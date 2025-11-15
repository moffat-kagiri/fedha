import 'package:shared_preferences/shared_preferences.dart';
import 'biometric_auth_service.dart';

/// Compatibility extension that exposes the older method names used by
/// some UI code so the app compiles without changing callers.
extension BiometricAuthCompat on BiometricAuthService {
  /// Older name used in UI code.
  Future<bool> isAvailable() => canAuthenticate();

  /// Map the older `authenticate(localizedReason: ...)` call to the
  /// current implementation.
  Future<bool> authenticate({required String localizedReason}) =>
      authenticateWithBiometric(localizedReason);

  /// Save a biometric session timestamp (used after a successful login).
  Future<void> setBiometricSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('last_biometric_auth', now);
    } catch (_) {
      // Best-effort; don't crash the app if prefs fail.
    }
  }

  /// Clear the biometric session and disable biometric flag.
  Future<void> clearBiometricSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_biometric_auth');
      await setBiometricEnabled(false);
    } catch (_) {
      // ignore
    }
  }
}
