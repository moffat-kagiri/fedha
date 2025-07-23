// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';
import '../utils/app_logger.dart';
import './api_client.dart';
import './biometric_auth_service.dart';
import './sync_manager.dart';

class LoginResult {
  final bool success;
  final String message;
  final Profile? profile;
  final String? sessionToken;
  final String? errorCode;

  LoginResult({
    required this.success,
    required this.message,
    this.profile,
    this.sessionToken,
    this.errorCode,
  });
  
  // Factory constructors
  factory LoginResult.success({Profile? profile, String? sessionToken, String message = 'Login successful'}) {
    return LoginResult(
      success: true,
      message: message,
      profile: profile,
      sessionToken: sessionToken,
    );
  }

  factory LoginResult.error({String message = 'Login failed', String? errorCode}) {
    return LoginResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

class SyncResult {
  final bool success;
  final String? message;
  final int syncedEntities;
  final List<String>? errors;

  SyncResult({
    required this.success,
    this.message,
    this.syncedEntities = 0,
    this.errors,
  });
  
  // Factory constructors instead of static methods
  factory SyncResult.success({int syncedEntities = 0, String? message}) {
    return SyncResult(
      success: true,
      syncedEntities: syncedEntities,
      message: message ?? 'Sync completed successfully',
    );
  }

  factory SyncResult.error({String? message, List<String>? errors}) {
    return SyncResult(
      success: false,
      message: message ?? 'Sync failed',
      errors: errors,
    );
  }
}

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient;
  final _secureStorage = const FlutterSecureStorage();
  final _logger = AppLogger('AuthService');
  final _uuid = Uuid();
  
  Box<Profile>? _profileBox;
  Profile? _currentProfile;
  BiometricAuthService? _biometricService;

  AuthService(this._apiClient) {
    initialize();
  }
  
  // Getters
  Profile? get profile => _currentProfile;
  BiometricAuthService? get biometricService => _biometricService;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      _biometricService = BiometricAuthService();
      await _biometricService?.initialize();
      
      if (!Hive.isBoxOpen('profiles')) {
        _profileBox = await Hive.openBox<Profile>('profiles');
      } else {
        _profileBox = Hive.box<Profile>('profiles');
      }
      
      // Restore last used profile
      await _restoreLastProfile();
      
      _logger.info('AuthService initialized');
    } catch (e) {
      _logger.error('Failed to initialize AuthService: $e');
    }
  }
  
  // Restore the last used profile
  Future<void> _restoreLastProfile() async {
    try {
      final profileId = await _secureStorage.read(key: 'current_profile_id');
      if (profileId != null && _profileBox != null) {
        _currentProfile = _profileBox!.get(profileId);
        if (_currentProfile != null) {
          _logger.info('Restored profile: ${_currentProfile!.name}');
        }
      }
    } catch (e) {
      _logger.error('Failed to restore last profile: $e');
    }
  }
  
  // Login with email and password
  Future<LoginResult> login({required String email, required String password}) async {
    try {
      // First check if we have a local profile with this email
      if (_profileBox == null) await initialize();
      
      final existingProfiles = _profileBox!.values.cast<Profile>().toList();
      final matchingProfile = existingProfiles.firstWhere(
        (profile) => profile.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('No account found with this email'),
      );
      
      // In a real app, you would verify the password with the server
      // Here we'll simulate a successful login
      final sessionToken = _createSessionToken();
      
      // Update the profile with the session token
      final updatedProfile = matchingProfile.copyWith(
        lastLogin: DateTime.now(),
      );
      
      await _profileBox!.put(updatedProfile.id, updatedProfile);
      await _secureStorage.write(key: 'current_profile_id', value: updatedProfile.id);
      await _secureStorage.write(key: 'session_token', value: sessionToken);
      
      _currentProfile = updatedProfile;
      notifyListeners();
      
      return LoginResult.success(
        profile: updatedProfile,
        sessionToken: sessionToken,
      );
    } catch (e) {
      _logger.error('Login failed: $e');
      return LoginResult.error(message: e.toString());
    }
  }
  
  // Login with biometric
  Future<LoginResult> loginWithBiometric() async {
    try {
      if (_biometricService == null) {
        throw Exception('Biometric service not initialized');
      }
      
      final isAuthenticated = await _biometricService!.authenticateWithBiometric(
        'Authenticate to login',
      );
      
      if (!isAuthenticated) {
        return LoginResult.error(message: 'Biometric authentication failed');
      }
      
      if (_currentProfile == null) {
        final profileId = await _secureStorage.read(key: 'current_profile_id');
        if (profileId == null) {
          return LoginResult.error(message: 'No profile found');
        }
        
        _currentProfile = _profileBox!.get(profileId);
      }
      
      if (_currentProfile == null) {
        return LoginResult.error(message: 'Profile not found');
      }
      
      // Generate new session token
      final sessionToken = _createSessionToken();
      
      // Update the profile with the new session token
      final updatedProfile = _currentProfile!.copyWith(
        lastLogin: DateTime.now(),
      );
      
      await _profileBox!.put(updatedProfile.id, updatedProfile);
      await _secureStorage.write(key: 'session_token', value: sessionToken);
      
      _currentProfile = updatedProfile;
      notifyListeners();
      
      return LoginResult.success(
        profile: updatedProfile,
        sessionToken: sessionToken,
      );
    } catch (e) {
      _logger.error('Biometric login failed: $e');
      return LoginResult.error(message: 'Biometric login failed: ${e.toString()}');
    }
  }
  
  // Signup with email and password
  Future<LoginResult> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (_profileBox == null) await initialize();
      
      // Check if email is already registered
      final existingProfiles = _profileBox!.values.cast<Profile>().toList();
      final emailExists = existingProfiles.any(
        (profile) => profile.email.toLowerCase() == email.toLowerCase()
      );
      
      if (emailExists) {
        return LoginResult.error(message: 'Email already registered');
      }
      
      // Generate unique IDs and tokens
      final deviceId = await _getOrCreateDeviceId();
      final sessionToken = _createSessionToken();
      final userId = _uuid.v4();
      
      // Create new profile
      final newProfile = Profile(
        id: userId,
        email: email.trim(),
        name: name.trim(),
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        pin: '0000', // Default PIN
        phoneNumber: '',
        photoUrl: '',
        authToken: sessionToken,
      );
      
      // Save locally
      await _profileBox!.put(userId, newProfile);
      await _secureStorage.write(key: 'current_profile_id', value: userId);
      await _secureStorage.write(key: 'session_token', value: sessionToken);
      
      // Set as current profile
      _currentProfile = newProfile;
      
      // Try to create account on server if online
      try {
        final isConnected = await _apiClient.checkServerConnection();
        
        if (isConnected) {
          await _apiClient.createAccount(
            email: email,
            name: name,
            deviceId: deviceId,
            sessionToken: sessionToken,
            userId: userId,
          );
        }
      } catch (e) {
        _logger.warn('Could not sync new account to server: $e');
        // Continue anyway as we've created the local account
      }
      
      notifyListeners();
      
      return LoginResult.success(
        profile: newProfile,
        sessionToken: sessionToken,
        message: 'Account created successfully',
      );
    } catch (e) {
      _logger.error('Signup failed: $e');
      return LoginResult.error(message: 'Failed to create account: ${e.toString()}');
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      if (_biometricService != null) {
        await _biometricService.clearBiometricSession();
      }
      
      // Invalidate session on server if possible
      if (_currentProfile != null && _apiClient != null) {
        try {
          await _apiClient.invalidateSession(
            userId: _currentProfile!.id,
            sessionToken: _currentProfile!.authToken ?? '',
          );
        } catch (e) {
          _logger.warn('Failed to invalidate server session: $e');
          // Continue with local logout
        }
      }
      
      // Clear local storage
      _currentProfile = null;
      await _secureStorage.delete(key: 'current_profile_id');
      await _secureStorage.delete(key: 'session_token');
      
      notifyListeners();
      _logger.info('User logged out');
    } catch (e) {
      _logger.error('Logout failed: $e');
    }
  }
  
  // Update profile name
  Future<bool> updateProfileName(String newName) async {
    if (_currentProfile == null) {
      return false;
    }
    
    try {
      final updatedProfile = _currentProfile!.copyWith(name: newName.trim());
      
      await _profileBox?.put(_currentProfile!.id, updatedProfile);
      
      _currentProfile = updatedProfile;
      notifyListeners();
      
      return true;
    } catch (e) {
      _logger.error('Failed to update profile name: $e');
      return false;
    }
  }
  
  // Update profile email
  Future<bool> updateProfileEmail(String newEmail) async {
    if (_currentProfile == null || 
        _currentProfile!.email.toLowerCase() == newEmail.trim().toLowerCase()) {
      return false;
    }
    
    try {
      final updatedProfile = _currentProfile!.copyWith(email: newEmail.trim());
      
      await _profileBox?.put(_currentProfile!.id, updatedProfile);
      
      _currentProfile = updatedProfile;
      notifyListeners();
      
      return true;
    } catch (e) {
      _logger.error('Failed to update profile email: $e');
      return false;
    }
  }
  
  // Helper methods
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
  
  // For profile management extension
  Future<Box<Profile>> getProfileBox() async {
    if (_profileBox == null) await initialize();
    return _profileBox!;
  }
  
  void setCurrentProfile(Profile profile) {
    _currentProfile = profile;
    notifyListeners();
  }
}
