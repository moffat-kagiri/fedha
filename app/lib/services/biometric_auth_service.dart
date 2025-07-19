// Simple stub implementation for biometric authentication
class BiometricAuthService {
  static BiometricAuthService? _instance;
  static BiometricAuthService get instance => _instance ??= BiometricAuthService._();
  
  BiometricAuthService._();

  Future<bool> isAvailable() async {
    // Placeholder - would use local_auth package in real implementation
    return false;
  }

  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    // Placeholder - would implement actual biometric authentication
    return false;
  }

  Future<List<String>> getAvailableBiometrics() async {
    // Placeholder - would return available biometric types
    return [];
  }

  Future<bool> canCheckBiometrics() async {
    // Placeholder - would check if device supports biometrics
    return false;
  }

  Future<bool> hasValidBiometricSession() async {
    // Placeholder
    return false;
  }

  Future<bool> authenticateWithBiometric(String reason) async {
    // Placeholder
    return false;
  }

  Future<bool> isBiometricEnabled() async {
    // Placeholder
    return false;
  }

  Future<bool> shouldPromptBiometricSetup() async {
    // Placeholder
    return false;
  }

  Future<void> clearBiometricSession() async {
    // Placeholder
  }

  Future<bool> isDeviceSupported() async {
    // Placeholder
    return false;
  }

  Future<bool> isFingerPrintAvailable() async {
    // Placeholder
    return false;
  }
}
