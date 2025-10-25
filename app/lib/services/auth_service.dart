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

class AuthService with ChangeNotifier {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  final _uuid = Uuid();
  final _secureStorage = FlutterSecureStorage();
  final _apiClient = ApiClient.instance;
  final _logger = AppLogger.getLogger('AuthService');
  final _offlineDataService = OfflineDataService();
  BiometricAuthService? _biometricService;

  Profile? _currentProfile;

  AuthService._();

  Profile? get currentProfile => _currentProfile;
  
  void setCurrentProfile(Profile profile) {
    _currentProfile = profile;
    notifyListeners();
  }

  Future<void> initialize() async {
    _biometricService = BiometricAuthService.instance;
    await _biometricService?.initialize();
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      _logger.severe('Failed to check login status: $e');
      return false;
    }
  }

  Future<String?> getStoredProfile() async {
    try {
      return await _secureStorage.read(key: 'current_profile_data');
    } catch (e) {
      _logger.severe('Failed to get stored profile: $e');
      return null;
    }
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Get device ID and create session
      final deviceId = await _getOrCreateDeviceId();
      final sessionToken = _createSessionToken();
      final userId = _uuid.v4();
      
      // Create or retrieve profile
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: email.split('@')[0], // Temporary name from email
        email: email.trim(),
        password: password,
      );

      final updatedProfile = newProfile.copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
      );

      // Persist profile and session
      await _secureStorage.write(
        key: 'current_profile_data',
        value: jsonEncode(updatedProfile.toJson()),
      );
      await _secureStorage.write(key: 'session_token', value: sessionToken);

      // Store login state for background services
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('profile_id', userId);

      // Initialize background SMS listener
      await Workmanager().registerPeriodicTask(
        'sms_listener',
        'sms_listener_task',
        frequency: const Duration(hours: 3),
        inputData: {
          'profileId': userId
        }
      );

      _currentProfile = updatedProfile;
      notifyListeners();

      _logger.info('User logged in successfully: $email');
      return LoginResult.success(
        profile: updatedProfile, 
        sessionToken: sessionToken,
        isFirstLogin: true
      );

    } catch (e) {
      _logger.severe('Login failed: $e');
      return LoginResult.error(message: 'Login failed: ${e.toString()}');
    }
  }

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
      );
      final updatedProfile = newProfile.copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
        phoneNumber: phone ?? '',
        photoUrl: avatarPath ?? '',
      );
      // Persist new profile JSON
      await _secureStorage.write(
        key: 'current_profile_data',
        value: jsonEncode(updatedProfile.toJson()),
      );
      await _secureStorage.write(key: 'session_token', value: sessionToken);
      // Persist that an account has been created
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('account_creation_attempted', true);
      _currentProfile = updatedProfile;
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
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Signup failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_biometricService != null) {
        await _biometricService!.clearBiometricSession();
      }
      if (_currentProfile != null) {
        try {
          await _apiClient.invalidateSession();
        } catch (e) {
          _logger.severe('Failed to invalidate server session: $e');
        }
      }
      _currentProfile = null;
      await _secureStorage.delete(key: 'current_profile_data');
      await _secureStorage.delete(key: 'session_token');
      notifyListeners();
      _logger.info('User logged out');
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }

    // Clear login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('profile_id');

    // Cancel SMS listener service
    await Workmanager().cancelByUniqueName('sms_listener');
  }

  Future<bool> updateProfileName(String newName) async {
    if (_currentProfile == null) return false;
    try {
      final updatedProfile = _currentProfile!.copyWith(name: newName.trim());
      // Persist updated profile JSON
      await _secureStorage.write(
        key: 'current_profile_data',
        value: jsonEncode(updatedProfile.toJson()),
      );
      _currentProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Failed to update profile name: $e');
      return false;
    }
  }

  Future<bool> updateProfileEmail(String newEmail) async {
    if (_currentProfile == null || (_currentProfile!.email ?? '').toLowerCase() == newEmail.trim().toLowerCase()) return false;
    try {
      final updatedProfile = _currentProfile!.copyWith(email: newEmail.trim());
      // Persist updated profile JSON
      await _secureStorage.write(
        key: 'current_profile_data',
        value: jsonEncode(updatedProfile.toJson()),
      );
      _currentProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Failed to update profile email: $e');
      return false;
    }
  }

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


  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentProfile == null) return false;
    try {
      // Simulate password change; in real apps validate with server
      return true;
    } catch (e) {
      _logger.severe('Failed to change password: $e');
      return false;
    }
  }

  Future<LoginResult> enhancedLogin({
    required String email,
    required String password,
    bool useBiometric = false,
  }) async {
    try {
      // Handle biometric authentication if requested
      if (useBiometric) {
        if (_biometricService == null) {
          return LoginResult.error(message: 'Biometric service not available');
        }
        final isAuthenticated = await _biometricService!.authenticateWithBiometric('Please authenticate');
        if (!isAuthenticated) {
          return LoginResult.error(message: 'Biometric authentication failed');
        }
        // If current profile exists and matches email, proceed with biometric login
        if (_currentProfile != null && _currentProfile!.email == email) {
          final sessionToken = _createSessionToken();
          final updatedProfile = _currentProfile!.copyWith(
            authToken: sessionToken,
            sessionToken: sessionToken,
          );
          await _secureStorage.write(
            key: 'current_profile_data',
            value: jsonEncode(updatedProfile.toJson()),
          );
          await _secureStorage.write(key: 'session_token', value: sessionToken);
          _currentProfile = updatedProfile;
          notifyListeners();
          return LoginResult.success(profile: updatedProfile, sessionToken: sessionToken);
        }
      }

      // Proceed with normal login if not using biometric or no matching profile
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return LoginResult.error(message: 'Email and password are required');
      }

      // Get device ID and create session
      final deviceId = await _getOrCreateDeviceId();
      final sessionToken = _createSessionToken();
      
      // Try server authentication if available
      try {
        final isConnected = await _apiClient.checkServerHealth();
        if (isConnected) {
          await _apiClient.login(
            email: email, 
            password: password,
            // Note: deviceId is stored but not sent to server yet
          );
        }
      } catch (e) {
        _logger.warning('Could not authenticate with server: $e');
        // Continue with local authentication
      }

      // Create or retrieve profile
      final userId = _uuid.v4();
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: email.split('@')[0], // Temporary name from email
        email: email.trim(),
        password: password,
      );

      final updatedProfile = newProfile.copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
      );

      // Persist profile and session
      await _secureStorage.write(
        key: 'current_profile_data',
        value: jsonEncode(updatedProfile.toJson()),
      );
      await _secureStorage.write(key: 'session_token', value: sessionToken);

      // Store login state for background services
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('profile_id', userId);

      // Initialize background SMS listener
      await Workmanager().registerPeriodicTask(
        'sms_listener',
        'sms_listener_task',
        frequency: const Duration(hours: 3),
        inputData: {
          'profileId': userId
        }
      );

      _currentProfile = updatedProfile;
      notifyListeners();

      _logger.info('User logged in successfully: $email');
      return LoginResult.success(
        profile: updatedProfile, 
        sessionToken: sessionToken,
        isFirstLogin: true
      );

    } catch (e) {
      _logger.severe('Login failed: $e');
      return LoginResult.error(message: 'Login failed: ${e.toString()}');
    }
  }

  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = _uuid.v4();
      final sessionToken = _createSessionToken();
      final name = profileData['name'] as String;
      final email = profileData['email'] as String;
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: name.trim(),
        email: email.trim(),
        password: profileData['password'] as String? ?? 'ChangeMe123!',
      );
      final updatedProfile = newProfile.copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
        phoneNumber: profileData['phoneNumber'] as String? ?? '',
        photoUrl: profileData['photoUrl'] as String? ?? '',
        baseCurrency: profileData['baseCurrency'] as String? ?? 'USD',
        timezone: profileData['timezone'] as String? ?? 'UTC',
      );
      // Persist new profile
      await _secureStorage.write(
        key: 'current_profile_data',
        value: jsonEncode(updatedProfile.toJson()),
      );
      await _secureStorage.write(key: 'session_token', value: sessionToken);
      _currentProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Failed to create profile: $e');
      return false;
    }
  }

  // First login methods
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

  Future<bool> enableBiometricAuth(bool enable) async {
    if (_biometricService != null) {
      await _biometricService!.setBiometricEnabled(enable);
      return true;
    }
    return false;
  }

  Future<void> markPermissionsPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_permissions_prompt', false);
  }

  /// Initialize the SMS listener service with the current profile
  Future<void> _initializeSmsListener(String profileId) async {
      // Initialize background SMS listener with offline data service
      final smsService = SmsListenerService.instance;
      await smsService.initialize(
        offlineDataService: _offlineDataService,
        profileId: profileId
      );
    
      // Register background task
      await Workmanager().registerPeriodicTask(
        'sms_listener',
        'sms_listener_task',
        frequency: const Duration(hours: 3),
        inputData: {
          'profileId': profileId
        }
      );
  }
}

class LoginResult {
  final bool success;
  final String message;
  final Profile? profile;
  final bool isFirstLogin;
  final String? sessionToken;

  LoginResult.success({this.profile, this.sessionToken, this.isFirstLogin = false, String? message})
      : success = true,
        message = message ?? 'Login successful';

  LoginResult.error({required this.message})
      : success = false,
        profile = null,
        isFirstLogin = false,
        sessionToken = null;

  static LoginResult empty() => LoginResult.error(message: 'No profile found');
}