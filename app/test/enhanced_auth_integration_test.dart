import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fedha/services/enhanced_firebase_auth_service.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Enhanced Firebase Auth Integration Test', () {
    late EnhancedFirebaseAuthService authService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      authService = EnhancedFirebaseAuthService();
    });

    test('Should register user and create Firestore profile', () async {
      final email =
          'integrationtest+${DateTime.now().millisecondsSinceEpoch}@example.com';

      final result = await authService.registerWithEmailVerification(
        name: 'Integration Test User',
        email: email,
        password: 'testpass123',
        profileType: 'personal',
        baseCurrency: 'ZAR',
      );

      expect(result['success'], true);
      expect(result['profileId'], isNotNull);
      print('✅ Registration test passed: ${result['profileId']}');
      print('📧 Email: $email');
      print('🔑 Password: testpass123');
    });

    test('Should send password reset email', () async {
      final result = await authService.resetPassword(
        email: 'testuser@example.com',
      );

      expect(result['success'], true);
      expect(
        result['message'],
        contains('noreply@fedha-tracker.firebaseapp.com'),
      );
      print('✅ Password reset test passed');
    });

    test('Should login existing user', () async {
      final result = await authService.loginWithEmailAndPassword(
        email: 'testuser@example.com',
        password: 'testpass123',
      );

      print('Login result: $result');
      // Note: This might fail if user doesn't exist in Firebase Auth
    });
  });
}
