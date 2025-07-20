import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:local_auth/local_auth.dart'; // Uncomment when adding local_auth dependency

// Enhanced biometric authentication service with persistent login
class BiometricAuthService {
  static BiometricAuthService? _instance;
  static BiometricAuthService get instance => _instance ??= BiometricAuthService._();
  
  BiometricAuthService._();

  // final LocalAuthentication _localAuth = LocalAuthentication(); // Uncomment when adding dependency
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const String _sessionTokenKey = 'session_token';
  static const int _sessionDurationHours = 24; // 24 hour session

  Future<bool> isAvailable() async {
    try {
      // For development: return true to test biometric setup
      // In production, this would check actual device capabilities
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      // For development: simulate successful authentication
      // In production: would use actual biometric authentication
      await Future.delayed(const Duration(seconds: 1)); // Simulate auth delay
      final result = true; // Simulate success
      
      if (result) {
        await _saveSuccessfulAuth();
      }
      
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAvailableBiometrics() async {
    try {
      // return await _localAuth.getAvailableBiometrics().then((list) => 
      //   list.map((e) => e.toString()).toList());
      return ['fingerprint']; // Stub
    } catch (e) {
      return [];
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      // return await _localAuth.canCheckBiometrics;
      return true; // Stub
    } catch (e) {
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
      return false;
    }
  }

  Future<bool> authenticateWithBiometric(String reason) async {
    // Check if we have a valid session first
    if (await hasValidBiometricSession()) {
      return true;
    }
    
    // Otherwise, require new authentication
    return await authenticate(reason: reason);
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> shouldPromptBiometricSetup() async {
    final isAvailable = await this.isAvailable();
    final isEnabled = await isBiometricEnabled();
    return isAvailable && !isEnabled;
  }

  Future<void> _saveSuccessfulAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionToken = _generateSessionToken();
      
      await prefs.setInt(_lastAuthTimeKey, now);
      await prefs.setString(_sessionTokenKey, sessionToken);
    } catch (e) {
      // Handle error
    }
  }

  String _generateSessionToken() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'session_${now}_${(now * 31) % 1000000}';
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastAuthTimeKey);
      await prefs.remove(_sessionTokenKey);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> clearBiometricSession() async {
    await clearSession();
  }

  Future<void> logout() async {
    await clearSession();
  }

  Future<bool> isDeviceSupported() async {
    return await isAvailable();
  }

  Future<bool> isFingerPrintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains('fingerprint');
  }
}
