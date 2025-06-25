import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fedha/services/biometric_auth_service.dart';
import 'package:fedha/services/auth_service.dart';

/// Debug script to check biometric authentication flow
void main() async {
  await Hive.initFlutter();

  print('🔍 BIOMETRIC AUTHENTICATION DEBUG');
  print('===================================');

  try {
    // Initialize services
    final biometricService = BiometricAuthService.instance;
    final authService = AuthService();
    await authService.initialize();

    print('\n📱 Device Capabilities:');
    print(
      '  - Device supported: ${await biometricService.isDeviceSupported()}',
    );
    print(
      '  - Fingerprint available: ${await biometricService.isFingerPrintAvailable()}',
    );
    print(
      '  - Available types: ${await biometricService.getAvailableBiometricTypes()}',
    );

    print('\n⚙️ Biometric Settings:');
    print(
      '  - Biometric enabled: ${await biometricService.isBiometricEnabled()}',
    );
    print(
      '  - Has valid session: ${await biometricService.hasValidBiometricSession()}',
    );
    print(
      '  - Should prompt setup: ${await biometricService.shouldPromptBiometricSetup()}',
    );

    print('\n🔐 Authentication State:');
    print('  - User logged in: ${authService.isLoggedIn}');
    print(
      '  - Current profile: ${authService.currentProfile?.email ?? 'None'}',
    );

    // Check SharedPreferences values
    final prefs = await SharedPreferences.getInstance();
    print('\n💾 SharedPreferences:');
    print('  - biometric_enabled: ${prefs.getBool('biometric_enabled')}');
    print(
      '  - biometric_session_token: ${prefs.getString('biometric_session_token') != null ? 'Present' : 'Absent'}',
    );
    print('  - last_biometric_login: ${prefs.getInt('last_biometric_login')}');
    print(
      '  - biometric_setup_prompted: ${prefs.getBool('biometric_setup_prompted')}',
    );

    // Check Hive settings
    if (Hive.isBoxOpen('settings')) {
      final settingsBox = Hive.box('settings');
      print('\n📦 Hive Settings:');
      print('  - current_profile_id: ${settingsBox.get('current_profile_id')}');
      print('  - auto_login_enabled: ${settingsBox.get('auto_login_enabled')}');
    }

    print('\n✅ Debug complete - check above values for issues');
  } catch (e) {
    print('❌ Error during debug: $e');
  }
}
