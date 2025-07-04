import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Firebase Auth-Firestore Connection Test', () {
    setUpAll(() async {
      // Initialize Flutter test binding
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase for testing
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    test('Test Firebase Auth and Firestore connectivity', () async {
      // Test Firebase Auth connection
      final auth = FirebaseAuth.instance;
      expect(auth, isNotNull);
      print('✅ Firebase Auth instance created successfully');

      // Test Firestore connection
      final firestore = FirebaseFirestore.instance;
      expect(firestore, isNotNull);
      print('✅ Firestore instance created successfully');

      // Test Firestore settings
      final settings = firestore.settings;
      print('📊 Firestore Settings:');
      print('   Host: ${settings.host}');
      print('   SSL Enabled: ${settings.sslEnabled}');
      print('   Persistence Enabled: ${settings.persistenceEnabled}');

      // Test Auth state
      final currentUser = auth.currentUser;
      print('👤 Current Auth State:');
      print('   User: ${currentUser?.uid ?? "No user logged in"}');
      print('   Email Verified: ${currentUser?.emailVerified ?? false}');

      // Test basic Firestore read operation (should show permission error if rules are blocking)
      try {
        await firestore.collection('profiles').limit(1).get();
        print('✅ Firestore read test successful');
      } catch (e) {
        print('❌ Firestore read test failed: $e');
        print('💡 This indicates a Firestore rules or permissions issue');
      }

      // Check if we can access Firestore settings page
      try {
        final doc = firestore.doc('test/connectivity');
        print('✅ Firestore document reference created: ${doc.path}');
      } catch (e) {
        print('❌ Firestore document reference failed: $e');
      }
    });

    test('Test authentication flow with Firestore', () async {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      print('🔐 Testing Authentication-Firestore Integration...');

      // Check if we have an authenticated user
      final user = auth.currentUser;
      if (user != null) {
        print('👤 Current user found: ${user.uid}');

        // Test if we can query profiles for this user
        try {
          final query =
              await firestore
                  .collection('profiles')
                  .where('firebaseUid', isEqualTo: user.uid)
                  .limit(1)
                  .get();

          print(
            '✅ User profile query successful. Found ${query.docs.length} profiles',
          );
        } catch (e) {
          print('❌ User profile query failed: $e');
          print('💡 This indicates auth-firestore integration issues');
        }
      } else {
        print('👤 No authenticated user found');
        print('💡 Need to test with authentication first');
      }
    });
  });
}
