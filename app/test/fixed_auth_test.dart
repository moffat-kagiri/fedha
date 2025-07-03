import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fedha/services/enhanced_firebase_auth_service.dart';
import 'package:fedha/firebase_options.dart';

void main() {
  group('Fixed Account Creation and Password Reset Tests', () {
    late EnhancedFirebaseAuthService authService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      authService = EnhancedFirebaseAuthService();
    });

    test(
      'Fixed: Account creation should work with updated Firestore rules',
      () async {
        final email =
            'fixed+${DateTime.now().millisecondsSinceEpoch}@example.com';

        print('🔧 Testing account creation with fixed Firestore rules...');
        print('📧 Email: $email');

        try {
          // Test account creation with auto-login disabled to focus on profile creation
          final result = await authService.registerWithEmailVerification(
            name: 'Fixed Test User',
            email: email,
            password: 'fixed123',
            profileType: 'personal',
            baseCurrency: 'ZAR',
            autoLogin: false,
          );

          print('📊 Registration result: $result');

          expect(
            result['success'],
            true,
            reason:
                'Account creation should succeed with fixed Firestore rules',
          );
          expect(
            result['profileId'],
            isNotNull,
            reason: 'Profile ID should be generated',
          );
          expect(
            result['firebaseUid'],
            isNotNull,
            reason: 'Firebase UID should be created',
          );

          // Verify profile exists in Firestore
          final profileId = result['profileId'];
          if (profileId != null) {
            final profileData = await authService.getProfileById(profileId);
            expect(
              profileData,
              isNotNull,
              reason: 'Profile should exist in Firestore',
            );
            expect(profileData!['email'], equals(email));
            expect(profileData['firebaseUid'], equals(result['firebaseUid']));

            print('✅ Profile successfully created and verified!');
          }
        } catch (e) {
          print('❌ Account creation still failing: $e');
          fail('Account creation failed: $e');
        }
      },
    );

    test('Fixed: Auto-login after registration', () async {
      final email =
          'autologin+${DateTime.now().millisecondsSinceEpoch}@example.com';

      print('🔧 Testing auto-login after registration...');
      print('📧 Email: $email');

      try {
        // Test account creation with auto-login enabled
        final result = await authService.registerWithEmailVerification(
          name: 'Auto Login Test User',
          email: email,
          password: 'autologin123',
          profileType: 'business',
          baseCurrency: 'ZAR',
          autoLogin: true,
        );

        print('📊 Registration with auto-login result: $result');

        expect(result['success'], true);
        expect(
          result['loggedIn'],
          true,
          reason: 'User should be automatically logged in',
        );
        expect(
          result['user'],
          isNotNull,
          reason: 'Firebase user should be available',
        );

        // Verify current user is signed in
        final currentUser = authService.currentUser;
        expect(
          currentUser,
          isNotNull,
          reason: 'Current user should be signed in',
        );
        expect(currentUser!.email, equals(email));

        print('✅ Auto-login after registration working!');

        // Clean up - sign out
        await authService.signOut();
        expect(
          authService.currentUser,
          isNull,
          reason: 'User should be signed out',
        );
      } catch (e) {
        print('❌ Auto-login still failing: $e');
        fail('Auto-login failed: $e');
      }
    });

    test('Fixed: Password reset functionality', () async {
      final email =
          'passwordreset+${DateTime.now().millisecondsSinceEpoch}@example.com';

      print('🔧 Testing password reset functionality...');
      print('📧 Email: $email');

      try {
        // First create an account to test password reset on
        final registerResult = await authService.registerWithEmailVerification(
          name: 'Password Reset Test User',
          email: email,
          password: 'original123',
          profileType: 'personal',
          baseCurrency: 'ZAR',
          autoLogin: false,
        );

        expect(
          registerResult['success'],
          true,
          reason: 'Account should be created for password reset test',
        );

        // Now test password reset
        final resetResult = await authService.resetPassword(email: email);

        print('📊 Password reset result: $resetResult');

        expect(
          resetResult['success'],
          true,
          reason: 'Password reset should succeed for existing user',
        );
        expect(
          resetResult['message'],
          contains('noreply@fedha-tracker.firebaseapp.com'),
          reason: 'Message should mention correct email sender',
        );

        print('✅ Password reset working correctly!');
      } catch (e) {
        print('❌ Password reset still failing: $e');
        fail('Password reset failed: $e');
      }
    });

    test('Fixed: Login with existing account', () async {
      final email =
          'login+${DateTime.now().millisecondsSinceEpoch}@example.com';
      final password = 'login123';

      print('🔧 Testing login with existing account...');
      print('📧 Email: $email');

      try {
        // First create an account
        final registerResult = await authService.registerWithEmailVerification(
          name: 'Login Test User',
          email: email,
          password: password,
          profileType: 'personal',
          baseCurrency: 'ZAR',
          autoLogin: false,
        );

        expect(registerResult['success'], true);

        // Sign out if logged in
        await authService.signOut();

        // Now test login
        final loginResult = await authService.loginWithEmailAndPassword(
          email: email,
          password: password,
        );

        print('📊 Login result: $loginResult');

        expect(
          loginResult['success'],
          true,
          reason: 'Login should succeed with correct credentials',
        );
        expect(
          loginResult['user'],
          isNotNull,
          reason: 'Firebase user should be available',
        );
        expect(
          loginResult['profileId'],
          isNotNull,
          reason: 'Profile should be linked to Firebase user',
        );

        print('✅ Login working correctly!');

        // Clean up
        await authService.signOut();
      } catch (e) {
        print('❌ Login still failing: $e');
        fail('Login failed: $e');
      }
    });
  });
}
