import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fedha/services/firebase_auth_service.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Account Creation Tests', () {
    setUpAll(() async {
      // Initialize Flutter bindings
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    tearDown(() async {
      // Clean up test users - handle errors gracefully
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      } catch (e) {
        // Ignore cleanup errors in tests
        print('Test cleanup warning: $e');
      }
    });

    test('Should create account with email and password', () async {
      final authService = FirebaseAuthService();

      final result = await authService.registerWithEmailAndPassword(
        name: 'Test User',
        profileType: 'personal',
        password: 'testpass123',
        email: 'test+${DateTime.now().millisecondsSinceEpoch}@example.com',
        baseCurrency: 'ZAR',
        timezone: 'Africa/Johannesburg',
      );

      expect(result['success'], true);
      expect(result['profileId'], isNotNull);
      expect(result['profileType'], 'PERS');

      // Verify profile created in Firestore
      final profileDoc =
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(result['profileId'])
              .get();

      expect(profileDoc.exists, true);
      expect(profileDoc.data()?['name'], 'Test User');
      expect(profileDoc.data()?['baseCurrency'], 'ZAR');
    });

    test('Should create local profile (PIN-based)', () async {
      final authService = FirebaseAuthService();

      final result = await authService.registerLocalProfile(
        name: 'Local Test User',
        profileType: 'business',
        password: '1234',
        baseCurrency: 'ZAR',
        timezone: 'Africa/Johannesburg',
      );

      expect(result['success'], true);
      expect(result['profileId'], isNotNull);
      expect(result['profileType'], 'BIZ');

      // Verify profile created in Firestore
      final profileDoc =
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(result['profileId'])
              .get();

      expect(profileDoc.exists, true);
      expect(profileDoc.data()?['name'], 'Local Test User');
      expect(profileDoc.data()?['profileType'], 'BIZ');
    });

    test('Should login with created account', () async {
      final authService = FirebaseAuthService();

      // First create an account
      final createResult = await authService.registerWithEmailAndPassword(
        name: 'Login Test User',
        profileType: 'personal',
        password: 'logintest123',
        email: 'logintest+${DateTime.now().millisecondsSinceEpoch}@example.com',
      );

      expect(createResult['success'], true);

      // Now try to login
      final loginResult = await authService.loginWithEmailAndPassword(
        email: createResult['email'],
        password: 'logintest123',
      );

      expect(loginResult['success'], true);
      expect(loginResult['profileId'], createResult['profileId']);
    });
  });
}
