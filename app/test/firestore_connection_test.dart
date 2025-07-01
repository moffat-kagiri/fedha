import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Firestore Connection Test', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    test('Should be able to write test data to Firestore', () async {
      final firestore = FirebaseFirestore.instance;

      // Try to write a simple test document
      final testDoc = {
        'testField': 'testValue',
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'manual_test',
      };

      print('🔥 Attempting to write test document to Firestore...');

      try {
        await firestore.collection('test_connection').add(testDoc);
        print('✅ Successfully wrote test document to Firestore!');
        print(
          '📊 Check your Firebase Console for the "test_connection" collection',
        );

        // Query the document back to verify
        final snapshot =
            await firestore
                .collection('test_connection')
                .where('source', isEqualTo: 'manual_test')
                .get();

        expect(snapshot.docs.isNotEmpty, true);
        print(
          '✅ Successfully read back ${snapshot.docs.length} test document(s)',
        );
      } catch (e) {
        print('❌ Failed to write to Firestore: $e');
        fail('Firestore write failed: $e');
      }
    });

    test('Should create a test profile manually', () async {
      final firestore = FirebaseFirestore.instance;

      final testProfile = {
        'id': 'test_profile_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Manual Test User',
        'profileType': 'PERS',
        'passwordHash': 'hashed_password_here',
        'baseCurrency': 'ZAR',
        'timezone': 'Africa/Johannesburg',
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'firebaseUid': 'test_firebase_uid',
      };

      print('🔥 Creating test profile in Firestore...');

      try {
        await firestore.collection('profiles').add(testProfile);
        print('✅ Successfully created test profile!');
        print('📊 Check your Firebase Console for the "profiles" collection');
      } catch (e) {
        print('❌ Failed to create test profile: $e');
        fail('Profile creation failed: $e');
      }
    });
  });
}
