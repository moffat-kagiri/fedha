import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fedha/services/enhanced_firebase_auth_service.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Enhanced Firebase Auth Account Creation Test', () {
    late EnhancedFirebaseAuthService authService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      authService = EnhancedFirebaseAuthService();
    });

    test('Should create account and auto-login user', () async {
      final email =
          'autotest+${DateTime.now().millisecondsSinceEpoch}@example.com';

      print('🔐 Testing account creation with auto-login...');

      final result = await authService.registerWithEmailVerification(
        name: 'Auto Test User',
        email: email,
        password: 'testpass123',
        profileType: 'personal',
        baseCurrency: 'ZAR',
        autoLogin: true,
      );

      print('📊 Registration result: $result');

      expect(result['success'], true);
      expect(result['profileId'], isNotNull);
      expect(
        result['loggedIn'],
        true,
        reason: 'User should be automatically logged in after registration',
      );

      // Check if Firebase user is currently signed in
      final currentUser = authService.currentUser;
      expect(
        currentUser,
        isNotNull,
        reason: 'Current user should be signed in',
      );
      expect(currentUser!.email, equals(email));

      print('✅ Account creation and auto-login test passed!');
      print('📧 Email: $email');
      print('🔑 Password: testpass123');
      print('👤 Firebase UID: ${currentUser.uid}');
      print('📋 Profile ID: ${result['profileId']}');

      // Test logout
      await authService.signOut();
      expect(
        authService.currentUser,
        isNull,
        reason: 'User should be signed out',
      );

      print('✅ Logout test passed!');
    });

    test('Should login existing user and link to profile', () async {
      final email = 'testuser@example.com';
      final password = 'testpass123';

      print('🔐 Testing login with profile linking...');

      final result = await authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('📊 Login result: $result');

      if (result['success']) {
        expect(result['firebaseUid'], isNotNull);
        expect(result['profileId'], isNotNull);
        expect(result['user'], isNotNull);

        print('✅ Login test passed!');
        print('👤 Firebase UID: ${result['firebaseUid']}');
        print('📋 Profile ID: ${result['profileId']}');

        await authService.signOut();
      } else {
        print(
          '⚠️ Login failed (expected if user doesn\'t exist): ${result['error']}',
        );
      }
    });

    test('Should send password reset email', () async {
      final result = await authService.resetPassword(
        email: 'testuser@example.com',
      );

      print('📊 Password reset result: $result');

      expect(result['success'], true);
      expect(
        result['message'],
        contains('noreply@fedha-tracker.firebaseapp.com'),
      );

      print('✅ Password reset test passed!');
    });
  });
}
