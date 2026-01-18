// auth_service.dart - PostgreSQL Backend Compatible (Simplified & Fixed)
import 'dart:async'show unawaited;
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
      
      _isInitialized = true;
      _logger.info('AuthService initialized - Active profile: ${_currentProfile?.name ?? "None"}');
    } catch (e, stackTrace) {
      _logger.severe('AuthService initialization failed', e, stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// Initialize with essential dependencies only (for auth_wrapper.dart)
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

  /// Restore active profile from storage
  Future<void> _restoreActiveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final currentProfileId = prefs.getString('current_profile_id');
      
      _logger.info('Restoring session - logged in: $isLoggedIn, profile ID: $currentProfileId');
      
      if (isLoggedIn && currentProfileId != null && currentProfileId.isNotEmpty) {
        // Restore auth token FIRST
        final storedToken = await _secureStorage.read(key: 'auth_token');
        if (storedToken != null && storedToken.isNotEmpty) {
          _apiClient.setAuthToken(storedToken);
          _logger.info('✅ Auth token restored from secure storage');
        } else {
          _logger.warning('⚠️ No auth token found in secure storage');
        }
        
        // Then restore profile
        final profileData = await _secureStorage.read(key: 'profile_$currentProfileId');
        
        if (profileData != null) {
          final profileJson = jsonDecode(profileData);
          _currentProfile = Profile.fromJson(profileJson);
          
          _logger.info('✅ Profile restored: ${_currentProfile!.name} (${_currentProfile!.id})');
        } else {
          _logger.warning('⚠️ Profile data not found for ID: $currentProfileId');
          await _clearSession();
        }
      } else {
        _logger.info('No active session to restore');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to restore active profile', e, stackTrace);
      await _clearSession();
    }
  }

  /// Store profile data securely
  Future<void> _storeProfile(Profile profile) async {
    try {
      final profileJson = jsonEncode(profile.toJson());
      
      // Store profile data
      await _secureStorage.write(
        key: 'profile_${profile.id}',
        value: profileJson,
      );
      
      // Store auth token separately for quick access
      if (profile.authToken != null && profile.authToken!.isNotEmpty) {
        await _secureStorage.write(
          key: 'auth_token',
          value: profile.authToken!,
        );
        _logger.info('✅ Auth token stored securely');
      }
      
      _logger.info('✅ Profile stored: ${profile.name} (${profile.id})');
    } catch (e, stackTrace) {
      _logger.severe('Failed to store profile', e, stackTrace);
      rethrow;
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
      
      // Set auth token in API client
      if (profile.authToken != null && profile.authToken!.isNotEmpty) {
        _apiClient.setAuthToken(profile.authToken!);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_profile_id', profileId);
      await prefs.setBool('is_logged_in', true);
      
      await _initializeProfileServices(profileId);
      
      notifyListeners();
      _logger.info('✅ Current profile set: ${profile.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to set current profile', e, stackTrace);
      return false;
    }
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
      
      _logger.info('✅ Profile services initialized for: $profileId');
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
    
    // Clear stored token but NOT data!
    await _secureStorage.delete(key: 'auth_token');
    
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      _logger.warning('Failed to cancel background tasks: $e');
    }
    
    notifyListeners();
  }

  // ==================== AUTH METHODS ====================

  /// Login with automatic data persistence
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Attempting login for: $email');
      
      // Authenticate with server
      final serverResponse = await _apiClient.login(
        email: email,
        password: password,
      );
      
      // Check if authentication succeeded
      if (serverResponse['success'] != true || serverResponse['token'] == null) {
        final errorMsg = serverResponse['error']?.toString() ?? 
                        serverResponse['body']?.toString() ?? 
                        'Invalid email or password';
        _logger.warning('❌ Server authentication failed: $errorMsg');
        return LoginResult.error(message: errorMsg);
      }
      
      _logger.info('✅ Server authentication successful');
      final authToken = serverResponse['token'] as String;
      
      // Set token in API client immediately
      _apiClient.setAuthToken(authToken);
      
      // Fetch full profile data from server
      final profileResponse = await _apiClient.getProfile(
        sessionToken: authToken,
      );
      
      if (profileResponse['success'] != true || profileResponse['profile'] == null) {
        _logger.warning('Failed to fetch profile data from server');
        return LoginResult.error(message: 'Failed to retrieve profile data');
      }
      
      final serverProfile = profileResponse['profile'] as Map<String, dynamic>;
      final userData = serverResponse['user'] as Map<String, dynamic>?;
      
      // Extract user data
      final userId = serverProfile['id']?.toString() ?? _uuid.v4();
      final firstName = userData?['first_name']?.toString() ?? 
                      serverProfile['first_name']?.toString() ?? 
                      email.split('@')[0];
      final lastName = userData?['last_name']?.toString() ?? 
                      serverProfile['last_name']?.toString() ?? 
                      '';
      final fullName = '$firstName $lastName'.trim();
      
      // Create profile with server data
      final profile = Profile.defaultProfile(
        id: userId,
        name: fullName,
        email: email.trim(),
        password: _hashPassword(password),
      ).copyWith(
        authToken: authToken,
        sessionToken: authToken,
        baseCurrency: serverProfile['base_currency'] as String? ?? 'KES',
        timezone: serverProfile['timezone'] as String? ?? 'Africa/Nairobi',
        phoneNumber: serverProfile['phone_number'] as String? ?? '',
        lastModified: serverProfile['last_modified'] != null
            ? DateTime.tryParse(serverProfile['last_modified'] as String)
            : null,
        lastLogin: DateTime.now(),
      );
      
      // Store profile and set as active
      await _storeProfile(profile);
      await setCurrentProfile(profile.id);
      await _biometricService?.registerSuccessfulPasswordLogin();
      
      // ✅ NEW: Trigger initial sync via UnifiedSyncService
      if (_syncService != null) {
        _logger.info('🔄 Triggering initial data sync...');
        _syncService!.setCurrentProfile(profile.id);
        
        // Perform initial sync in background (don't block login)
        unawaited(_syncService!.performInitialSync(profile.id, authToken));
      } else {
        _logger.warning('⚠️ SyncService not available - data will sync on next app launch');
      }
      
      _logger.info('✅ Login successful: $email');
      return LoginResult.success(
        profile: profile,
        sessionToken: authToken,
        isFirstLogin: false,
      );
    } catch (e, stackTrace) {
      _logger.severe('Login failed', e, stackTrace);
      
      // Try offline login as fallback
      return await _attemptOfflineLogin(email, password);
    }
  }

  /// Offline login fallback
  Future<LoginResult> _attemptOfflineLogin(String email, String password) async {
    try {
      final existingProfile = await _getProfileByEmail(email);
      
      if (existingProfile == null) {
        return LoginResult.error(
          message: 'No account found. Please connect to the internet to login.',
        );
      }
      
      if (!_verifyPassword(password, existingProfile.password)) {
        _logger.warning('Offline password verification failed');
        return LoginResult.error(message: 'Invalid email or password');
      }
      
      _logger.info('✅ Offline authentication successful');
      
      final sessionToken = _createSessionToken();
      final profile = existingProfile.copyWith(
        sessionToken: sessionToken,
        lastLogin: DateTime.now(),
      );
      
      await _storeProfile(profile);
      await setCurrentProfile(profile.id);
      
      _logger.info('✅ Offline login successful: $email');
      return LoginResult.success(
        profile: profile,
        sessionToken: sessionToken,
        isFirstLogin: false,
      );
    } catch (e, stackTrace) {
      _logger.severe('Offline login failed', e, stackTrace);
      return LoginResult.error(message: 'Login failed: ${e.toString()}');
    }
  }

  /// Get profile by email
  Future<Profile?> _getProfileByEmail(String email) async {
    try {
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
    } catch (e) {
      _logger.warning('Error checking existing profile: $e');
    }
    return null;
  }

  /// Signup method 
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
      
      // Basic validation
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      
      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }
      
      // Check server availability
      final isOnline = await _apiClient.checkServerHealth();
      
      if (!isOnline) {
        throw Exception('Server unavailable - cannot create account offline');
      }
      
      // Register with server
      _logger.info('Registering account with backend...');
      final response = await _apiClient.createAccount(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        avatarPath: avatarPath,
      );
      
      // Check registration success
      if (response['success'] != true && response['status'] != 201) {
        final errorMsg = response['error']?.toString() ?? 
                        response['body']?.toString() ?? 
                        'Registration failed';
        throw Exception(errorMsg);
      }
      
      _logger.info('✅ Server registration successful');
      final authToken = response['token'] as String?;
      
      // Set token if provided
      if (authToken != null) {
        _apiClient.setAuthToken(authToken);
      }
      
      // Try to fetch profile from server
      Map<String, dynamic>? serverProfile;
      if (authToken != null) {
        try {
          final profileResponse = await _apiClient.getProfile(sessionToken: authToken);
          if (profileResponse['success'] == true) {
            serverProfile = profileResponse['profile'] as Map<String, dynamic>?;
          }
        } catch (e) {
          _logger.warning('Failed to fetch profile: $e');
        }
      }
      
      // Create local profile
      final userId = serverProfile?['id']?.toString() ?? 
                    response['user_id']?.toString() ?? 
                    _uuid.v4();
      final sessionToken = authToken ?? _createSessionToken();
      final fullName = '$firstName $lastName'.trim();
      
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: fullName,
        email: email.trim(),
        password: _hashPassword(password),
      ).copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
        phoneNumber: phone ?? serverProfile?['phone_number'] as String? ?? '',
        photoUrl: avatarPath ?? serverProfile?['avatar_url'] as String? ?? '',
        baseCurrency: serverProfile?['base_currency'] as String? ?? 'KES',
        timezone: serverProfile?['timezone'] as String? ?? 'Africa/Nairobi',
        lastModified: serverProfile?['last_modified'] != null
            ? DateTime.tryParse(serverProfile?['last_modified'] as String)
            : null,
        lastLogin: DateTime.now(),
      );
      
      await _storeProfile(newProfile);
      await setCurrentProfile(newProfile.id);
      
      // ✅ NEW: Trigger initial sync via UnifiedSyncService
      if (_syncService != null && authToken != null) {
        _logger.info('🔄 Triggering initial data sync...');
        _syncService!.setCurrentProfile(newProfile.id);
        
        // Perform initial sync in background
        unawaited(_syncService!.performInitialSync(newProfile.id, authToken));
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_login', false);
      
      _logger.info('✅ Signup successful: $email');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Signup failed', e, stackTrace);
      rethrow;
    }
  }

  /// Biometric login
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
        sessionToken: sessionToken,
        lastLogin: DateTime.now(),
      );

      await _storeProfile(updatedProfile);
      await setCurrentProfile(updatedProfile.id);
      
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

  /// Simplified logout (preserves data)
  Future<void> logout() async {
    try {
      await _biometricService?.clearBiometricSession();
      
      // Clear auth tokens but NOT data!
      _apiClient.clearAuthToken();
      await _secureStorage.delete(key: 'auth_token');
      
      // Clear session
      await _clearSession();
      
      _logger.info('✅ User logged out (data preserved)');
    } catch (e, stackTrace) {
      _logger.severe('Logout failed', e, stackTrace);
    }
  }

  // ==================== PROFILE MANAGEMENT ====================

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
      // Verify current password
      if (!_verifyPassword(currentPassword, _currentProfile!.password)) {
        throw Exception('Current password is incorrect');
      }
      
      // Validate new password
      final passwordError = _validatePassword(newPassword);
      if (passwordError != null) {
        throw Exception(passwordError);
      }
      
      final updatedProfile = _currentProfile!.copyWith(
        password: _hashPassword(newPassword),
      );
      await _storeProfile(updatedProfile);
      _currentProfile = updatedProfile;
      return true;
    } catch (e) {
      _logger.severe('Failed to change password: $e');
      return false;
    }
  }

  // ==================== FIRST LOGIN & BIOMETRIC METHODS ====================

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

  // ==================== HELPER METHODS ====================

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

  String _createSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  Future<bool> isLoggedIn() async => hasActiveProfile;

  Future<String?> getStoredProfile() async {
    try {
      if (_currentProfile != null) {
        return jsonEncode(_currentProfile!.toJson());
      }
      return null;
    } catch (e) {
      _logger.severe('Failed to get stored profile: $e');
      return null;
    }
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