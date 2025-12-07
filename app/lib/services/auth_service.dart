// auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../models/profile.dart';
import 'api_client.dart';
import 'biometric_auth_service.dart';
import 'offline_data_service.dart';
import 'sms_listener_service.dart';
import 'unified_sync_service.dart';
import 'budget_service.dart';

class AuthService with ChangeNotifier {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  // Dependencies
  OfflineDataService? _offlineDataService;
  BiometricAuthService? _biometricService;
  UnifiedSyncService? _syncService;
  BudgetService? _budgetService;
  
  final _uuid = const Uuid();
  final _secureStorage = const FlutterSecureStorage();
  final _apiClient = ApiClient.instance;
  final _logger = AppLogger.getLogger('AuthService');

  Profile? _currentProfile;
  bool _isInitialized = false;

  AuthService._();

  // Getters
  Profile? get currentProfile => _currentProfile;
  String? get profileId => _currentProfile?.id;
  bool get isInitialized => _isInitialized;
  bool get hasActiveProfile => _currentProfile != null && _currentProfile!.id.isNotEmpty;

  /// Initialize with all dependencies
  Future<void> initializeWithAllDependencies({
    required OfflineDataService offlineDataService,
    BiometricAuthService? biometricService,
    UnifiedSyncService? syncService,
    BudgetService? budgetService,
  }) async {
    if (_isInitialized) {
      _logger.warning('AuthService already initialized');
      return;
    }
    
    try {
      _logger.info('Initializing AuthService with all dependencies...');
      
      _offlineDataService = offlineDataService;
      _biometricService = biometricService;
      _syncService = syncService;
      _budgetService = budgetService;
      
      await _restoreActiveProfile();
      
      if (_currentProfile != null && _syncService != null) {
        _logger.info('Syncing data for restored profile...');
        _syncService!.setCurrentProfile(_currentProfile!.id);
        await _syncService!.syncAll();
        
        if (_budgetService != null) {
          await _budgetService!.loadBudgetsForProfile(_currentProfile!.id);
        }
      }
      
      _isInitialized = true;
      _logger.info('AuthService initialized - Active profile: ${_currentProfile?.name ?? "None"}');
    } catch (e, stackTrace) {
      _logger.severe('AuthService initialization failed', e, stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// Initialize with essential dependencies only
  Future<void> initializeWithDependencies({
    required OfflineDataService offlineDataService,
    BiometricAuthService? biometricService,
  }) async {
    if (_isInitialized) {
      _logger.warning('AuthService already initialized');
      return;
    }
    
    try {
      _logger.info('Initializing AuthService with dependencies...');
      
      _offlineDataService = offlineDataService;
      _biometricService = biometricService;
      
      await _restoreActiveProfile();
      
      _isInitialized = true;
      _logger.info('AuthService initialized - Active profile: ${_currentProfile?.name ?? "None"}');
    } catch (e, stackTrace) {
      _logger.severe('AuthService initialization failed', e, stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// Restore active profile from persistent storage
  Future<void> _restoreActiveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final currentProfileId = prefs.getString('current_profile_id');
      
      _logger.info('Restoring session - logged in: $isLoggedIn, profile ID: $currentProfileId');
      
      if (isLoggedIn && currentProfileId != null && currentProfileId.isNotEmpty) {
        final profileData = await _secureStorage.read(key: 'profile_$currentProfileId');
        
        if (profileData != null) {
          final profileJson = jsonDecode(profileData);
          _currentProfile = Profile.fromJson(profileJson);
          _logger.info('Profile restored: ${_currentProfile!.name} (${_currentProfile!.id})');
        } else {
          _logger.warning('Profile data not found for ID: $currentProfileId');
          await _clearSession();
        }
      } else {
        _logger.info('No active session to restore');
        _currentProfile = null;
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to restore active profile', e, stackTrace);
      await _clearSession();
    }
  }

  /// Set current profile by ID
  Future<bool> setCurrentProfile(String profileId) async {
    try {
      _logger.info('Setting current profile: $profileId');
      
      final profileData = await _secureStorage.read(key: 'profile_$profileId');
      if (profileData == null) {
        _logger.warning('Profile data not found for ID: $profileId');
        return false;
      }
      
      final profileJson = jsonDecode(profileData);
      final profile = Profile.fromJson(profileJson);
      
      _currentProfile = profile;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_profile_id', profileId);
      await prefs.setBool('is_logged_in', true);
      
      await _initializeProfileServices(profileId);
      
      notifyListeners();
      _logger.info('Current profile set: ${profile.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to set current profile', e, stackTrace);
      return false;
    }
  }

  /// Store profile data
  Future<void> _storeProfile(Profile profile) async {
    try {
      final profileJson = jsonEncode(profile.toJson());
      
      await _secureStorage.write(
        key: 'profile_${profile.id}',
        value: profileJson,
      );
      
      await _secureStorage.write(
        key: 'current_profile_data',
        value: profileJson,
      );
      
      _logger.info('Profile stored: ${profile.name} (${profile.id})');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store profile', e, stackTrace);
      rethrow;
    }
  }

  /// Get profile by email
  Future<Profile?> _getProfileByEmail(String email) async {
    try {
      if (_currentProfile?.email?.toLowerCase() == email.toLowerCase()) {
        return _currentProfile;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final currentProfileId = prefs.getString('current_profile_id');
      
      if (currentProfileId != null) {
        final profileData = await _secureStorage.read(key: 'profile_$currentProfileId');
        if (profileData != null) {
          final profile = Profile.fromJson(jsonDecode(profileData));
          if (profile.email?.toLowerCase() == email.toLowerCase()) {
            return profile;
          }
        }
      }
      
      final legacyData = await _secureStorage.read(key: 'current_profile_data');
      if (legacyData != null) {
        final profile = Profile.fromJson(jsonDecode(legacyData));
        if (profile.email?.toLowerCase() == email.toLowerCase()) {
          return profile;
        }
      }
    } catch (e) {
      _logger.warning('Error checking existing profile: $e');
    }
    return null;
  }

  /// Initialize services for specific profile
  Future<void> _initializeProfileServices(String profileId) async {
    if (_offlineDataService == null) {
      _logger.warning('OfflineDataService not available for profile initialization');
      return;
    }

    try {
      await Workmanager().cancelAll();
      
      final smsService = SmsListenerService.instance;
      await smsService.initialize(
        offlineDataService: _offlineDataService!,
        profileId: profileId,
      );
      
      _logger.info('Profile services initialized for: $profileId');
    } catch (e) {
      _logger.warning('Failed to initialize profile services: $e');
    }
  }

  /// Clear all session data
  Future<void> _clearSession() async {
    _currentProfile = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('current_profile_id');
    
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      _logger.warning('Failed to cancel background tasks: $e');
    }
    
    notifyListeners();
  }

  // ==================== AUTH METHODS ====================

  Future<bool> isLoggedIn() async {
    return hasActiveProfile;
  }

  Future<String?> getStoredProfile() async {
    try {
      if (_currentProfile != null) {
        return jsonEncode(_currentProfile!.toJson());
      }
      return await _secureStorage.read(key: 'current_profile_data');
    } catch (e) {
      _logger.severe('Failed to get stored profile: $e');
      return null;
    }
  }

  /// SECURE LOGIN - Validates credentials with server
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Attempting login for: $email');
      
      // CRITICAL FIX: Check server first
      bool serverAuthSuccess = false;
      Map<String, dynamic>? serverResponse;
      
      try {
        final isOnline = await _apiClient.checkServerHealth();
        
        if (isOnline) {
          _logger.info('Server available - authenticating...');
          serverResponse = await _apiClient.login(
            email: email,
            password: password,
          );
          
          // FIXED: Properly check success - token existence is key
          serverAuthSuccess = serverResponse['token'] != null;
          
          if (serverAuthSuccess) {
            _logger.info('✅ Server authentication successful');
          } else {
            _logger.warning('❌ Server authentication failed');
            final errorMsg = serverResponse['error']?.toString() ?? 
                            serverResponse['body']?.toString() ?? 
                            'Invalid email or password';
            return LoginResult.error(message: errorMsg);
          }
        } else {
          _logger.warning('Server unavailable - checking offline credentials');
        }
      } catch (e) {
        _logger.warning('Server authentication error: $e - falling back to offline');
      }
      
      // Check/create local profile
      Profile? profile;
      bool isFirstLogin = false;
      
      if (serverAuthSuccess && serverResponse != null) {
        // Server auth succeeded
        final existingProfile = await _getProfileByEmail(email);
        
        if (existingProfile != null) {
          // Update existing profile with new token
          profile = existingProfile.copyWith(
            authToken: serverResponse['token'] as String?,
            sessionToken: _createSessionToken(),
          );
        } else {
          // Create new profile
          isFirstLogin = true;
          final userId = _uuid.v4();
          final userData = serverResponse['user'] as Map<String, dynamic>?;
          
          final firstName = userData?['first_name']?.toString() ?? email.split('@')[0];
          final lastName = userData?['last_name']?.toString() ?? '';
          final fullName = '$firstName $lastName'.trim();
          
          profile = Profile.defaultProfile(
            id: userId,
            name: fullName,
            email: email.trim(),
            password: _hashPassword(password),
          ).copyWith(
            authToken: serverResponse['token'] as String?,
            sessionToken: _createSessionToken(),
          );
        }
        
        // CRITICAL: Set API token for subsequent requests
        if (serverResponse['token'] != null) {
          _apiClient.setAuthToken(serverResponse['token'] as String);
          
          // CRITICAL FIX: Fetch full profile data from server
          try {
            final profileResponse = await _apiClient.getProfile(
              sessionToken: serverResponse['token'] as String,
            );
            
            if (profileResponse['success'] == true && profileResponse['profile'] != null) {
              final serverProfile = profileResponse['profile'] as Map<String, dynamic>;
              _logger.info('Merged server profile data: $serverProfile');
              
              // Merge server profile data with local profile
              if (profile != null) {
                profile = profile.copyWith(
                  baseCurrency: serverProfile['base_currency'] as String? ?? 'KES',
                  timezone: serverProfile['timezone'] as String? ?? 'Africa/Nairobi',
                  lastModified: serverProfile['last_modified'] != null
                      ? DateTime.parse(serverProfile['last_modified'] as String)
                      : null,
                  lastLogin: serverProfile['last_login'] != null
                      ? DateTime.parse(serverProfile['last_login'] as String)
                      : null,
                );
              }
            }
          } catch (e) {
            _logger.warning('Failed to fetch server profile data: $e');
            // Continue with existing profile data
          }
        }
      } else {
        // Offline fallback
        final existingProfile = await _getProfileByEmail(email);
        
        if (existingProfile == null) {
          return LoginResult.error(
            message: 'No account found. Please connect to the internet to create an account.',
          );
        }
        
        if (!_verifyPassword(password, existingProfile.password)) {
          _logger.warning('Offline password verification failed');
          return LoginResult.error(message: 'Invalid email or password');
        }
        
        _logger.info('✅ Offline authentication successful');
        profile = existingProfile.copyWith(
          sessionToken: _createSessionToken(),
        );
      }
      
      // Ensure profile is not null before proceeding
      if (profile == null) {
        return LoginResult.error(
          message: 'Failed to create or retrieve profile',
        );
      }
      
      // Store profile and set as active
      await _storeProfile(profile);
      await setCurrentProfile(profile.id);
      await _biometricService?.registerSuccessfulPasswordLogin();
      
      // Sync data
      if (_syncService != null) {
        _logger.info('Syncing data after login...');
        _syncService!.setCurrentProfile(profile.id);
        await _syncService!.syncAll();
        
        if (_budgetService != null) {
          await _budgetService!.loadBudgetsForProfile(profile.id);
        }
      }
      
      _logger.info('✅ User logged in successfully: $email (First login: $isFirstLogin)');
      return LoginResult.success(
        profile: profile,
        sessionToken: profile.sessionToken!,
        isFirstLogin: isFirstLogin,
      );
    } catch (e, stackTrace) {
      _logger.severe('Login failed', e, stackTrace);
      return LoginResult.error(message: 'Login failed: ${e.toString()}');
    }
  }

  /// SECURE SIGNUP
  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      _logger.info('Attempting signup for: $email');
      
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      
      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }
      
      // Try server registration
      bool serverRegistrationSuccess = false;
      String? serverToken;
      
      try {
        final isOnline = await _apiClient.checkServerHealth();
        
        if (isOnline) {
          _logger.info('Server available - registering account...');
          final response = await _apiClient.createAccount(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            avatarPath: avatarPath,
          );
          
          // FIXED: Check for token OR status 201
          serverRegistrationSuccess = response['token'] != null || 
                                      response['status'] == 201;
          serverToken = response['token'] as String?;
          
          if (serverRegistrationSuccess) {
            _logger.info('✅ Server registration successful');
            
            // Set token if provided
            if (serverToken != null) {
              _apiClient.setAuthToken(serverToken);
            }
          } else {
            final errorMsg = response['error']?.toString() ?? 
                            response['body']?.toString() ?? 
                            'Registration failed';
            throw Exception(errorMsg);
          }
        } else {
          throw Exception('Server unavailable - cannot create account offline');
        }
      } catch (e) {
        _logger.severe('Server registration error: $e');
        rethrow;
      }
      
      // Create local profile
      final userId = _uuid.v4();
      final sessionToken = _createSessionToken();
      final fullName = '$firstName $lastName'.trim();
      
      var newProfile = Profile.defaultProfile(
        id: userId,
        name: fullName,
        email: email.trim(),
        password: _hashPassword(password),
      ).copyWith(
        authToken: serverToken ?? sessionToken,
        sessionToken: sessionToken,
        phoneNumber: phone ?? '',
        photoUrl: avatarPath ?? '',
      );
      
      // CRITICAL FIX: Fetch full profile data from server after signup
      if (serverToken != null) {
        try {
          final profileResponse = await _apiClient.getProfile(
            sessionToken: serverToken,
          );
          
          if (profileResponse['success'] == true && profileResponse['profile'] != null) {
            final serverProfile = profileResponse['profile'] as Map<String, dynamic>;
            _logger.info('Merged server profile data from signup: $serverProfile');
            
            // Merge server profile data with local profile
            newProfile = newProfile.copyWith(
              baseCurrency: serverProfile['base_currency'] as String? ?? 'KES',
              timezone: serverProfile['timezone'] as String? ?? 'Africa/Nairobi',
              lastModified: serverProfile['last_modified'] != null
                  ? DateTime.parse(serverProfile['last_modified'] as String)
                  : null,
              lastLogin: serverProfile['last_login'] != null
                  ? DateTime.parse(serverProfile['last_login'] as String)
                  : null,
            );
          }
        } catch (e) {
          _logger.warning('Failed to fetch server profile data after signup: $e');
          // Continue with default profile data
        }
      }
      
      await _storeProfile(newProfile);
      await setCurrentProfile(newProfile.id);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('account_creation_attempted', true);
      
      // CRITICAL FIX: Mark first login as completed
      await prefs.setBool('is_first_login', false);
      
      if (_syncService != null) {
        _syncService!.setCurrentProfile(newProfile.id);
      }
      
      _logger.info('✅ Signup successful for: $email');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Signup failed', e, stackTrace);
      rethrow;
    }
  }

