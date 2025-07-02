// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_profile.dart';
import '../services/auth_service.dart';
import '../services/sms_listener_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/enhanced_firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  final ProfileType profileType;

  const LoginScreen({super.key, required this.profileType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showBiometricOption = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final biometricService = BiometricAuthService.instance;
    final bool isSupported = await biometricService.isDeviceSupported();
    final bool isFingerprintAvailable =
        await biometricService.isFingerPrintAvailable();
    final bool isEnabled = await biometricService.isBiometricEnabled();

    if (kDebugMode) {
      print(
        'LoginScreen: Biometric check - supported: $isSupported, fingerprint: $isFingerprintAvailable, enabled: $isEnabled',
      );
    }

    if (mounted) {
      setState(() {
        // Show biometric option if device supports it, fingerprint is available, and user has enabled it
        _showBiometricOption =
            isSupported && isFingerprintAvailable && isEnabled;
      });

      if (kDebugMode) {
        print('LoginScreen: Show biometric option: $_showBiometricOption');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.profileType.toString().split('.').last} Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Type Indicator
            Chip(
              label: Text(
                widget.profileType.toString().split('.').last,
                style: const TextStyle(fontSize: 16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor:
                  widget.profileType == ProfileType.business
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 40),

            // Password Input
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Enter Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              onChanged: (_) => setState(() => _errorMessage = null),
            ),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
              ),
            ),

            // Biometric Login Option
            if (_showBiometricOption) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleBiometricLogin,
                icon: const Icon(Icons.fingerprint, size: 24),
                label: const Text('Use Fingerprint'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Profile Help
            TextButton(
              onPressed: _showForgotPassword,
              child: const Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use Enhanced Firebase Auth Service for login
      final enhancedAuthService = EnhancedFirebaseAuthService();

      // For login screen, we need an email. Let's get it from user input or profile
      // This assumes we have an email field or we're using the old auth service for profile selection
      // We need to update this to work with the enhanced service
      final authService = Provider.of<AuthService>(context, listen: false);

      // Try to get email from current profile context
      String? email;
      if (authService.currentProfile != null) {
        email = authService.currentProfile!.email;
      }

      if (email != null) {
        // Use enhanced Firebase auth service
        final result = await enhancedAuthService.loginWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (result['success'] == true) {
          // Update SMS listener service with current profile ID
          final smsListenerService = Provider.of<SmsListenerService>(
            context,
            listen: false,
          );

          final profileId = result['profileId'];
          if (profileId != null) {
            smsListenerService.setCurrentProfile(profileId);
          }

          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          setState(() => _errorMessage = result['error'] ?? 'Login failed');
        }
      } else {
        // Fallback to old auth service if no email available
        final success = await authService.loginByType(
          widget.profileType,
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (success) {
          // Update SMS listener service with current profile ID
          final smsListenerService = Provider.of<SmsListenerService>(
            context,
            listen: false,
          );
          final currentProfile = authService.currentProfile;
          if (currentProfile != null) {
            smsListenerService.setCurrentProfile(currentProfile.id);
          }

          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          setState(
            () => _errorMessage = 'Invalid password for selected profile',
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.loginWithBiometric();

      if (!mounted) return;

      if (success) {
        // Update SMS listener service with current profile ID
        final smsListenerService = Provider.of<SmsListenerService>(
          context,
          listen: false,
        );
        final currentProfile = authService.currentProfile;
        if (currentProfile != null) {
          smsListenerService.setCurrentProfile(currentProfile.id);
        }

        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _errorMessage = 'Biometric authentication failed');
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'Biometric login failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address to receive password reset instructions.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid email address'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _handlePasswordReset(email);
                },
                child: const Text('Send Reset Email'),
              ),
            ],
          ),
    );
  }

  Future<void> _handlePasswordReset(String email) async {
    try {
      final enhancedAuthService = EnhancedFirebaseAuthService();
      final result = await enhancedAuthService.resetPassword(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success']
                  ? result['message'] ??
                      'Password reset email sent successfully!'
                  : result['error'] ?? 'Failed to send reset email',
            ),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
            duration: const Duration(
              seconds: 5,
            ), // Longer duration for success message
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
