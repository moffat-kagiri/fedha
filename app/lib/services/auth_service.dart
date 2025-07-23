// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/profile.dart';
import '../services/api_client.dart';
import '../services/biometric_auth_service.dart';
import '../services/biometric_auth_extension.dart';
import '../utils/app_logger.dart';

// Auth session for persistent login
class AuthSession {
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String sessionToken;
  final String? deviceId;
  
  bool get isValid => DateTime.now().isBefore(expiresAt);
  
  AuthSession({
    required this.userId,
    required this.sessionToken,
    this.deviceId,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 30));
    
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sessionToken': sessionToken,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'deviceId': deviceId,
  };
  
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['userId'],
    sessionToken: json['sessionToken'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    deviceId: json['deviceId'],
  );
}

// Profile existence check result
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
  final Profile? profile;
  final bool isFirstLogin;
  final String? sessionToken;

  LoginResult.success({
    this.profile, 
    this.sessionToken,
    this.isFirstLogin = false,
    String? message,
  }) : success = true,
       message = message ?? 'Login successful';
       
  LoginResult.error({required this.message})
    : success = false, 
      profile = null,
      sessionToken = null,
      isFirstLogin = false;

  static LoginResult empty() => LoginResult.error(message: 'No profile found');
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

// Result class for sync operations
class SyncResult {
  final bool success;
  final String message;
  final int syncedEntities;
  final List<String>? errors;
  
  SyncResult({
    required this.success,
    required this.message,
    required this.syncedEntities,
    this.errors,
  });
  
  factory SyncResult.failed(String message) => SyncResult(
    success: false,
    message: message,
    syncedEntities: 0,
  );
  
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
      syncedEntities: 0,
      errors: errors,
    );
  }
}

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
    initialize();
  }
  
  // Getters
  Profile? get profile => _currentProfile;
  Profile? get currentProfile => _currentProfile;
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
      _logger.severe('Failed to initialize AuthService: $e');
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
      _logger.severe('Failed to restore last profile: $e');
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
        authToken: sessionToken,
        sessionToken: sessionToken,
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
      _logger.severe('Login failed: $e');
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
        authToken: sessionToken,
        sessionToken: sessionToken,
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
      _logger.severe('Biometric login failed: $e');
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
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: name.trim(),
        email: email.trim(),
        pin: '0000', // Default PIN
      ).copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
        phoneNumber: '',
        photoUrl: '',
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
            password: password,
            firstName: name.split(' ').first,
            lastName: name.split(' ').length > 1 ? name.split(' ').last : '',
            deviceId: deviceId,
          );
        }
      } catch (e) {
        _logger.warning('Could not sync new account to server: $e');
        // Continue anyway as we've created the local account
      }
      
      notifyListeners();
      
      return LoginResult.success(
        profile: newProfile,
        sessionToken: sessionToken,
        message: 'Account created successfully',
      );
    } catch (e) {
      _logger.severe('Signup failed: $e');
      return LoginResult.error(message: 'Failed to create account: ${e.toString()}');
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      if (_biometricService != null) {
        await _biometricService!.clearBiometricSession();
      }
      
      // Invalidate session on server if possible
      if (_currentProfile != null) {
        try {
          await _apiClient.invalidateSession(
            userId: _currentProfile!.id,
            sessionToken: _currentProfile!.authToken ?? '',
          );
        } catch (e) {
          _logger.severe('Failed to invalidate server session: $e');
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
      _logger.severe('Logout failed: $e');
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
      _logger.severe('Failed to update profile name: $e');
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
      _logger.severe('Failed to update profile email: $e');
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
  
  // Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentProfile == null) {
      return false;
    }
    
    try {
      // In a real app, you would verify the current password with the server
      // Here we'll simulate a successful password change
      
      // Try to update password on server if online
      final isConnected = await _apiClient.checkServerConnection();
      
      if (isConnected) {
        try {
          // This would typically call the API to update the password
          // Since we don't have actual password validation here, we'll just
          // simulate a successful password change
        } catch (e) {
          _logger.warning('Failed to update password on server: $e');
          return false;
        }
      }
      
      // Return success
      return true;
    } catch (e) {
      _logger.severe('Failed to change password: $e');
      return false;
    }
  }
  
  // Check if the user is currently logged in
  bool isLoggedIn() {
    return _currentProfile != null;
  }
  
  // Enhanced login with additional options
  Future<LoginResult> enhancedLogin({
    required String email,
    required String password,
    bool rememberMe = false,
    bool useBiometric = false,
  }) async {
    try {
      // First try regular login
      final loginResult = await login(email: email, password: password);
      
      if (!loginResult.success) {
        return loginResult;
      }
      
      // If login was successful and user wants to use biometrics, set it up
      if (loginResult.success && useBiometric && _biometricService != null) {
        final biometricAvailable = await _biometricService!.canAuthenticate();
        
        if (biometricAvailable) {
          // Save credentials for biometric auth
          final biometricExtension = BiometricAuthExtension(this);
          await biometricExtension.saveBiometricCredentials(email, password);
        }
      }
      
      // If remember me is set, extend the session duration
      if (rememberMe && loginResult.sessionToken != null) {
        // In a real app, you would extend session on server
        // Here we'll just update local storage with extended expiration
        final extendedSession = AuthSession(
          userId: _currentProfile!.id,
          sessionToken: loginResult.sessionToken!,
          expiresAt: DateTime.now().add(const Duration(days: 90)),
        );
        
        await _secureStorage.write(
          key: 'auth_session',
          value: jsonEncode(extendedSession.toJson()),
        );
      }
      
      return loginResult;
    } catch (e) {
      _logger.severe('Enhanced login failed: $e');
      return LoginResult.error(message: e.toString());
    }
  }
  
  // Create a new profile from profile data
  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    try {
      if (_profileBox == null) await initialize();
      
      // Generate unique ID
      final userId = _uuid.v4();
      final sessionToken = _createSessionToken();
      
      // Extract basic data
      final name = profileData['name'] as String;
      final email = profileData['email'] as String;
      
      // Create profile with default values first
      final newProfile = Profile.defaultProfile(
        id: userId,
        name: name.trim(),
        email: email.trim(),
        pin: profileData['pin'] as String? ?? '0000',
      );
      
      // Apply any additional data from profileData
      final updatedProfile = newProfile.copyWith(
        authToken: sessionToken,
        sessionToken: sessionToken,
        phoneNumber: profileData['phoneNumber'] as String? ?? '',
        photoUrl: profileData['photoUrl'] as String? ?? '',
        baseCurrency: profileData['baseCurrency'] as String? ?? 'USD',
        timezone: profileData['timezone'] as String? ?? 'UTC',
      );
      
      // Save locally
      await _profileBox!.put(userId, updatedProfile);
      await _secureStorage.write(key: 'current_profile_id', value: userId);
      await _secureStorage.write(key: 'session_token', value: sessionToken);
      
      // Set as current profile
      _currentProfile = updatedProfile;
      notifyListeners();
      
      _logger.info('Created new profile: ${updatedProfile.name}');
      return true;
    } catch (e) {
      _logger.severe('Failed to create profile: $e');
      return false;
    }
  }
}
