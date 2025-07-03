import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fedha/services/enhanced_firebase_auth_service.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Debug Account Creation Issues', () {
    late EnhancedFirebaseAuthService authService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      authService = EnhancedFirebaseAuthService();
    });

    test('Debug: Test direct profile creation', () async {
      final email =
          'debug+${DateTime.now().millisecondsSinceEpoch}@example.com';

      print('🔍 Testing direct profile creation...');
      print('📧 Email: $email');

      try {
        // Test the _registerDirectly method by using registerWithEmailVerification
        // which will fallback to direct registration if functions fail
        final result = await authService.registerWithEmailVerification(
          name: 'Debug Test User',
          email: email,
          password: 'debug123',
          profileType: 'personal',
          baseCurrency: 'ZAR',
          autoLogin: false, // Disable auto-login to focus on profile creation
        );

        print('📊 Registration result: $result');

        if (result['success'] == true) {
          print('✅ Profile created successfully!');
          print('📋 Profile ID: ${result['profileId']}');
          print('👤 Firebase UID: ${result['firebaseUid']}');

          // Verify the profile exists in Firestore
          final profileId = result['profileId'];
          if (profileId != null) {
            print('🔍 Verifying profile exists in Firestore...');
            final profileData = await authService.getProfileById(profileId);

            if (profileData != null) {
              print('✅ Profile verification successful!');
              print('📄 Profile data: $profileData');

              expect(profileData['email'], equals(email));
              expect(profileData['name'], equals('Debug Test User'));
              expect(profileData['profileType'], equals('PERS'));
            } else {
              print(
                '❌ Profile verification failed - profile not found in Firestore',
              );
              fail('Profile not found in Firestore after creation');
            }
          }

          // Also verify by Firebase UID if available
          final firebaseUid = result['firebaseUid'];
          if (firebaseUid != null) {
            print('🔍 Verifying profile by Firebase UID...');
            final profileByUid = await authService.getProfileByFirebaseUid(
              firebaseUid,
            );

            if (profileByUid != null) {
              print('✅ Profile found by Firebase UID!');
              print('📄 Profile by UID: $profileByUid');
            } else {
              print('❌ Profile not found by Firebase UID');
            }
          }
        } else {
          print('❌ Profile creation failed: ${result['error']}');
          fail('Profile creation failed: ${result['error']}');
        }
      } catch (e) {
        print('❌ Exception during profile creation: $e');
        fail('Exception during profile creation: $e');
      }
    });

    test('Debug: Test password reset', () async {
      print('🔍 Testing password reset...');

      try {
        final result = await authService.resetPassword(
          email: 'debug@example.com',
        );

        print('📊 Password reset result: $result');

        if (result['success'] == true) {
          print('✅ Password reset email sent successfully!');
          print('📧 Message: ${result['message']}');
        } else {
          print('❌ Password reset failed: ${result['error']}');
        }
      } catch (e) {
        print('❌ Exception during password reset: $e');
      }
    });
  });
}
