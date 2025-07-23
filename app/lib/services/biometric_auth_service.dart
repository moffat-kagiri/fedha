import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  final _logger = AppLogger('BiometricAuthService');
  
  // Constants for storage keys
  final _biometricEnabledKey = 'biometric_enabled';
  final _lastAuthTimeKey = 'last_biometric_auth_time';
  final _sessionTokenKey = 'biometric_session_token';
  final _biometricAuthKey = 'biometric_auth_key';
  
  // Session duration (in hours)
  final _sessionDurationHours = 24;

  Future<void> initialize() async {
    _logger.info('Initializing BiometricAuthService');
    // No initialization needed currently
  }

  Future<bool> canAuthenticate() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || 
          await _localAuth.isDeviceSupported();
      
      _logger.info('Can authenticate with biometrics: $canAuthenticate');
      return canAuthenticate;
    } catch (e) {
      _logger.error('Error checking biometric availability: $e');
      return false;
    }
  }
  
  // This is the actual authentication method
  Future<bool> authenticateWithBiometric(String reason) async {
    try {
      if (!await isAvailable()) {
        _logger.warn('Biometric authentication not available');
        return false;
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        await _saveAuthenticationSession();
      }
      
      return authenticated;
    } catch (e) {
      _logger.error('Biometric authentication error: $e');
      return false;
    }
  }
  
  Future<bool> hasValidBiometricSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAuthTime = prefs.getInt(_lastAuthTimeKey);
      final sessionToken = prefs.getString(_sessionTokenKey);
      
      if (lastAuthTime == null || sessionToken == null) {
        return false;
      }
      
      final authTime = DateTime.fromMillisecondsSinceEpoch(lastAuthTime);
      final now = DateTime.now();
      
      final sessionExpiry = authTime.add(Duration(hours: _sessionDurationHours));
      
      return now.isBefore(sessionExpiry);
    } catch (e) {
      _logger.error('Error checking biometric session: $e');
      return false;
    }
  }
  
  Future<bool> isAvailable() async {
    final canAuth = await canAuthenticate();
    if (!canAuth) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }
  
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      _logger.info('Biometric auth set to: $enabled');
    } catch (e) {
      _logger.error('Error setting biometric enabled: $e');
    }
  }
  
  Future<bool> isBiometricEnabled() async {
    try {
      final isAvail = await isAvailable();
      return isAvail;
    } catch (e) {
      _logger.error('Error checking if biometric is enabled: $e');
      return false;
    }
  }
  
  Future<void> _saveAuthenticationSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Generate a session token - in a real app, this would be more secure
      final sessionToken = DateTime.now().toIso8601String();
      
      await prefs.setInt(_lastAuthTimeKey, now);
      await prefs.setString(_sessionTokenKey, sessionToken);
      
      _logger.info('Saved authentication session');
    } catch (e) {
      _logger.error('Error saving authentication session: $e');
    }
  }
  
  Future<void> clearBiometricSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_lastAuthTimeKey);
      await prefs.remove(_sessionTokenKey);
      await _secureStorage.delete(key: _biometricAuthKey);
      
      _logger.info('Cleared biometric session');
    } catch (e) {
      _logger.error('Error clearing biometric session: $e');
    }
  }
}
