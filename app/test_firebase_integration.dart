// Test script to verify Firebase integration
// Run this with: dart run test_firebase_integration.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');

    print('🔍 Testing Firestore connection...');
    final firestore = FirebaseFirestore.instance;

    // Test write
    await firestore.collection('test').add({
      'message': 'Firebase integration test',
      'timestamp': DateTime.now(),
      'platform': 'flutter',
    });
    print('✅ Firestore write test successful!');

    // Test read
    final snapshot = await firestore.collection('test').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      print('✅ Firestore read test successful!');
      print('📄 Sample document: ${snapshot.docs.first.data()}');
    }

    print('🎉 All Firebase tests passed!');
  } catch (e) {
    print('❌ Firebase test failed: $e');

    if (e.toString().contains('DefaultFirebaseOptions')) {
      print(
        '💡 Solution: Update lib/firebase_options.dart with real values from Firebase Console',
      );
    }

    if (e.toString().contains('google-services.json')) {
      print(
        '💡 Solution: Download google-services.json from Firebase Console and place in android/app/',
      );
    }
  }
}
