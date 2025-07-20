// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/sms_listener_service.dart';
import '../services/biometric_auth_service.dart';
import '../utils/password_validator.dart';

class LoginScreen extends StatefulWidget {
  final ProfileType? profileType;

  const LoginScreen({super.key, this.profileType});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const SizedBox(height: 100), // Add top padding for visual centering
            // Profile Type Indicator
            Chip(
              label: Text(
                (widget.profileType ?? ProfileType.personal).toString().split('.').last,
                style: const TextStyle(fontSize: 16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor:
                  (widget.profileType ?? ProfileType.personal) == ProfileType.business
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
            ),
            const SizedBox(height: 40),

            // Password Input
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Enter Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
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
    final password = _passwordController.text.trim();
    final passwordError = PasswordValidator.getErrorMessage(password);
    
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.loginByType(
        widget.profileType ?? ProfileType.personal,
        password,
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

        // Check if biometric setup is needed
        await _promptBiometricSetupIfNeeded();

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

  Future<void> _promptBiometricSetupIfNeeded() async {
    final biometricService = BiometricAuthService.instance;
    final shouldPrompt = await biometricService.shouldPromptBiometricSetup();
    
    print('DEBUG: Should prompt biometric setup: $shouldPrompt');
    
    if (!shouldPrompt || !mounted) return;

    // Always show the dialog for testing
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Enable Biometric Security'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Would you like to enable fingerprint/face unlock for secure and convenient access to your account?',
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.security, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Enhanced Security', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.speed, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('Quick Access', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A39),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      print('DEBUG: User chose to enable biometric');
      final success = await biometricService.authenticate(
        reason: 'Set up biometric authentication for Fedha',
      );
      
      if (success) {
        await biometricService.setBiometricEnabled(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric security enabled successfully!'),
            backgroundColor: Color(0xFF007A39),
          ),
        );
        print('DEBUG: Biometric setup completed successfully');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric setup failed. You can enable it later in settings.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
