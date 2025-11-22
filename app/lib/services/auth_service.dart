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
    
    // Try to restore existing session on startup
    await _restoreExistingSession();
  }

  Future<void> _restoreExistingSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (isLoggedIn) {
        final profileData = await _secureStorage.read(key: 'current_profile_data');
        if (profileData != null) {
          final profileJson = jsonDecode(profileData);
          _currentProfile = Profile.fromJson(profileJson);
          _logger.info('Restored existing session for: ${_currentProfile?.email}');
        }
      }
    } catch (e) {
      _logger.warning('Failed to restore session: $e');
    }
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
        // Check if we already have a profile for this email
        final existingProfile = await _getProfileByEmail(email);
        final bool isFirstLogin = existingProfile == null;

        Profile profile;
        if (existingProfile != null) {
        // Use existing profile
        profile = existingProfile.copyWith(
            authToken: _createSessionToken(),
            sessionToken: _createSessionToken(),
        );
        } else {
        // Create new profile for first login
        final deviceId = await _getOrCreateDeviceId();
        final userId = _uuid.v4();
        
        // For first-time login, we don't have first/last name yet
        // Use email username as temporary name - user can update later
        final tempName = email.split('@')[0];
        
        profile = Profile.defaultProfile(
            id: userId,
            name: tempName, // Temporary name until user updates profile
            email: email.trim(),
            password: password,
        ).copyWith(
            authToken: _createSessionToken(),
            sessionToken: _createSessionToken(),
        );
        }

        // Persist profile and session
        await _secureStorage.write(
            key: 'current_profile_data',
            value: jsonEncode(profile.toJson()),
        );
        await _secureStorage.write(key: 'session_token', value: profile.sessionToken!);

        // Store login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('profile_id', profile.id);

        // Register biometric session for password login
        await _biometricService?.registerSuccessfulPasswordLogin();

        // Initialize SMS listener (only once)
        await _initializeSmsListener(profile.id);

        _currentProfile = profile;
        notifyListeners();

        _logger.info('User logged in successfully: $email (First login: $isFirstLogin)');
        return LoginResult.success(
            profile: profile, 
            sessionToken: profile.sessionToken!,
            isFirstLogin: isFirstLogin
        );

        } catch (e) {
        _logger.severe('Login failed: $e');
        return LoginResult.error(message: 'Login failed: ${e.toString()}');
        }
    }

  Future<Profile?> _getProfileByEmail(String email) async {
    try {
      final profileData = await _secureStorage.read(key: 'current_profile_data');
      if (profileData != null) {
        final profileJson = jsonDecode(profileData);
        final existingProfile = Profile.fromJson(profileJson);
        if (existingProfile.email?.toLowerCase() == email.toLowerCase()) {
          return existingProfile;
        }
      }
    } catch (e) {
      _logger.warning('Error checking existing profile: $e');
    }
    return null;
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
        final fullName = '$firstName $lastName'.trim(); // Use actual names from form
        
        final newProfile = Profile.defaultProfile(
        id: userId,
        name: fullName, // Use the combined first + last name
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
        notifyListeners();

        // Try to sync with server if available
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
      
      // Clear login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('profile_id');

      // Cancel SMS listener service
      await Workmanager().cancelByUniqueName('sms_listener');
      
      notifyListeners();
      _logger.info('User logged out');
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }
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

  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    try {
        final userId = _uuid.v4();
        final sessionToken = _createSessionToken();
        final name = '${profileData['firstName']} ${profileData['lastName']}'.trim(); // Combine names
        final email = profileData['email'] as String;
        
        final newProfile = Profile.defaultProfile(
        id: userId,
        name: name, // Use combined first + last name
        email: email.trim(),
        password: profileData['password'] as String? ?? 'ChangeMe123!',
        );
        
        final updatedProfile = newProfile.copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
        phoneNumber: profileData['phoneNumber'] as String? ?? '',
        photoUrl: profileData['photoUrl'] as String? ?? '',
        baseCurrency: profileData['baseCurrency'] as String? ?? 'KES',
        timezone: profileData['timezone'] as String? ?? 'GMT +3',
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
        
        // Check for existing profile matching email
        final existingProfile = await _getProfileByEmail(email);
        if (existingProfile != null) {
            final sessionToken = _createSessionToken();
            final updatedProfile = existingProfile.copyWith(
            authToken: sessionToken,
            sessionToken: sessionToken,
            );
            
            await _secureStorage.write(
            key: 'current_profile_data',
            value: jsonEncode(updatedProfile.toJson()),
            );
            await _secureStorage.write(key: 'session_token', value: sessionToken);

            // Register biometric session
            await _biometricService?.registerSuccessfulBiometricSession();

            _currentProfile = updatedProfile;
            notifyListeners();
            
            return LoginResult.success(
            profile: updatedProfile, 
            sessionToken: sessionToken,
            isFirstLogin: false // Biometric login is never first login
            );
        } else {
            return LoginResult.error(message: 'No existing profile found for biometric login');
        }
        }

        // Fall back to regular login if not using biometric or no matching profile
        return await login(email: email, password: password);

    } catch (e) {
        _logger.severe('Enhanced login failed: $e');
        return LoginResult.error(message: 'Login failed: ${e.toString()}');
    }
    }


  /// Initialize the SMS listener service with the current profile
  Future<void> _initializeSmsListener(String profileId) async {
    try {
      // Cancel any existing SMS listener first
      await Workmanager().cancelByUniqueName('sms_listener');
      
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
    } catch (e) {
      _logger.warning('Failed to initialize SMS listener: $e');
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