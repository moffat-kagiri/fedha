// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/enhanced_profile.dart';
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
  final EnhancedProfile? profile;

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
  final ApiClient _apiClient = ApiClient();

  EnhancedProfile? _currentProfile;
  bool _isInitialized = false;
  Box<EnhancedProfile>? _profileBox;

  EnhancedProfile? get currentProfile => _currentProfile;
  bool get isLoggedIn => _currentProfile != null;
  bool get isInitialized => _isInitialized;

  /// Get current profile ID
  String? get currentProfileId => _currentProfile?.id;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if boxes are already open, if not open them
      if (!Hive.isBoxOpen('enhanced_profiles')) {
        _profileBox = await Hive.openBox<EnhancedProfile>('enhanced_profiles');
      } else {
        _profileBox = Hive.box<EnhancedProfile>('enhanced_profiles');
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
      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');

      if (_profileBox!.isEmpty) {
        if (kDebugMode) {
          print('No profiles found. Creating test profiles...');
        }

        // Create test business profile
        final businessProfile = EnhancedProfile(
          type: ProfileType.business,
          passwordHash: EnhancedProfile.hashPassword('password123'),
          name: 'Test Business',
          email: 'business@test.com',
        );

        // Create test personal profile
        final personalProfile = EnhancedProfile(
          type: ProfileType.personal,
          passwordHash: EnhancedProfile.hashPassword('password456'),
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

  // Create enhanced profile with device-generated UUID, sync to server
  Future<bool> createEnhancedProfile(Map<String, dynamic> profileData) async {
    try {
      if (kDebugMode) {
        print('Creating enhanced profile with data: $profileData');
      }
      final String? email = profileData['email'];
      final String? pin = profileData['pin'] ?? profileData['password'];
      final String? name = profileData['name'];
      final ProfileType? profileTypeEnum = profileData['profile_type'];

      if (email == null || email.isEmpty || pin == null || pin.isEmpty) {
        throw Exception('Email and password are required to create a profile.');
      }
      if (name == null || name.isEmpty) {
        throw Exception('Name is required to create a profile.');
      }
      if (profileTypeEnum == null) {
        throw Exception('Profile type is required to create a profile.');
      }

      final String profileTypeString =
          profileTypeEnum.toString().split('.').last;

      // Generate UUID for new profile
      final String deviceProfileId = const Uuid().v4();
      String? serverProfileId;

      // Sync profile to server, passing deviceProfileId
      try {
        final serverResponse = await _apiClient.createEnhancedProfile(
          id: deviceProfileId,
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
        serverProfileId =
            serverResponse['user_id'] ??
            serverResponse['profile_id'] ??
            deviceProfileId;
      } catch (serverError) {
        if (kDebugMode) {
          print('Server profile creation failed: $serverError');
        }
        throw Exception('Failed to create profile on server.');
      }

      if (serverProfileId == null || serverProfileId.isEmpty) {
        throw Exception('Server did not return a valid profile ID.');
      }

      // Create profile locally using the server-synced ID
      final profile = EnhancedProfile(
        id: serverProfileId,
        type: profileData['profile_type'],
        passwordHash: EnhancedProfile.hashPassword(pin),
        name: profileData['name'],
        email: email,
        baseCurrency: profileData['base_currency'] ?? 'KES',
        timezone: profileData['timezone'] ?? 'GMT+3',
      );

      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');
      await _profileBox!.put(serverProfileId, profile);

      final settingsBox = Hive.box('settings');
      await settingsBox.put(
        'google_drive_enabled',
        profileData['enable_google_drive'] ?? false,
      );
      await settingsBox.put('current_profile_id', serverProfileId);

      _currentProfile = profile;

      // Save to Google if requested
      if (profileData['save_to_google'] == true) {
        try {
          await saveCredentialsToGoogle();
        } catch (googleError) {
          if (kDebugMode) {
            print('Google save failed, but continuing: $googleError');
          }
        }
      }

      notifyListeners();

      if (kDebugMode) {
        print(
          'Enhanced profile created successfully with email: ${profile.email}, User ID: $serverProfileId (synced to server)',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Enhanced profile creation failed: $e');
      }
      return false;
    }
  }

  // Enhanced login: always fetch profile from server using email, use server ID for session
  Future<LoginResult> enhancedLogin(
    String email,
    String pin, {
    bool saveToGoogle = false,
  }) async {
    if (kDebugMode) {
      print('Attempting enhanced login for email: $email');
    }

    try {
      // Fetch profile from server using email
      final serverProfile = await _apiClient.getEnhancedProfile(email: email);
      final serverProfileId =
          serverProfile['id'] ??
          serverProfile['user_id'] ??
          serverProfile['profile_id'];
      if (serverProfileId == null || serverProfileId.isEmpty) {
        return LoginResult.error('No profile found for this email.');
      }
      // Verify password/pin
      if (serverProfile['pin'] != pin) {
        return LoginResult.error('Invalid password or pin.');
      }
      // Create/update local profile
      final profile = EnhancedProfile(
        id: serverProfileId,
        type: ProfileType.values.firstWhere(
          (t) => t.toString().split('.').last == serverProfile['profile_type'],
          orElse: () => ProfileType.personal,
        ),
        passwordHash: EnhancedProfile.hashPassword(pin),
        name: serverProfile['name'],
        email: email,
        baseCurrency: serverProfile['base_currency'] ?? 'KES',
        timezone: serverProfile['timezone'] ?? 'GMT+3',
      );
      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');
      await _profileBox!.put(serverProfileId, profile);
      final settingsBox = Hive.box('settings');
      await settingsBox.put('current_profile_id', serverProfileId);
      _currentProfile = profile.copyWith(lastLogin: DateTime.now());
      await _profileBox!.put(serverProfileId, _currentProfile!);
      notifyListeners();
      if (kDebugMode) {
        print(
          'Server login successful for email: $email, ID: $serverProfileId',
        );
      }
      // Prompt for biometric setup if needed
      await promptBiometricSetupIfNeeded();
      return LoginResult.success(profile: _currentProfile!);
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return LoginResult.error('Login failed: ${e.toString()}');
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
      final newPasswordHash = EnhancedProfile.hashPassword(newPassword);

      _currentProfile = _currentProfile!.copyWith(
        passwordHash: newPasswordHash,
      );

      // Save locally
      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');
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
          passwordHash: EnhancedProfile.hashPassword(newPassword),
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
      final newPasswordHash = EnhancedProfile.hashPassword(newPassword);

      _currentProfile = _currentProfile!.copyWith(
        passwordHash: newPasswordHash,
      );

      // Save locally
      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');
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

      // Check if biometric session is valid (just check if enabled)
      final bool hasValidSession = biometricService.isEnabled;
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
          final bool authenticated = await biometricService.authenticate(
            localizedReason:
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
      if (!biometricService.isEnabled) {
        if (kDebugMode) {
          print('Biometric authentication is not enabled');
        }
        return false;
      }

      // Authenticate with biometric
      final bool authenticated = await biometricService.authenticate(
        localizedReason: 'Please verify your identity to access your account',
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

  /// Prompt for biometric setup after first successful login
  Future<void> promptBiometricSetupIfNeeded() async {
    try {
      final BiometricAuthService biometricService =
          BiometricAuthService.instance;

      if (await biometricService.shouldPromptBiometricSetup()) {
        if (kDebugMode) {
          print('Attempting to enable biometric authentication after login');
        }

        // Actually enable biometric authentication with user test
        final success = await biometricService.promptAndEnableBiometric();

        if (success) {
          if (kDebugMode) {
            print('✅ Biometric authentication enabled successfully');
          }
        } else {
          if (kDebugMode) {
            print('❌ User declined or failed biometric setup');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up biometric authentication: $e');
      }
    }
  }

  // Check if a profile exists with the given email
  Future<ProfileExistenceResult> checkProfileExists(String email) async {
    try {
      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');

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
  List<EnhancedProfile> getAllProfiles() {
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
      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');

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

  // Debug method to list all existing profiles
  Future<void> debugListProfiles() async {
    try {
      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');

      if (kDebugMode) {
        print('=== DEBUG: Listing all profiles ===');
        print('Total profiles: ${_profileBox!.values.length}');

        if (_profileBox!.values.isEmpty) {
          print('No profiles found in local storage');
        } else {
          for (final profile in _profileBox!.values) {
            print('Profile ID: ${profile.id}');
            print('Email: ${profile.email}');
            print('Name: ${profile.name}');
            print('Type: ${profile.type}');
            print('Created: ${profile.createdAt}');
            print('---');
          }
        }
        print('=== END DEBUG ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error listing profiles: $e');
      }
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentProfile != null;

  /// Clear all user data (for account deletion)
  Future<void> clearAllUserData() async {
    try {
      await logout();

      // Clear all boxes
      final settingsBox = Hive.box('settings');
      await settingsBox.clear();

      if (_profileBox != null) {
        await _profileBox!.clear();
      }

      // Clear other data boxes
      final transactionsBox = Hive.box('transactions');
      await transactionsBox.clear();

      final budgetsBox = Hive.box('budgets');
      await budgetsBox.clear();

      final goalsBox = Hive.box('goals');
      await goalsBox.clear();

      if (kDebugMode) {
        print('All user data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear user data: $e');
      }
    }
  }

  /// Check if session is valid (not expired)
  bool isSessionValid() {
    if (_currentProfile == null) return false;

    // Check if session is within valid timeframe (24 hours)
    final lastLogin = _currentProfile!.lastLogin;
    if (lastLogin == null) return false;

    final now = DateTime.now();
    final sessionDuration = now.difference(lastLogin);
    const maxSessionDuration = Duration(hours: 24);

    return sessionDuration <= maxSessionDuration;
  }

  /// Refresh session timestamp
  Future<void> refreshSession() async {
    if (_currentProfile == null) return;

    try {
      final updatedProfile = _currentProfile!.copyWith(
        lastLogin: DateTime.now(),
      );
      await _profileBox!.put(_currentProfile!.id, updatedProfile);
      _currentProfile = updatedProfile;

      if (kDebugMode) {
        print('Session refreshed for user: ${_currentProfile!.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to refresh session: $e');
      }
    }
  }
}

// Alias for backward compatibility with EnhancedAuthService
typedef EnhancedAuthService = AuthService;
