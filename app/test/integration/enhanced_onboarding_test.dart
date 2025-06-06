// test/integration/enhanced_onboarding_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fedha/main.dart';
import 'package:fedha/services/enhanced_auth_service.dart';
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
      await tester.pumpWidget(const MyApp());
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
      await tester.tap(find.text('Continue to PIN Setup'));
      await tester.pumpAndSettle();

      // Should now be on PIN setup screen
      expect(find.text('Set Your Secure PIN'), findsOneWidget);
      expect(find.text('Create PIN'), findsOneWidget);
      expect(find.text('Confirm PIN'), findsOneWidget);

      // Enter PIN
      await tester.enterText(find.byType(TextFormField).at(0), '5678');
      await tester.enterText(find.byType(TextFormField).at(1), '5678');

      // Set PIN and continue
      await tester.tap(find.text('Set PIN & Continue'));
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

    testWidgets('PIN validation works correctly', (WidgetTester tester) async {
      // Test PIN validation scenarios
      // This test would check weak PIN detection and validation
    });
  });

  group('Enhanced Auth Service Tests', () {
    late EnhancedAuthService authService;

    setUp(() {
      authService = EnhancedAuthService();
    });

    test('createEnhancedProfile creates profile correctly', () async {
      final profileData = {
        'profile_type': ProfileType.personal,
        'name': 'Test User',
        'email': 'test@example.com',
        'base_currency': 'USD',
        'timezone': 'GMT+0',
        'pin': '1234',
        'enable_google_drive': false,
      };

      final result = await authService.createEnhancedProfile(profileData);
      expect(result, isTrue);
      expect(authService.currentProfile, isNotNull);
      expect(authService.currentProfile!.name, equals('Test User'));
    });

    test('setInitialPin works for new profiles', () async {
      // Create a profile first
      final profileData = {
        'profile_type': ProfileType.business,
        'name': 'Business User',
        'email': 'business@example.com',
        'pin': '0000', // Temporary PIN
      };

      await authService.createEnhancedProfile(profileData);

      // Set initial PIN
      final result = await authService.setInitialPin('9876');
      expect(result, isTrue);

      // Verify PIN was set correctly
      expect(authService.currentProfile!.verifyPin('9876'), isTrue);
    });
  });
}
