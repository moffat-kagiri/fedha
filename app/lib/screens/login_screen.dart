// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_profile.dart';
import '../services/auth_service.dart';
import '../services/sms_listener_service.dart';
import '../services/biometric_auth_service.dart';

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
              onPressed: _showProfileHelp,
              child: const Text('Having trouble logging in?'),
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
      final authService = Provider.of<AuthService>(context, listen: false);
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
        setState(() => _errorMessage = 'Invalid password for selected profile');
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

  void _showProfileHelp() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Profile Help'),
            content: const Text(
              'Contact support at support@fedha.app if you\'ve forgotten your password.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
