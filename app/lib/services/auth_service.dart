// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/profile.dart';
import '../services/api_client.dart';
import '../services/biometric_auth_service.dart';
import '../utils/logger.dart';

class AuthService extends ChangeNotifier {
  late final ApiClient _apiClient;
  final _secureStorage = const FlutterSecureStorage();
  final _logger = AppLogger.getLogger('AuthService');
  final _uuid = Uuid();

  Box<Profile>? _profileBox;
  Profile? _currentProfile;
  BiometricAuthService? _biometricService;

  AuthService([ApiClient? apiClient]) {
    _apiClient = apiClient ?? ApiClient();
    // Optionally initialize biometric service here
    _biometricService = BiometricAuthService.instance;
    initialize();
  }

  // Getters
  Profile? get profile => _currentProfile;
  Profile? get currentProfile => _currentProfile;
  BiometricAuthService? get biometricService => _biometricService;

  bool isLoggedIn() => _currentProfile != null;

  /// Initialize AuthService by restoring any existing session
  Future<void> initialize() async {
    // Open Hive box for profiles
    // Attempt to restore last logged-in profile
    try {
      final storedId = await _secureStorage.read(key: 'current_profile_id');
      if (storedId != null) {
        final storedProfile = _profileBox?.get(storedId);
        if (storedProfile != null) {
          _currentProfile = storedProfile;
        }
      }
    } catch (e) {
      _logger.warning('Failed to restore session: $e');
    }
    _logger.info('AuthService initialized, currentProfile: ${_currentProfile?.id}');
  }

  Future<void> _restoreLastProfile() async {
    // Restore profile from persistent storage if available
  }

  Future<LoginResult> login({required String email, required String password}) async {
    // Dummy login implementation
    return LoginResult.error(message: 'Login not implemented');
  }

  Future<LoginResult> loginWithBiometric() async {
    try {
      if (_biometricService == null) {
        return LoginResult.error(message: 'Biometric service not available');
      }
      final isAuthenticated = await _biometricService!.authenticateWithBiometric('Please authenticate');
      if (!isAuthenticated) return LoginResult.error(message: 'Biometric authentication failed');
      if (_currentProfile == null) return LoginResult.error(message: 'No current profile');
      final sessionToken = _createSessionToken();
      final updatedProfile = _currentProfile!.copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
      );
      await _profileBox?.put(updatedProfile.id, updatedProfile);
      await _secureStorage.write(key: 'session_token', value: sessionToken);
      _currentProfile = updatedProfile;
      notifyListeners();
      return LoginResult.success(profile: updatedProfile, sessionToken: sessionToken);
    } catch (e) {
      _logger.severe('Biometric login failed: $e');
      return LoginResult.error(message: 'Biometric login failed: ${e.toString()}');
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
      if (_profileBox == null) await initialize();
      final existingProfiles = _profileBox?.values.cast<Profile>().toList() ?? [];
      final emailExists = existingProfiles.any((profile) => (profile.email ?? '').toLowerCase() == email.toLowerCase());
      if (emailExists) {
        _logger.warning('Email already registered: $email');
        return false;
      }
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
      await _profileBox?.put(userId, updatedProfile);
  await _secureStorage.write(key: 'current_profile_id', value: userId);
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
      await _secureStorage.delete(key: 'current_profile_id');
      await _secureStorage.delete(key: 'session_token');
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
      await _profileBox?.put(_currentProfile!.id, updatedProfile);
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
      await _profileBox?.put(_currentProfile!.id, updatedProfile);
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

  Future<Box<Profile>> getProfileBox() async {
    if (_profileBox == null) await initialize();
    return _profileBox!;
  }

  void setCurrentProfile(Profile profile) {
    _currentProfile = profile;
    notifyListeners();
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
    // For now, simply call login
    return login(email: email, password: password);
  }

  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    try {
      if (_profileBox == null) await initialize();
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
      await _profileBox?.put(userId, updatedProfile);
      await _secureStorage.write(key: 'current_profile_id', value: userId);
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
