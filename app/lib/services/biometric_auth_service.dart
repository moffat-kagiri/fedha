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
  
  // Session timeout configuration
  Duration sessionTimeout = const Duration(minutes: 15); // tweakable
  int _lastSuccessfulAuthMs = 0;

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
        await registerSuccessfulBiometricSession();
      }

      return authenticated;
    } catch (e) {
      _logger.warning('Biometric authentication error: $e');
      return false;
    }
  }

  /// Call this after a successful biometric auth
  Future<void> registerSuccessfulBiometricSession() async {
    _lastSuccessfulAuthMs = DateTime.now().millisecondsSinceEpoch;
    
    // Also persist to shared preferences for persistence across app restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastAuthTimeKey, _lastSuccessfulAuthMs);
      _logger.info('Biometric session registered and saved');
    } catch (e) {
      _logger.severe('Error saving biometric session: $e');
    }
  }

  /// Check if current session is valid (user authenticated within timeout)
  Future<bool> hasValidBiometricSession() async {
    // First check in-memory session (faster)
    if (_lastSuccessfulAuthMs > 0) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - _lastSuccessfulAuthMs;
      if (elapsed < sessionTimeout.inMilliseconds) {
        return true;
      }
    }

    // If no valid in-memory session, check persisted storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAuth = prefs.getInt(_lastAuthTimeKey);
      
      if (lastAuth == null) {
        return false;
      }

      // Update in-memory value
      _lastSuccessfulAuthMs = lastAuth;
      
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastAuth;
      return elapsed < sessionTimeout.inMilliseconds;
    } catch (e) {
      _logger.warning('Error checking session: $e');
      return false;
    }
  }

  Future<void> invalidateBiometricSession() async {
    _lastSuccessfulAuthMs = 0;
    
    // Also remove persisted value
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastAuthTimeKey);
      _logger.info('Biometric session invalidated');
    } catch (e) {
      _logger.severe('Error invalidating biometric session: $e');
    }
  }

  /// Optional: call when user re-authenticates via password to set the session
  Future<void> registerSuccessfulPasswordLogin() async {
    await registerSuccessfulBiometricSession();
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

  /// Compatibility wrapper: allow callers to set session without calling
  /// the private method directly.
  Future<void> setBiometricSession() async {
    await registerSuccessfulBiometricSession();
  }

  /// Clear all biometric data
  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
      await prefs.remove(_lastAuthTimeKey);
      _lastSuccessfulAuthMs = 0;
      _logger.info('Biometric disabled and session cleared');
    } catch (e) {
      _logger.severe('Error disabling biometric: $e');
    }
  }

  /// Compatibility wrapper matching older `clearBiometricSession()` name
  Future<void> clearBiometricSession() async {
    await invalidateBiometricSession();
  }

  /// Initialize service (called once on app start)
  Future<void> initialize() async {
    // Try to restore session from persistent storage on startup
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAuth = prefs.getInt(_lastAuthTimeKey);
      if (lastAuth != null) {
        _lastSuccessfulAuthMs = lastAuth;
      }
    } catch (e) {
      _logger.warning('Error initializing biometric session: $e');
    }
    
    _logger.info('BiometricAuthService initialized');
  }
}