// test/integration/onboarding_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fedha/main.dart';
import 'package:fedha/services/auth_service.dart';
import 'package:fedha/models/enhanced_profile.dart';

void main() {
  group('Enhanced Onboarding Flow Tests', () {
    setUpAll(() async {
      await Hive.initFlutter();
      // Clear any existing data
      await Hive.deleteBoxFromDisk('settings');
      await Hive.deleteBoxFromDisk('enhanced_profiles');
    });

    testWidgets('Complete enhanced onboarding flow', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const FedhaApp());
      await tester.pumpAndSettle();

      // Should start with onboarding screen for first-time users
      expect(find.text('Welcome to Fedha'), findsOneWidget);

      // Navigate through onboarding
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Complete onboarding
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should now be on profile type selection screen
      expect(find.text('Select Profile Type'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);

      // Select personal profile
      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();

      // Should now be on enhanced profile creation screen
      expect(find.text('Create Personal Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);

      // Fill out the form
      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'john.doe@example.com',
      );

      // Submit the form
      await tester.tap(find.text('Continue to Password Setup'));
      await tester.pumpAndSettle();

      // Should now be on password setup screen
      expect(find.text('Set Your Secure Password'), findsOneWidget);
      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Enter password
      await tester.enterText(find.byType(TextFormField).at(0), 'TestPass123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'TestPass123!');

      // Set password and continue
      await tester.tap(find.text('Set Password & Continue'));
      await tester.pumpAndSettle();

      // Should now be on main navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Enhanced profile creation with Google Drive backup', (
      WidgetTester tester,
    ) async {
      // Test the enhanced profile creation with Google Drive backup enabled
      // This test would require mocking Google Drive service
    });

    testWidgets('Password validation works correctly', (
      WidgetTester tester,
    ) async {
      // Test password validation scenarios
      // This test would check weak password detection and validation
    });
  });
  group('Enhanced Auth Service Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('createEnhancedProfile creates profile correctly', () async {
      final profileData = {
        'profile_type': ProfileType.personal,
        'name': 'Test User',
        'email': 'test@example.com',
        'base_currency': 'USD',
        'timezone': 'GMT+0',
        'password': 'TestPass123!',
        'enable_google_drive': false,
      };

      final result = await authService.createEnhancedProfile(profileData);
      expect(result, isTrue);
      expect(authService.currentProfile, isNotNull);
      expect(authService.currentProfile!.name, equals('Test User'));
    });

    test('setInitialPassword works for new profiles', () async {
      // Create a profile first
      final profileData = {
        'profile_type': ProfileType.business,
        'name': 'Business User',
        'email': 'business@example.com',
        'password': 'TempPass0000', // Temporary password
      };

      await authService.createEnhancedProfile(profileData);

      // Set initial password (simulate password change)
      final result = await authService.setInitialPassword(
        'NewBusinessPass9876',
      );
      expect(result, isTrue);

      // Verify password was set correctly
      expect(
        authService.currentProfile!.verifyPassword('NewBusinessPass9876'),
        isTrue,
      );
    });
  });
}
