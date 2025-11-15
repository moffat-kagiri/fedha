import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Streamlined biometric authentication service
class BiometricAuthService {
  static BiometricAuthService? _instance;
  
  static BiometricAuthService? get instance {
    _instance ??= BiometricAuthService._();
    return _instance;
  }

  BiometricAuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final _logger = AppLogger.getLogger('BiometricAuthService');
  
  // Simple storage keys
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _lastAuthTimeKey = 'last_biometric_auth';
  static const _sessionDurationMinutes = 15;

  /// Check if device supports biometric authentication
  Future<bool> canAuthenticate() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || 
          await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      _logger.warning('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types on device
  Future<List<String>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.map((b) => b.toString().split('.').last).toList();
    } catch (e) {
      _logger.warning('Error getting biometric types: $e');
      return [];
    }
  }

  /// Authenticate user with biometric
  Future<bool> authenticateWithBiometric(String reason) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        await _saveAuthenticationSession();
      }

      return authenticated;
    } catch (e) {
      _logger.warning('Biometric authentication error: $e');
      return false;
    }
  }

  /// Compatibility wrapper: older callers used `isAvailable()`
  Future<bool> isAvailable() => canAuthenticate();

  /// Compatibility wrapper to match older `authenticate(localizedReason: ..)`
  Future<bool> authenticate({required String localizedReason}) async {
    return authenticateWithBiometric(localizedReason);
  }

  /// Enable biometric for this device
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      _logger.info('Biometric enabled: $enabled');
    } catch (e) {
      _logger.severe('Error setting biometric enabled: $e');
    }
  }

  /// Check if biometric is enabled for this profile
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      _logger.warning('Error checking biometric enabled: $e');
      return false;
    }
  }

  /// Check if current session is valid (user authenticated within timeout)
  Future<bool> hasValidBiometricSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAuth = prefs.getInt(_lastAuthTimeKey);
      
      if (lastAuth == null) {
        return false;
      }

      final lastAuthTime = DateTime.fromMillisecondsSinceEpoch(lastAuth);
      final now = DateTime.now();
      final sessionExpiry = lastAuthTime.add(
        Duration(minutes: _sessionDurationMinutes),
      );

      return now.isBefore(sessionExpiry);
    } catch (e) {
      _logger.warning('Error checking session: $e');
      return false;
    }
  }

  /// Save authentication session timestamp
  Future<void> _saveAuthenticationSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastAuthTimeKey, now);
      _logger.info('Session saved');
    } catch (e) {
      _logger.severe('Error saving session: $e');
    }
  }

  /// Compatibility wrapper: allow callers to set session without calling
  /// the private `_saveAuthenticationSession` directly.
  Future<void> setBiometricSession() async {
    await _saveAuthenticationSession();
  }

  /// Clear all biometric data
  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
      await prefs.remove(_lastAuthTimeKey);
      _logger.info('Biometric disabled');
    } catch (e) {
      _logger.severe('Error disabling biometric: $e');
    }
  }

  /// Compatibility wrapper matching older `clearBiometricSession()` name
  Future<void> clearBiometricSession() async {
    await disableBiometric();
  }

  /// Initialize service (called once on app start)
  Future<void> initialize() async {
    _logger.info('BiometricAuthService initialized');
  }
}
