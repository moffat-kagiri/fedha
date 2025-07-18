// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/enums.dart';
import '../services/api_client.dart';
import '../services/biometric_auth_service.dart';
import '../services/google_auth_service.dart';

// Result class for profile existence checks
class ProfileExistenceResult {
  final bool exists;
  final bool isLocal;
  final bool isOnServer;

  ProfileExistenceResult({
    required this.exists,
    required this.isLocal,
    required this.isOnServer,
  });
}

// Login result class
class LoginResult {
  final bool success;
  final String message;
  final Profile? profile;

  LoginResult.success({this.profile})
    : success = true,
      message = 'Login successful';
  LoginResult.error(this.message) : success = false, profile = null;

  static LoginResult empty() => LoginResult.error('No profile found');
}

// Profile stats class
class ProfileStats {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final int transactionCount;
  final int activeBudgets;
  final int activeGoals;
  final DateTime? lastLogin;
  final int accountAge;

  ProfileStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.transactionCount,
    required this.activeBudgets,
    required this.activeGoals,
    this.lastLogin,
    required this.accountAge,
  });

  static ProfileStats empty() => ProfileStats(
    totalIncome: 0.0,
    totalExpense: 0.0,
    netBalance: 0.0,
    transactionCount: 0,
    activeBudgets: 0,
    activeGoals: 0,
    accountAge: 0,
  );
}

