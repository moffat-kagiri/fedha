import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/permissions_service.dart';
import 'welcome_onboarding_screen.dart';
import 'login_welcome_screen.dart';
import 'main_navigation.dart';
import 'biometric_lock_screen.dart';
import 'permissions_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _onboardingCompleted = false;
  bool _needsBiometricAuth = false;
  bool _needsPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.initialize();
        
        // Initialize permissions service and check if we need to show permissions prompt
        final permissionsService = PermissionsService.instance;
        final needsPermissions = await permissionsService.shouldShowPermissionsPrompt();
        
        final biometricService = BiometricAuthService.instance;
        final biometricEnabled = await biometricService?.isBiometricEnabled() ?? false;
        final hasValidSession = await biometricService?.hasValidBiometricSession() ?? false;
        
        // Check if user is logged in and biometric is enabled
        bool needsBiometric = false;
        if (authService.isLoggedIn() && biometricEnabled && !hasValidSession) {
          needsBiometric = true;
        }
        
        setState(() {
          _onboardingCompleted = onboardingCompleted;
          _needsBiometricAuth = needsBiometric;
          _needsPermissions = needsPermissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _onboardingCompleted = false;
          _needsBiometricAuth = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF007A39),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Fedha',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
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
    
    // Show permissions screen if needed
    if (_needsPermissions) {
      return PermissionsScreen(
        onPermissionsSet: () {
          setState(() {
            _needsPermissions = false;
          });
        },
      );
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
        if (authService.isLoggedIn()) {
          return const MainNavigation();
        } else {
          return const LoginWelcomeScreen();
        }
      },
    );
  }
}