  // ==================== PASSWORD HELPERS ====================

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  bool _verifyPassword(String password, String storedHash) {
    final hash = _hashPassword(password);
    return hash == storedHash;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Logout with data sync
  Future<void> logout() async {
    try {
      await _biometricService?.clearBiometricSession();
      
      if (_syncService != null && _currentProfile != null) {
        _logger.info('Syncing data before logout...');
        try {
          await _syncService!.syncAll();
        } catch (e) {
          _logger.warning('Failed to sync before logout: $e');
        }
      }
      
      if (_currentProfile != null) {
        try {
          await _apiClient.invalidateSession();
        } catch (e) {
          _logger.warning('Failed to invalidate server session: $e');
        }
      }
      
      _syncService?.clearCache();
      _budgetService?.clearCache();
      _apiClient.clearAuthToken();
      
      await _clearSession();
      _logger.info('User logged out');
    } catch (e, stackTrace) {
      _logger.severe('Logout failed', e, stackTrace);
    }
  }

  // Biometric login
  Future<LoginResult> biometricLogin() async {
    try {
      if (_biometricService == null) {
        return LoginResult.error(message: 'Biometric service not available');
      }

      if (_currentProfile == null) {
        await _restoreActiveProfile();
      }

      if (_currentProfile == null) {
        return LoginResult.error(
          message: 'No existing profile found. Please login with email and password first.',
        );
      }

      final isAuthenticated = await _biometricService!.authenticateWithBiometric(
        'Authenticate to access your Fedha account',
      );

      if (!isAuthenticated) {
        return LoginResult.error(message: 'Biometric authentication failed or canceled');
      }

      final sessionToken = _createSessionToken();
      final updatedProfile = _currentProfile!.copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
      );

      await _storeProfile(updatedProfile);
      _currentProfile = updatedProfile;
      await _initializeProfileServices(updatedProfile.id);

      if (_syncService != null) {
        _logger.info('Syncing data after biometric login...');
        _syncService!.setCurrentProfile(updatedProfile.id);
        await _syncService!.syncAll();
        
        if (_budgetService != null) {
          await _budgetService!.loadBudgetsForProfile(updatedProfile.id);
        }
      }
      
      notifyListeners();
      
      _logger.info('Biometric login successful: ${updatedProfile.email}');
      return LoginResult.success(
        profile: updatedProfile,
        sessionToken: sessionToken,
        isFirstLogin: false,
      );
    } catch (e, stackTrace) {
      _logger.severe('Biometric login failed', e, stackTrace);
      return LoginResult.error(message: 'Biometric login failed: ${e.toString()}');
    }
  }

