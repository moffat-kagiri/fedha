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

  // ✅ Dependencies injected, not created
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

  // ✅ Getters
  Profile? get currentProfile => _currentProfile;
  String? get profileId => _currentProfile?.id;
  bool get isInitialized => _isInitialized;
  bool get hasActiveProfile => _currentProfile != null && _currentProfile!.id.isNotEmpty;

  /// Initialize with all dependencies including sync services
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
      
      // Inject dependencies
      _offlineDataService = offlineDataService;
      _biometricService = biometricService;
      _syncService = syncService;
      _budgetService = budgetService;
      
      // Restore active profile
      await _restoreActiveProfile();
      
      // Sync data if profile is restored
      if (_currentProfile != null && _syncService != null) {
        _logger.info('Syncing data for restored profile...');
        _syncService!.setCurrentProfile(_currentProfile!.id);
        await _syncService!.syncAll();
        
        // Load budgets
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
      
      // Inject dependencies
      _offlineDataService = offlineDataService;
      _biometricService = biometricService;
      
      // Restore active profile
      await _restoreActiveProfile();
      
      _isInitialized = true;
      _logger.info('AuthService initialized - Active profile: ${_currentProfile?.name ?? "None"}');
    } catch (e, stackTrace) {
      _logger.severe('AuthService initialization failed', e, stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  /// ✅ DEPRECATED: Use initializeWithDependencies instead
  @Deprecated('Use initializeWithDependencies() for proper dependency injection')
  Future<void> initialize() async {
    _logger.warning('Using deprecated initialize() method. Use initializeWithDependencies() instead.');
    
    if (!_isInitialized) {
      // Fallback for backward compatibility
      _offlineDataService ??= OfflineDataService();
      await _offlineDataService!.initialize();
      await initializeWithDependencies(
        offlineDataService: _offlineDataService!,
        biometricService: _biometricService,
      );
    }
  }

  /// ✅ Restore active profile from persistent storage
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

  /// ✅ Set current profile by ID
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
      
      // Persist active profile selection
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_profile_id', profileId);
      await prefs.setBool('is_logged_in', true);
      
      // Initialize profile-specific services
      await _initializeProfileServices(profileId);
      
      notifyListeners();
      _logger.info('Current profile set: ${profile.name}');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to set current profile', e, stackTrace);
      return false;
    }
  }

  /// ✅ Store profile data with proper key
  Future<void> _storeProfile(Profile profile) async {
    try {
      final profileJson = jsonEncode(profile.toJson());
      
      // Store with unique profile key
      await _secureStorage.write(
        key: 'profile_${profile.id}',
        value: profileJson,
      );
      
      // Legacy compatibility key
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

  /// ✅ Get profile by email
  Future<Profile?> _getProfileByEmail(String email) async {
    try {
      // Check current profile first
      if (_currentProfile?.email?.toLowerCase() == email.toLowerCase()) {
        return _currentProfile;
      }
      
      // Check stored profile
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
      
      // Check legacy storage
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

  /// ✅ Initialize services for specific profile
  Future<void> _initializeProfileServices(String profileId) async {
    if (_offlineDataService == null) {
      _logger.warning('OfflineDataService not available for profile initialization');
      return;
    }

    try {
      // Cancel existing background tasks
      await Workmanager().cancelAll();
      
      // Initialize SMS listener
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

  /// ✅ Clear all session data
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

  // ==================== PUBLIC AUTH METHODS ====================

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

  /// ✅ SECURE LOGIN - Validates credentials with server
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Attempting login for: $email');
      
      // ✅ STEP 1: Try server authentication first
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
          
          serverAuthSuccess = serverResponse['success'] == true || 
                            serverResponse['token'] != null;
          
          if (serverAuthSuccess) {
            _logger.info('Server authentication successful');
          } else {
            _logger.warning('Server authentication failed: ${serverResponse['error'] ?? serverResponse['body']}');
            return LoginResult.error(
              message: 'Invalid email or password',
            );
          }
        } else {
          _logger.warning('Server unavailable - checking offline credentials');
        }
      } catch (e) {
        _logger.warning('Server authentication error: $e');
        // Proceed to offline check
      }
      // ✅ STEP 2: Check/create local profile
      Profile? profile;
      bool isFirstLogin = false;
      
      if (serverAuthSuccess && serverResponse != null) {
        // Server auth succeeded - create/update local profile
        final existingProfile = await _getProfileByEmail(email);
        
        if (existingProfile != null) {
          // Update existing profile
          profile = existingProfile.copyWith(
            authToken: serverResponse['token'] as String?,
            sessionToken: _createSessionToken(),
          );
        } else {
          // Create new profile from server response
          isFirstLogin = true;
          final userId = _uuid.v4();
          final userData = serverResponse['user'] as Map<String, dynamic>?;
          
          final firstName = userData?['first_name'] ?? email.split('@')[0];
          final lastName = userData?['last_name'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          
          profile = Profile.defaultProfile(
            id: userId,
            name: fullName,
            email: email.trim(),
            password: _hashPassword(password), // Store hashed locally
          ).copyWith(
            authToken: serverResponse['token'] as String?,
            sessionToken: _createSessionToken(),
          );
        }
      } else {
        // ✅ STEP 3: Offline fallback - verify against stored credentials
        final existingProfile = await _getProfileByEmail(email);
        
        if (existingProfile == null) {
          return LoginResult.error(
            message: 'No account found. Please connect to the internet to create an account.',
          );
        }
        
        // Verify password matches stored hash
        if (!_verifyPassword(password, existingProfile.password)) {
          _logger.warning('Offline password verification failed');
          return LoginResult.error(
            message: 'Invalid email or password',
          );
        }
        
        _logger.info('Offline authentication successful');
        profile = existingProfile.copyWith(
          sessionToken: _createSessionToken(),
        );
      }
      
      // ✅ STEP 4: Store profile and set as active
      await _storeProfile(profile);
      await setCurrentProfile(profile.id);
      await _biometricService?.registerSuccessfulPasswordLogin();
      
      // ✅ STEP 5: Sync data
      if (_syncService != null) {
        _logger.info('Syncing data after login...');
        _syncService!.setCurrentProfile(profile.id);
        await _syncService!.syncAll();
        
        if (_budgetService != null) {
          await _budgetService!.loadBudgetsForProfile(profile.id);
        }
      }
      
      _logger.info('User logged in successfully: $email (First login: $isFirstLogin)');
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

  /// ✅ SECURE SIGNUP - Validates with server
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
      
      // ✅ STEP 1: Validate email format
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      
      // ✅ STEP 2: Validate password strength
      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }
      
      // ✅ STEP 3: Try server registration first
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
          
          serverRegistrationSuccess = response['success'] == true || 
                                      response['token'] != null;
          serverToken = response['token'] as String?;
          
          if (serverRegistrationSuccess) {
            _logger.info('Server registration successful');
          } else {
            final errorMsg = response['error']?.toString() ?? 
                            response['errors']?.toString() ?? 
                            'Registration failed';
            throw Exception(errorMsg);
          }
        } else {
          _logger.warning('Server unavailable - creating offline account');
        }
      } catch (e) {
        _logger.severe('Server registration error: $e');
        rethrow;
      }
      
      // ✅ STEP 4: Create local profile
      final userId = _uuid.v4();
      final sessionToken = _createSessionToken();
      final fullName = '$firstName $lastName'.trim();
      
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: fullName,
        email: email.trim(),
        password: _hashPassword(password), // Store hashed
      ).copyWith(
        authToken: serverToken ?? sessionToken,
        sessionToken: sessionToken,
        phoneNumber: phone ?? '',
        photoUrl: avatarPath ?? '',
      );
      
      await _storeProfile(newProfile);
      await setCurrentProfile(newProfile.id);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('account_creation_attempted', true);
      
      // ✅ Initialize sync
      if (_syncService != null) {
        _syncService!.setCurrentProfile(newProfile.id);
      }
      
      _logger.info('Signup successful for: $email');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Signup failed', e, stackTrace);
      rethrow;
    }
  }

  // ==================== PASSWORD SECURITY HELPERS ====================

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    // Simple hash for local storage
    // In production, use a proper key derivation function
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify password against stored hash
  bool _verifyPassword(String password, String storedHash) {
    final hash = _hashPassword(password);
    return hash == storedHash;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
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
    
    return null; // Password is valid
  }

  /// Logout with data sync
  Future<void> logout() async {
    try {
      await _biometricService?.clearBiometricSession();
      
      // ✅ CRITICAL: Sync data before logout
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
      
      // Clear service caches
      _syncService?.clearCache();
      _budgetService?.clearCache();
      
      await _clearSession();
      _logger.info('User logged out');
    } catch (e, stackTrace) {
      _logger.severe('Logout failed', e, stackTrace);
    }
  }

  // Biometric login with data sync
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

      // ✅ CRITICAL: Sync data after biometric login
      if (_syncService != null) {
        _logger.info('Syncing data after biometric login...');
        _syncService!.setCurrentProfile(updatedProfile.id);
        await _syncService!.syncAll();
        
        // Load budgets
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

  // ==================== FIRST LOGIN FLOW ====================

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

  // ==================== HELPERS ====================

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