class AuthService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final ApiClient _apiClient = ApiClient();

  Profile? _currentProfile;
  bool _isInitialized = false;
  Box<Profile>? _profileBox;

  Profile? get currentProfile => _currentProfile;
  bool get isLoggedIn => _currentProfile != null;
  bool get isInitialized => _isInitialized;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if boxes are already open, if not open them
      if (!Hive.isBoxOpen('profiles')) {
        _profileBox = await Hive.openBox<Profile>('profiles');
      } else {
        _profileBox = Hive.box<Profile>('profiles');
      }

      // Open other necessary boxes
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }
      if (!Hive.isBoxOpen('transactions')) {
        await Hive.openBox('transactions');
      }
      if (!Hive.isBoxOpen('budgets')) {
        await Hive.openBox('budgets');
      }
      if (!Hive.isBoxOpen('goals')) {
        await Hive.openBox('goals');
      }

      // Create test profiles if none exist (for development/testing)
      await _createTestProfilesIfNeeded();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize AuthService: $e');
      }
    }
  }

  // Auto login - check for stored session
  Future<void> tryAutoLogin() async {
    try {
      if (_profileBox == null) {
        await initialize();
      }

      final settingsBox = Hive.box('settings');
      final currentProfileId = settingsBox.get('current_profile_id');
      final persistentLoginEnabled = settingsBox.get(
        'persistent_login_enabled',
        defaultValue: true,
      );

      if (currentProfileId != null && persistentLoginEnabled) {
        final profile = _profileBox!.get(currentProfileId);
        if (profile != null) {
          _currentProfile = profile;

          // Update last login timestamp
          final updatedProfile = profile.copyWith(lastLogin: DateTime.now());
          await _profileBox!.put(currentProfileId, updatedProfile);
          _currentProfile = updatedProfile;

          notifyListeners();

          if (kDebugMode) {
            print('Auto login successful for profile: ${profile.email}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auto login failed: $e');
      }
    }
  }

  // Enable or disable persistent login
  Future<void> setPersistentLoginEnabled(bool enabled) async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.put('persistent_login_enabled', enabled);

      if (!enabled) {
        // If disabling persistent login, clear current session
        await logout();
      }

      if (kDebugMode) {
        print('Persistent login ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set persistent login: $e');
      }
    }
  }

  // Check if persistent login is enabled
  Future<bool> isPersistentLoginEnabled() async {
    try {
      final settingsBox = Hive.box('settings');
      return settingsBox.get('persistent_login_enabled', defaultValue: true);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check persistent login status: $e');
      }
      return false;
    }
  }

  // Create test profiles for development/testing if none exist
  Future<void> _createTestProfilesIfNeeded() async {
    try {
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      if (_profileBox!.isEmpty) {
        if (kDebugMode) {
          print('No profiles found. Creating test profiles...');
        }

        // Create test business profile
        final businessProfile = Profile(
          id: const Uuid().v4(),
          type: ProfileType.business,
          pin: 'password123',
          passwordHash: Profile.hashPassword('password123'),
          name: 'Test Business',
          email: 'business@test.com',
        );

        // Create test personal profile
        final personalProfile = Profile(
          id: const Uuid().v4(),
          type: ProfileType.personal,
          pin: 'password456',
          passwordHash: Profile.hashPassword('password456'),
          name: 'Test Personal',
          email: 'personal@test.com',
        );

        await _profileBox!.put(businessProfile.id, businessProfile);
        await _profileBox!.put(personalProfile.id, personalProfile);

        if (kDebugMode) {
          print('Test profiles created:');
          print(
            '  Business: Email: ${businessProfile.email}, Password: password123',
          );
          print(
            '  Personal: Email: ${personalProfile.email}, Password: password456',
          );
        }
      } else {
        if (kDebugMode) {
          print('Existing profiles found: ${_profileBox!.length}');
          for (var key in _profileBox!.keys) {
            var profile = _profileBox!.get(key);
            print(
              '  ${profile?.type}: Email: ${profile?.email}, Name: ${profile?.name}',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating test profiles: $e');
      }
    }
  }

  // Create profile with additional metadata
  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    try {
      if (kDebugMode) {
        print('Creating enhanced profile with data: $profileData');
      } // Extract email and pin, which are now primary for server interaction
      final String? email = profileData['email'];
      final String? pin = profileData['pin'];
      final String? name = profileData['name'];
      final ProfileType? profileTypeEnum = profileData['profile_type'];

      if (email == null || email.isEmpty || pin == null || pin.isEmpty) {
        if (kDebugMode) {
          print('Email or PIN is missing. Cannot create server profile.');
        }
        throw Exception('Email and PIN are required to create a profile.');
      }

      if (name == null || name.isEmpty) {
        if (kDebugMode) {
          print('Name is missing. Cannot create server profile.');
        }
        throw Exception('Name is required to create a profile.');
      }

      if (profileTypeEnum == null) {
        if (kDebugMode) {
          print('Profile type is missing. Cannot create server profile.');
        }
        throw Exception('Profile type is required to create a profile.');
      }

      final String profileTypeString =
          profileTypeEnum
              .toString()
              .split('.')
              .last; // First try to create profile on server
      try {
        final serverResponse = await _apiClient.createEnhancedProfile(
          name: name,
          profileType: profileTypeString,
          pin: pin,
          email: email,
          baseCurrency: profileData['base_currency'] ?? 'KES',
          timezone: profileData['timezone'] ?? 'GMT+3',
        );
        if (kDebugMode) {
          print('Server profile created successfully: $serverResponse');
        }

        String userId =
            serverResponse['user_id'] ??
            serverResponse['profile_id'] ??
            _uuid.v4();
        final profile = Profile(
          id: userId, // Use server-provided user_id
          type: profileData['profile_type'],
          pin: pin,
          passwordHash: Profile.hashPassword(pin),
          name: profileData['name'],
          email: email,
          baseCurrency: profileData['base_currency'] ?? 'KES',
          timezone: profileData['timezone'] ?? 'GMT+3',
        );
        _profileBox ??= await Hive.openBox<Profile>(
          'profiles',
        );
        await _profileBox!.put(userId, profile);

        final settingsBox = Hive.box('settings');
        await settingsBox.put(
          'google_drive_enabled',
          profileData['enable_google_drive'] ?? false,
        );
        await settingsBox.put('current_profile_id', userId);

        _currentProfile = profile;

        // Save to Google if requested
        if (profileData['save_to_google'] == true) {
          await saveCredentialsToGoogle();
        }

        notifyListeners();

        if (kDebugMode) {
          print(
            'Enhanced profile created successfully with email: ${profile.email}, User ID: $userId',
          );
        }

        return true;
      } catch (serverError) {
        if (kDebugMode) {
          print('Server profile creation failed: $serverError');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Enhanced profile creation failed: $e');
      }
      return false;
    }
  }

  // Enhanced login with better error handling and Google credential support
  Future<LoginResult> enhancedLogin(
    String email,
    String pin, {
    bool saveToGoogle = false,
  }) async {
    if (kDebugMode) {
      print('Attempting enhanced login for email: $email');
    }

    try {
      // TODO: Fix login to use userId instead of email
      // For now, try to find local profile by email
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      for (final profile in _profileBox!.values) {
        if (profile.email == email && profile.verifyPassword(pin)) {
          _currentProfile = profile.copyWith(lastLogin: DateTime.now());

          // Save updated profile with last login time
          await _profileBox!.put(profile.id, _currentProfile!);

          // Save current profile ID for persistent login
          final settingsBox = Hive.box('settings');
          await settingsBox.put('current_profile_id', profile.id);

          // Save to Google if requested
          if (saveToGoogle) {
            await saveCredentialsToGoogle();
          }

          notifyListeners();

          if (kDebugMode) {
            print('Local login successful for email: $email');
          }

          return LoginResult.success(profile: _currentProfile!);
        }
      }
      return LoginResult.error('Invalid email or PIN');

      /* TODO: Restore server login with userId
      final serverProfileData = await _apiClient.loginProfile(
        userId: userId,  // Need to get userId from email somehow
        pin: pin,
      );

      if (kDebugMode) {
        print('Server login successful: $serverProfileData');
      }

      // Create profile from server data
      final String serverId = serverProfileData['id']?.toString() ?? email;
      final profileToSave = Profile(
        id: serverId,
        type: ProfileType.values.firstWhere(
          (e) =>
              e.toString().split('.').last == serverProfileData['profile_type'],
          orElse: () => ProfileType.personal,
        ),
        passwordHash: Profile.hashPassword(pin),
        name: serverProfileData['name'] ?? 'Default Name',
        email: email,
        baseCurrency: serverProfileData['base_currency'] ?? 'KES',
        timezone: serverProfileData['timezone'] ?? 'GMT+3',
      );

      _profileBox ??= await Hive.openBox<Profile>('profiles');
      await _profileBox!.put(serverId, profileToSave);

      final settingsBox = Hive.box('settings');
      await settingsBox.put('current_profile_id', serverId);

      _currentProfile = profileToSave;
      notifyListeners();

      if (kDebugMode) {
        print('Enhanced login successful for email: $email');
      }

      return LoginResult.success(profile: profileToSave);
      */
    } catch (e) {
      if (kDebugMode) {
        print('Enhanced login failed: $e');
      }
      return LoginResult.error('Login failed: $e');
    }
  }

  // Login with email and pin
  Future<bool> login(
    String email,
    String pin, {
    bool saveToGoogle = false,
  }) async {
    final result = await enhancedLogin(email, pin, saveToGoogle: saveToGoogle);
    return result.success;
  }

  // Signup with email and password
  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      if (_profileBox == null) {
        await initialize();
      }

      // Check if email already exists
      final existingProfiles = _profileBox!.values
          .where((p) => p.email?.toLowerCase() == email.toLowerCase())
          .toList();
      
      if (existingProfiles.isNotEmpty) {
        return false; // Email already exists
      }

      // Create new profile
      final newProfile = Profile(
        id: const Uuid().v4(),
        name: '$firstName $lastName',
        email: email,
        type: ProfileType.personal,
        pin: password, // Using password as pin for now
      );

      // Save profile
      await _profileBox!.put(newProfile.id, newProfile);

      // Set as current profile
      _currentProfile = newProfile;
      
      final settingsBox = Hive.box('settings');
      await settingsBox.put('current_profile_id', newProfile.id);

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Signup failed: $e');
      }
      return false;
    }
  }

  // Login by profile type (for backward compatibility)
  Future<bool> loginByType(ProfileType profileType, String password) async {
    try {
      if (_profileBox == null) {
        await initialize();
      }

      final profiles =
          _profileBox!.values.where((p) => p.type == profileType).toList();

      for (final profile in profiles) {
        if (profile.verifyPassword(password)) {
          _currentProfile = profile.copyWith(lastLogin: DateTime.now());

          // Update last login
          await _profileBox!.put(profile.id, _currentProfile!);

          final settingsBox = Hive.box('settings');
          await settingsBox.put('current_profile_id', profile.id);

          notifyListeners();

          if (kDebugMode) {
            print('Login successful for profile type: $profileType');
          }

          return true;
        }
      }

      if (kDebugMode) {
        print('Login failed for profile type: $profileType');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    }
  }

  // Set initial password for new profiles
  Future<bool> setInitialPassword(String newPassword) async {
    if (_currentProfile == null) {
      if (kDebugMode) {
        print('No current profile to set password for');
      }
      return false;
    }

    try {
      // Update password hash
      final newPasswordHash = Profile.hashPassword(newPassword);

      _currentProfile = _currentProfile!.copyWith(
        passwordHash: newPasswordHash,
      );

      // Save locally
      _profileBox ??= await Hive.openBox<Profile>('profiles');
      await _profileBox!.put(_currentProfile!.id, _currentProfile!);

      notifyListeners();

      if (kDebugMode) {
        print(
          'Initial password set successfully for profile: ${_currentProfile!.email}',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set initial password: $e');
      }
      return false;
    }
  }

  // Change password for existing profiles
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentProfile == null) {
      if (kDebugMode) {
        print('No current profile to change password for');
      }
      return false;
    }

    try {
      // Verify current password
      if (!_currentProfile!.verifyPassword(currentPassword)) {
        if (kDebugMode) {
          print('Current password verification failed');
        }
        return false;
      } // Try to update password on server first
      try {
        await _apiClient.updateEnhancedProfile(
          email: _currentProfile!.email!,
          passwordHash: Profile.hashPassword(newPassword),
          name: _currentProfile!.name!,
          baseCurrency: _currentProfile!.baseCurrency,
          timezone: _currentProfile!.timezone,
        );

        if (kDebugMode) {
          print('Server password update successful');
        }
      } catch (serverError) {
        if (kDebugMode) {
          print(
            'Server password update failed, continuing with local update: $serverError',
          );
        }
        // Continue with local update even if server fails
      }

      // Update password hash locally
      final newPasswordHash = Profile.hashPassword(newPassword);

      _currentProfile = _currentProfile!.copyWith(
        passwordHash: newPasswordHash,
      );

      // Save locally
      _profileBox ??= await Hive.openBox<Profile>('profiles');
      await _profileBox!.put(_currentProfile!.id, _currentProfile!);

      notifyListeners();

      if (kDebugMode) {
        print(
          'Password changed successfully for profile: ${_currentProfile!.email}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to change password: $e');
      }
      return false;
    }
  }

  // Biometric Authentication Methods

  /// Try auto-login with biometric authentication
  Future<bool> tryBiometricAutoLogin() async {
    try {
      final BiometricAuthService biometricService =
          BiometricAuthService.instance;

      // Check if biometric session is valid
      final bool hasValidSession =
          await biometricService.hasValidBiometricSession();
      if (!hasValidSession) {
        return false;
      }

      // Check if we have a current profile stored
      final settingsBox = Hive.box('settings');
      final currentProfileId = settingsBox.get('current_profile_id');

      if (currentProfileId != null) {
        final profile = _profileBox!.get(currentProfileId);
        if (profile != null) {
          // Authenticate with biometric
          final bool authenticated = await biometricService
              .authenticateWithBiometric(
                'Please verify your identity to access your account',
              );

          if (authenticated) {
            _currentProfile = profile.copyWith(lastLogin: DateTime.now());
            await _profileBox!.put(profile.id, _currentProfile!);
            notifyListeners();

            if (kDebugMode) {
              print(
                'Biometric auto-login successful for profile: ${profile.email}',
              );
            }
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Biometric auto-login failed: $e');
      }
      return false;
    }
  }

  /// Login with biometric authentication
  Future<bool> loginWithBiometric() async {
    try {
      final BiometricAuthService biometricService =
          BiometricAuthService.instance;

      // Check if biometric is available and enabled
      if (!await biometricService.isBiometricEnabled()) {
        if (kDebugMode) {
          print('Biometric authentication is not enabled');
        }
        return false;
      }

      // Authenticate with biometric
      final bool authenticated = await biometricService
          .authenticateWithBiometric(
            'Please verify your identity to access your account',
          );

      if (!authenticated) {
        return false;
      }

      // Get current profile
      final settingsBox = Hive.box('settings');
      final currentProfileId = settingsBox.get('current_profile_id');

      if (currentProfileId != null) {
        final profile = _profileBox!.get(currentProfileId);
        if (profile != null) {
          _currentProfile = profile.copyWith(lastLogin: DateTime.now());
          await _profileBox!.put(profile.id, _currentProfile!);
          notifyListeners();

          if (kDebugMode) {
            print('Biometric login successful for profile: ${profile.email}');
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Biometric login failed: $e');
      }
      return false;
    }
  }

  /// Check if biometric setup should be prompted
  Future<bool> shouldPromptBiometricSetup() async {
    try {
      final BiometricAuthService biometricService =
          BiometricAuthService.instance;
      return await biometricService.shouldPromptBiometricSetup();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric setup prompt: $e');
      }
      return false;
    }
  }

  // Check if a profile exists with the given email
  Future<ProfileExistenceResult> checkProfileExists(String email) async {
    try {
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      // Check local storage
      bool isLocal = false;
      for (var profile in _profileBox!.values) {
        if (profile.email == email) {
          isLocal = true;
          break;
        }
      } // Check server
      bool isOnServer = false;
      try {
        await _apiClient.getEnhancedProfile(email: email);
        isOnServer = true; // If no exception is thrown, profile exists
      } catch (e) {
        if (kDebugMode) {
          print('Server check failed: $e');
        }
        isOnServer = false;
      }

      return ProfileExistenceResult(
        exists: isLocal || isOnServer,
        isLocal: isLocal,
        isOnServer: isOnServer,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Profile existence check failed: $e');
      }
      return ProfileExistenceResult(
        exists: false,
        isLocal: false,
        isOnServer: false,
      );
    }
  }

  // Get profile statistics
  Future<ProfileStats> getProfileStats() async {
    if (_currentProfile == null) {
      return ProfileStats.empty();
    }

    try {
      final transactionBox = Hive.box('transactions');
      final budgetBox = Hive.box('budgets');
      final goalBox = Hive.box('goals');

      final profileTransactions =
          transactionBox.values
              .where((t) => t['profileId'] == _currentProfile!.id)
              .toList();

      final totalIncome = profileTransactions
          .where((t) => t['type'] == 'income')
          .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));

      final totalExpense = profileTransactions
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));

      final activeBudgets =
          budgetBox.values
              .where(
                (b) =>
                    b['profileId'] == _currentProfile!.id &&
                    b['isActive'] == true,
              )
              .length;

      final activeGoals =
          goalBox.values
              .where(
                (g) =>
                    g['profileId'] == _currentProfile!.id &&
                    g['isCompleted'] == false,
              )
              .length;

      return ProfileStats(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        transactionCount: profileTransactions.length,
        activeBudgets: activeBudgets,
        activeGoals: activeGoals,
        lastLogin: _currentProfile!.lastLogin,
        accountAge:
            DateTime.now().difference(_currentProfile!.createdAt).inDays,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get profile stats: $e');
      }
      return ProfileStats.empty();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Clear current profile
      _currentProfile = null;

      // Clear stored session
      final settingsBox = Hive.box('settings');
      await settingsBox.delete('current_profile_id');

      // Clear biometric session
      final biometricService = BiometricAuthService.instance;
      await biometricService.clearBiometricSession();

      if (kDebugMode) {
        print('AuthService: User logged out successfully');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error during logout: $e');
      }
    }
  }

  // Get all profiles (for profile selection)
  List<Profile> getAllProfiles() {
    try {
      if (_profileBox == null) return [];
      return _profileBox!.values.toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get all profiles: $e');
      }
      return [];
    }
  }

  // Delete profile
  Future<bool> deleteProfile(String profileId) async {
    try {
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      final profile = _profileBox!.get(profileId);
      if (profile == null) {
        if (kDebugMode) {
          print('Profile not found for deletion: $profileId');
        }
        return false;
      }

      // Try to delete from server first
      try {
        await _apiClient.deleteEnhancedProfile(email: profile.email!);
        if (kDebugMode) {
          print('Server profile deletion successful');
        }
      } catch (serverError) {
        if (kDebugMode) {
          print(
            'Server profile deletion failed, continuing with local deletion: $serverError',
          );
        }
      }

      // Delete locally
      await _profileBox!.delete(profileId);

      // If this was the current profile, logout
      if (_currentProfile?.id == profileId) {
        await logout();
      }

      if (kDebugMode) {
        print('Profile deleted successfully: $profileId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete profile: $e');
      }
      return false;
    }
  }

  // Sync profile with server
  Future<void> syncProfileWithServer() async {
    if (_currentProfile == null) return;
    try {
      // Attempt to sync with server
      await _apiClient.updateEnhancedProfile(
        email: _currentProfile!.email!,
        name: _currentProfile!.name!,
        baseCurrency: _currentProfile!.baseCurrency,
        timezone: _currentProfile!.timezone,
      );

      if (kDebugMode) {
        print('Profile sync with server successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Profile sync with server failed: $e');
      }
    }
  }

  // Check if profile needs password change (first-time login)
  bool requiresPasswordChange() {
    if (_currentProfile == null) return false;

    // If never logged in before or account is very new
    if (_currentProfile!.lastLogin == null) return true;

    final daysSinceCreation =
        DateTime.now().difference(_currentProfile!.createdAt).inDays;
    return daysSinceCreation < 1 && _currentProfile!.lastLogin == null;
  }

  // Update profile name
  Future<bool> updateProfileName(String newName) async {
    if (_currentProfile == null || newName.trim().isEmpty) {
      return false;
    }

    try {
      // Update the profile locally
      final updatedProfile = _currentProfile!.copyWith(name: newName.trim());

      // Save to local storage
      await _profileBox?.put(_currentProfile!.id, updatedProfile);

      // Update current profile
      _currentProfile = updatedProfile;
      notifyListeners();

      // TODO: Sync with server if needed
      // _syncProfileWithServer();

      if (kDebugMode) {
        print('Profile name updated successfully: $newName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update profile name: $e');
      }
      return false;
    }
  }

  // Update profile email
  Future<bool> updateProfileEmail(String newEmail) async {
    if (_currentProfile == null ||
        newEmail.trim().isEmpty ||
        !newEmail.contains('@')) {
      return false;
    }

    try {
      // Update the profile locally
      final updatedProfile = _currentProfile!.copyWith(email: newEmail.trim());

      // Save to local storage
      await _profileBox?.put(_currentProfile!.id, updatedProfile);

      // Update current profile
      _currentProfile = updatedProfile;
      notifyListeners();

      // TODO: Sync with server if needed
      // _syncProfileWithServer();

      if (kDebugMode) {
        print('Profile email updated successfully: $newEmail');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update profile email: $e');
      }
      return false;
    }
  }

  // Google Credential Management Methods

  /// Save login credentials to Google account
  Future<bool> saveCredentialsToGoogle() async {
    try {
      if (_currentProfile == null) {
        if (kDebugMode) {
          print('AuthService: No current profile to save credentials for');
        }
        return false;
      }

      final googleAuthService = GoogleAuthService.instance;
      final success = await googleAuthService.saveCredentialsToGoogle(
        email: _currentProfile!.email ?? '',
        name: _currentProfile!.name ?? '',
      );

      if (success) {
        // Mark that credentials are saved to Google for this profile
        final settingsBox = Hive.box('settings');
        await settingsBox.put('credentials_saved_to_google', true);
        await settingsBox.put('google_saved_profile_id', _currentProfile!.id);

        if (kDebugMode) {
          print(
            'AuthService: Credentials saved to Google for profile: ${_currentProfile!.email}',
          );
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error saving credentials to Google: $e');
      }
      return false;
    }
  }

  /// Check if credentials are saved to Google for current profile
  Future<bool> areCredentialsSavedToGoogle() async {
    try {
      final settingsBox = Hive.box('settings');
      final credentialsSaved = settingsBox.get(
        'credentials_saved_to_google',
        defaultValue: false,
      );
      final savedProfileId = settingsBox.get('google_saved_profile_id');

      // Check if the saved profile matches current profile
      if (_currentProfile != null && savedProfileId == _currentProfile!.id) {
        return credentialsSaved;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error checking Google credentials status: $e');
      }
      return false;
    }
  }

  /// Clear Google credential association
  Future<void> clearGoogleCredentials() async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.delete('credentials_saved_to_google');
      await settingsBox.delete('google_saved_profile_id');

      final googleAuthService = GoogleAuthService.instance;
      await googleAuthService.clearSavedCredentials();

      if (kDebugMode) {
        print('AuthService: Google credentials cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error clearing Google credentials: $e');
      }
    }
  }

  // ...existing code...
}

// Alias for backward compatibility with EnhancedAuthService
typedef EnhancedAuthService = AuthService;
