// lib/screens/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import 'login_screen.dart';
import 'welcome_onboarding_screen.dart';
import 'dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final authService = context.read<AuthService>();
      final offlineDataService = context.read<OfflineDataService>();

      // Ensure auth service is initialized with dependencies
      if (!authService.isInitialized) {
        await authService.initializeWithDependencies(
          offlineDataService: offlineDataService,
          biometricService: null,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete =
          prefs.getBool('onboarding_completed') ??
          prefs.getBool('onboarding_complete') ??
          false;

      if (mounted) {
        setState(() {
          _showOnboarding = !onboardingComplete;
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show onboarding for first-time users
    if (_showOnboarding) {
      return const WelcomeOnboardingScreen();
    }

    // Use Consumer to listen to auth state changes
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.hasActiveProfile) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
