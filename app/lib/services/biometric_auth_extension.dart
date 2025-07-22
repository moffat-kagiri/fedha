import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';

/// Extension to add biometric authentication methods to AuthService
extension BiometricAuthExtension on AuthService {
  /// Key for storing encrypted credentials
  static const String _biometricAuthKey = 'biometric_auth_credentials';
  
  /// Get secure storage instance
  FlutterSecureStorage get _secureStorage => const FlutterSecureStorage();
  
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
      if (!await biometricService.canAuthenticate()) {
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
      return await login(email: email, password: password);
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
      if (await BiometricAuthService.instance.canAuthenticate()) {
        // Get biometric authentication
        final isAuthenticated = await BiometricAuthService.instance.authenticate(
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
  
  /// Log in using biometric authentication
  Future<bool> loginWithBiometric() async {
    try {
      if (!await BiometricAuthService.instance.canAuthenticate()) {
        return false;
      }
      
      // Get biometric authentication
      final isAuthenticated = await BiometricAuthService.instance.authenticate(
        localizedReason: 'Login with biometric authentication',
      );
      
      if (isAuthenticated) {
        // Read encrypted credentials
        final credentialsJson = await _secureStorage.read(key: _biometricAuthKey);
        if (credentialsJson == null) {
          return false;
        }
        
        final credentials = jsonDecode(credentialsJson);
        final email = credentials['email'] as String;
        final password = credentials['password'] as String;
        
        // Login with credentials
        final result = await enhancedLogin(email, password);
        return result.success;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error during biometric login: $e');
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
