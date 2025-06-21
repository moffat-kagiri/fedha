// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/enhanced_profile.dart';
import '../services/api_client.dart';

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
  final Uuid _uuid = const Uuid();
  final ApiClient _apiClient = ApiClient();

  EnhancedProfile? _currentProfile;
  bool _isInitialized = false;
  Box<EnhancedProfile>? _profileBox;

  EnhancedProfile? get currentProfile => _currentProfile;
  bool get isLoggedIn => _currentProfile != null;
  bool get isInitialized => _isInitialized;

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

      if (currentProfileId != null) {
        final profile = _profileBox!.get(currentProfileId);
        if (profile != null) {
          _currentProfile = profile;
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

  // Create enhanced profile with additional metadata
  Future<bool> createEnhancedProfile(Map<String, dynamic> profileData) async {
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
        final profile = EnhancedProfile(
          id: userId, // Use server-provided user_id
          type: profileData['profile_type'],
          passwordHash: EnhancedProfile.hashPassword(pin),
          name: profileData['name'],
          email: email,
          baseCurrency: profileData['base_currency'] ?? 'KES',
          timezone: profileData['timezone'] ?? 'GMT+3',
        );
        _profileBox ??= await Hive.openBox<EnhancedProfile>(
          'enhanced_profiles',
        );
        await _profileBox!.put(userId, profile);

        final settingsBox = Hive.box('settings');
        await settingsBox.put(
          'google_drive_enabled',
          profileData['enable_google_drive'] ?? false,
        );
        await settingsBox.put('current_profile_id', userId);

        _currentProfile = profile;
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

  // Enhanced login with better error handling
  Future<LoginResult> enhancedLogin(String email, String pin) async {
    if (kDebugMode) {
      print('Attempting enhanced login for email: $email');
    }

    try {
      // TODO: Fix login to use userId instead of email
      // For now, try to find local profile by email
      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');

      for (final profile in _profileBox!.values) {
        if (profile.email == email && profile.verifyPassword(pin)) {
          _currentProfile = profile;
          notifyListeners();

          if (kDebugMode) {
            print('Local login successful for email: $email');
          }

          return LoginResult.success(profile: profile);
        }
      }
      return LoginResult.error('Invalid email or PIN');

      /* TODO: Restore server login with userId
      final serverProfileData = await _apiClient.loginEnhancedProfile(
        userId: userId,  // Need to get userId from email somehow
        pin: pin,
      );

      if (kDebugMode) {
        print('Server login successful: $serverProfileData');
      }

      // Create profile from server data
      final String serverId = serverProfileData['id']?.toString() ?? email;
      final profileToSave = EnhancedProfile(
        id: serverId,
        type: ProfileType.values.firstWhere(
          (e) =>
              e.toString().split('.').last == serverProfileData['profile_type'],
          orElse: () => ProfileType.personal,
        ),
        passwordHash: EnhancedProfile.hashPassword(pin),
        name: serverProfileData['name'] ?? 'Default Name',
        email: email,
        baseCurrency: serverProfileData['base_currency'] ?? 'KES',
        timezone: serverProfileData['timezone'] ?? 'GMT+3',
      );

      _profileBox ??= await Hive.openBox<EnhancedProfile>('enhanced_profiles');
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
  Future<bool> login(String email, String pin) async {
    final result = await enhancedLogin(email, pin);
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
      _currentProfile = null;

      final settingsBox = Hive.box('settings');
      await settingsBox.delete('current_profile_id');

      notifyListeners();

      if (kDebugMode) {
        print('Logout successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Logout failed: $e');
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

  // Backward compatibility aliases for old method names
  Future<void> autoLogin() async => await tryAutoLogin();
  Future<bool> setInitialPin(String pin) async => await setInitialPassword(pin);
}

// Alias for backward compatibility with EnhancedAuthService
typedef EnhancedAuthService = AuthService;