  Future<bool> canUseBiometricLogin() async {
    try {
      if (_currentProfile == null) {
        await _restoreActiveProfile();
      }
      
      return _biometricService != null &&
          await _biometricService!.canAuthenticate() &&
          _currentProfile != null;
    } catch (e) {
      _logger.warning('Error checking biometric availability: $e');
      return false;
    }
  }

  // Profile management methods
  Future<bool> updateProfileName(String newName) async {
    if (_currentProfile == null) return false;
    try {
      final updatedProfile = _currentProfile!.copyWith(name: newName.trim());
      await _storeProfile(updatedProfile);
      _currentProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Failed to update profile name: $e');
      return false;
    }
  }

  Future<bool> updateProfileEmail(String newEmail) async {
    if (_currentProfile == null) return false;
    if ((_currentProfile!.email ?? '').toLowerCase() == newEmail.trim().toLowerCase()) {
      return false;
    }
    try {
      final updatedProfile = _currentProfile!.copyWith(email: newEmail.trim());
      await _storeProfile(updatedProfile);
      _currentProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Failed to update profile email: $e');
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentProfile == null) return false;
    try {
      final updatedProfile = _currentProfile!.copyWith(password: newPassword);
      await _storeProfile(updatedProfile);
      _currentProfile = updatedProfile;
      return true;
    } catch (e) {
      _logger.severe('Failed to change password: $e');
      return false;
    }
  }

  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = _uuid.v4();
      final sessionToken = _createSessionToken();
      final name = '${profileData['firstName']} ${profileData['lastName']}'.trim();
      final email = profileData['email'] as String;
      
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: name,
        email: email.trim(),
        password: profileData['password'] as String? ?? 'ChangeMe123!',
      ).copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
        phoneNumber: profileData['phoneNumber'] as String? ?? '',
        photoUrl: profileData['photoUrl'] as String? ?? '',
        baseCurrency: profileData['baseCurrency'] as String? ?? 'KES',
        timezone: profileData['timezone'] as String? ?? 'GMT +3',
      );
      
      await _storeProfile(newProfile);
      await setCurrentProfile(newProfile.id);
      
      return true;
    } catch (e) {
      _logger.severe('Failed to create profile: $e');
      return false;
    }
  }

  Future<List<Profile>> getStoredProfiles() async {
    final List<Profile> profiles = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentProfileId = prefs.getString('current_profile_id');
      
      if (currentProfileId != null) {
        final profileData = await _secureStorage.read(key: 'profile_$currentProfileId');
        if (profileData != null) {
          profiles.add(Profile.fromJson(jsonDecode(profileData)));
        }
      }
    } catch (e) {
      _logger.warning('Error loading stored profiles: $e');
    }
    return profiles;
  }

  // First login flow
  Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_first_login') ?? true;
  }

  Future<bool> shouldShowBiometricPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_biometric_prompt') ?? true;
  }

  Future<bool> shouldShowPermissionsPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_permissions_prompt') ?? true;
  }

  Future<void> markFirstLoginCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_login', false);
  }

  Future<void> markBiometricPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_biometric_prompt', false);
  }

  Future<void> markPermissionsPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_permissions_prompt', false);
  }

  Future<bool> enableBiometricAuth(bool enable) async {
    if (_biometricService != null) {
      await _biometricService!.setBiometricEnabled(enable);
      return true;
    }
    return false;
  }

  // Helpers
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  String _createSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}

// ==================== LOGIN RESULT ====================

class LoginResult {
  final bool success;
  final String message;
  final Profile? profile;
  final bool isFirstLogin;
  final String? sessionToken;

  LoginResult.success({
    this.profile,
    this.sessionToken,
    this.isFirstLogin = false,
    String? message,
  })  : success = true,
        message = message ?? 'Login successful';

  LoginResult.error({required this.message})
      : success = false,
        profile = null,
        isFirstLogin = false,
        sessionToken = null;

  static LoginResult empty() => LoginResult.error(message: 'No profile found');
}