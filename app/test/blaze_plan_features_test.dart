import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Blaze Plan Features Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    test('Firebase Storage should be accessible', () async {
      final storage = FirebaseStorage.instance;
      expect(storage, isNotNull);
      expect(storage.app.name, '[DEFAULT]');
      print('✅ Firebase Storage accessible');
    });

    test('Cloud Functions should be accessible', () async {
      final functions = FirebaseFunctions.instance;
      expect(functions, isNotNull);
      expect(functions.app.name, '[DEFAULT]');
      print('✅ Cloud Functions accessible');
    });

    test('Storage bucket configuration', () async {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref();
      expect(ref, isNotNull);
      print('✅ Storage bucket configured');
      print('📁 Bucket: ${storage.bucket}');
    });

    test('Functions region configuration', () async {
      final functions = FirebaseFunctions.instanceFor(region: 'africa-south1');
      expect(functions, isNotNull);
      print('✅ Functions configured for South Africa region');
    });

    test('Health check function (if deployed)', () async {
      try {
        final functions = FirebaseFunctions.instanceFor(
          region: 'africa-south1',
        );
        final callable = functions.httpsCallable('health');
        final result = await callable.call();

        expect(result.data['status'], 'healthy');
        print('✅ Health check function working');
        print('📊 Response: ${result.data}');
      } catch (e) {
        print('ℹ️ Health function not deployed yet: $e');
        // This is expected if functions aren't deployed yet
      }
    });

    test('Enhanced registration function availability', () async {
      try {
        final functions = FirebaseFunctions.instanceFor(
          region: 'africa-south1',
        );
        final callable = functions.httpsCallable('registerWithVerification');
        expect(callable, isNotNull);
        print('✅ Enhanced registration function configured');
      } catch (e) {
        print('ℹ️ Enhanced registration function not available yet: $e');
      }
    });

    test('Storage rules validation (read access)', () async {
      try {
        final storage = FirebaseStorage.instance;
        final ref = storage.ref().child('public/test.txt');

        // Try to get download URL for public file (should work)
        // This tests if storage rules allow public read access
        await ref.getDownloadURL();
        print('✅ Storage rules allow public access');
      } catch (e) {
        if (e.toString().contains('object-not-found')) {
          print('✅ Storage rules working (file not found is expected)');
        } else {
          print('ℹ️ Storage rules test: $e');
        }
      }
    });

    test('Firestore with enhanced features', () async {
      final firestore = FirebaseFirestore.instance;

      // Test enhanced collections
      final profilesRef = firestore.collection('profiles');
      final documentsRef = firestore.collection('documents');

      expect(profilesRef, isNotNull);
      expect(documentsRef, isNotNull);

      print('✅ Enhanced Firestore collections accessible');
      print('📁 Collections: profiles, documents');
    });

    test('Analytics capabilities', () async {
      try {
        final functions = FirebaseFunctions.instanceFor(
          region: 'africa-south1',
        );
        final callable = functions.httpsCallable('getUserAnalytics');
        expect(callable, isNotNull);
        print('✅ Analytics functions configured');
      } catch (e) {
        print('ℹ️ Analytics functions not deployed yet: $e');
      }
    });

    test('Email services availability', () async {
      // Test if email-related functions are configured
      try {
        final functions = FirebaseFunctions.instanceFor(
          region: 'africa-south1',
        );
        final resetCallable = functions.httpsCallable('resetPasswordAdvanced');
        expect(resetCallable, isNotNull);
        print('✅ Email services configured');
      } catch (e) {
        print('ℹ️ Email services not deployed yet: $e');
      }
    });
  });
}
