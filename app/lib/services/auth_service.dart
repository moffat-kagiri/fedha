// auth_service.dart
import 'dart:async';
import 'dart:convert';
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

  /// Login with data sync
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final existingProfile = await _getProfileByEmail(email);
      final isFirstLogin = existingProfile == null;

      Profile profile;
      if (existingProfile != null) {
        profile = existingProfile.copyWith(
          authToken: _createSessionToken(),
          sessionToken: _createSessionToken(),
        );
      } else {
        final userId = _uuid.v4();
        final tempName = email.split('@')[0];
        
        profile = Profile.defaultProfile(
          id: userId,
          name: tempName,
          email: email.trim(),
          password: password,
        ).copyWith(
          authToken: _createSessionToken(),
          sessionToken: _createSessionToken(),
        );
      }

      await _storeProfile(profile);
      await setCurrentProfile(profile.id);
      await _biometricService?.registerSuccessfulPasswordLogin();

      // ✅ CRITICAL: Sync all data after login
      if (_syncService != null) {
        _logger.info('Syncing data after login...');
        _syncService!.setCurrentProfile(profile.id);
        await _syncService!.syncAll();
        
        // Load budgets
        if (_budgetService != null) {
          await _budgetService!.loadBudgetsForProfile(profile.id);
        }
      }

      _logger.info('User logged in: $email (First login: $isFirstLogin)');
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

  /// Signup with data sync
  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final sessionToken = _createSessionToken();
      final userId = _uuid.v4();
      final fullName = '$firstName $lastName'.trim();
      
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: fullName,
        email: email.trim(),
        password: password,
      ).copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
        phoneNumber: phone ?? '',
        photoUrl: avatarPath ?? '',
      );
      
      await _storeProfile(newProfile);
      await setCurrentProfile(newProfile.id);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('account_creation_attempted', true);

      // ✅ Initialize sync for new profile
      if (_syncService != null) {
        _syncService!.setCurrentProfile(newProfile.id);
      }

      // Try to sync with server
      try {
        final isConnected = await _apiClient.checkServerHealth();
        if (isConnected) {
          await _apiClient.createAccount(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            deviceId: deviceId,
          );
        }
      } catch (e) {
        _logger.warning('Could not sync new account to server: $e');
      }
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Signup failed', e, stackTrace);
      return false;
    }
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