import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import 'package:fedha/services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/first_login_handler.dart';
import 'welcome_onboarding_screen.dart';
// Removed deprecated login_welcome_screen import
import 'main_navigation.dart';
import 'biometric_lock_screen.dart';
import 'signup_screen.dart';
import 'login_screen.dart' hide Theme;

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _onboardingCompleted = false;
  bool _needsBiometricAuth = false;
  bool _accountCreationAttempted = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      final accountCreationAttempted = prefs.getBool('account_creation_attempted') ?? false;
      
      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.initialize();
        // NOTE: First-login prompts (biometric setup, permissions) are now
        // invoked from the explicit login/signup flows so we don't present
        // setup dialogs prematurely during app startup.
        // Check backend health but do not force logout when offline
        final apiClient = Provider.of<ApiClient>(context, listen: false);
        bool serverHealthy = false;
        try {
          serverHealthy = await apiClient.checkServerHealth();
        } catch (_) {}
        // Retain session even if offline
        
        final biometricService = BiometricAuthService.instance;
        final biometricEnabled = await biometricService?.isBiometricEnabled() ?? false;
        final hasValidSession = await biometricService?.hasValidBiometricSession() ?? false;
        
        // Check if user is logged in and biometric is enabled
        bool needsBiometric = false;
        if (await authService.isLoggedIn() && biometricEnabled && !hasValidSession) {
          needsBiometric = true;
        }
        
        // Set state with all our flags
        setState(() {
          _onboardingCompleted = onboardingCompleted;
          _needsBiometricAuth = needsBiometric;
          _accountCreationAttempted = accountCreationAttempted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _onboardingCompleted = false;
          _needsBiometricAuth = false;
          _isLoading = false;
          _accountCreationAttempted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: FedhaColors.primaryGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'Fedha',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (!_onboardingCompleted) {
      return const WelcomeOnboardingScreen();
    }
    
    // Show biometric lock if needed
    if (_needsBiometricAuth) {
      return BiometricLockScreen(
        onAuthSuccess: () {
          setState(() {
            _needsBiometricAuth = false;
          });
        },
        onSkip: () {
          // Optional: allow skip in development
          setState(() {
            _needsBiometricAuth = false;
          });
        },
      );
    }

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Use FutureBuilder to handle async isLoggedIn check
        return FutureBuilder<bool>(
          future: authService.isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!) {
              return const MainNavigation();
            } else if (!_accountCreationAttempted) {
              // No account attempt yet: prompt signup first
              return const SignupScreen();
            } else {
              // After account creation attempt: present login screen
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
