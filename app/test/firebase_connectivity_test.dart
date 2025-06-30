import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Firebase Connectivity Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    test('Firebase should be initialized', () async {
      expect(Firebase.apps.length, greaterThan(0));
      expect(Firebase.app().name, '[DEFAULT]');
      print('✅ Firebase initialized successfully');
    });

    test('FirebaseAuth should be accessible', () async {
      final auth = FirebaseAuth.instance;
      expect(auth, isNotNull);
      expect(auth.app.name, '[DEFAULT]');
      print('✅ Firebase Auth accessible');
    });

    test('Firestore should be accessible', () async {
      final firestore = FirebaseFirestore.instance;
      expect(firestore, isNotNull);
      expect(firestore.app.name, '[DEFAULT]');
      print('✅ Firestore accessible');
    });

    test('Should be able to query Firestore (read test)', () async {
      final firestore = FirebaseFirestore.instance;

      // Try to read from profiles collection (should work even if empty)
      try {
        final querySnapshot =
            await firestore.collection('profiles').limit(1).get();

        print(
          '✅ Firestore read test successful (${querySnapshot.docs.length} documents found)',
        );
        expect(querySnapshot, isNotNull);
      } catch (e) {
        print('❌ Firestore read error: $e');
        rethrow;
      }
    });

    test('Firebase project configuration', () async {
      final app = Firebase.app();
      expect(app.options.projectId, 'fedha-tracker');
      print('✅ Project ID: ${app.options.projectId}');
      print('✅ Auth Domain: ${app.options.authDomain}');
      print('✅ API Key configured: ${app.options.apiKey?.isNotEmpty == true}');
    });
  });
}
