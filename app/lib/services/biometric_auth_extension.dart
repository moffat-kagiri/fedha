import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../utils/app_logger.dart';

/// Extension to add biometric authentication methods to AuthService
extension BiometricAuthExtension on AuthService {
  static final _logger = AppLogger('BiometricAuthExtension');
  static final _secureStorage = const FlutterSecureStorage();
  static const _biometricAuthKey = 'biometric_auth_key';

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    final biometricService = BiometricAuthService.instance;
    if (biometricService == null) return false;
    return await biometricService.canAuthenticate();
  }

  /// Check if biometric authentication is enabled for the user
  Future<bool> isBiometricEnabled() async {
    final biometricService = BiometricAuthService.instance;
    if (biometricService == null) return false;
    return await biometricService.isBiometricEnabled();
  }

  /// Enable biometric authentication for the user
  Future<bool> enableBiometricAuth() async {
    try {
      final biometricService = BiometricAuthService.instance;
      if (biometricService == null) return false;
      
      // Check if biometrics are available on the device
      final isAvailable = await biometricService.canAuthenticate();
      if (!isAvailable) {
        _logger.warning('Biometric authentication not available on this device');
        return false;
      }

      // Enable biometric authentication
      await biometricService.setBiometricEnabled(true);
      
      _logger.info('Biometric authentication enabled');
      return true;
    } catch (e) {
      _logger.error('Failed to enable biometric authentication: $e');
      return false;
    }
  }

  /// Disable biometric authentication for the user
  Future<bool> disableBiometricAuth() async {
    try {
      final biometricService = BiometricAuthService.instance;
      if (biometricService == null) return false;
      
      await biometricService.setBiometricEnabled(false);
      await biometricService.clearBiometricSession();
      await _secureStorage.delete(key: _biometricAuthKey);
      
      _logger.info('Biometric authentication disabled');
      return true;
    } catch (e) {
      _logger.error('Failed to disable biometric authentication: $e');
      return false;
    }
  }
  
  /// Authenticate user with biometric authentication
  Future<bool> authenticateWithBiometric() async {
    final biometricService = BiometricAuthService.instance;
    if (biometricService == null) return false;
    return await biometricService.authenticateWithBiometric(
      'Authenticate to continue',
    );
  }

  /// Check if biometric credentials exist
  Future<bool> hasBiometricCredentials() async {
    try {
      final credentials = await _secureStorage.read(key: _biometricAuthKey);
      return credentials != null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for biometric credentials: $e');
      }
      return false;
    }
  }
  
  /// Login with biometric authentication
  Future<bool> loginWithBiometric() async {
    try {
      // Check if biometric auth is available
      final biometricService = BiometricAuthService.instance;
      if (biometricService == null || !await biometricService.canAuthenticate()) {
        return false;
      }
      
      // Get stored credentials
      final credentialsString = await _secureStorage.read(key: _biometricAuthKey);
      if (credentialsString == null) {
        return false;
      }
      
      final credentials = jsonDecode(credentialsString) as Map<String, dynamic>;
      final email = credentials['email'] as String;
      final password = credentials['password'] as String;
      
      // Login with email and password
      final result = await login(email: email, password: password);
      return result.success;
    } catch (e) {
      if (kDebugMode) {
        print('Biometric login failed: $e');
      }
      return false;
    }
  }
  
  /// Save credentials for biometric auth
  Future<bool> saveBiometricCredentials(String email, String password) async {
    try {
      final biometricService = BiometricAuthService.instance;
      if (biometricService == null) return false;
      
      if (await biometricService.canAuthenticate()) {
        // Get biometric authentication
        final isAuthenticated = await biometricService.authenticate(
          localizedReason: 'Authenticate to save login credentials',
        );
        
        if (isAuthenticated) {
          // Save encrypted credentials
          final credentials = jsonEncode({
            'email': email,
            'password': password,
          });
          
          await _secureStorage.write(
            key: _biometricAuthKey,
            value: credentials,
          );
          
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving biometric credentials: $e');
      }
      return false;
    }
  }
  
  /// Delete biometric credentials
  Future<bool> deleteBiometricCredentials() async {
    try {
      await _secureStorage.delete(key: _biometricAuthKey);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting biometric credentials: $e');
      }
      return false;
    }
  }
}
