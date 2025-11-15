import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';
import '../utils/logger.dart';

/// Simple biometric lock screen for app resume
class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final VoidCallback? onSkip;

  const BiometricLockScreen({
    Key? key,
    required this.onAuthSuccess,
    this.onSkip,
  }) : super(key: key);

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool _isAuthenticating = false;
  String? _errorMessage;
  String _biometricType = 'Fingerprint';
  final _logger = AppLogger.getLogger('BiometricLockScreen');

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _getBiometricType();
    _attemptAuth();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  Future<void> _getBiometricType() async {
    try {
      final biometricService = BiometricAuthService.instance;
      if (biometricService == null) return;

      final biometrics = await biometricService.getAvailableBiometrics();
      if (biometrics.contains('face')) {
        setState(() => _biometricType = 'Face ID');
      } else if (biometrics.contains('fingerprint')) {
        setState(() => _biometricType = 'Fingerprint');
      }
    } catch (e) {
      _logger.warning('Error getting biometric type: $e');
    }
  }

  Future<void> _attemptAuth() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final biometricService = BiometricAuthService.instance;
      if (biometricService == null) {
        setState(() {
          _errorMessage = 'Biometric service unavailable';
          _isAuthenticating = false;
        });
        return;
      }

      final success = await biometricService.authenticateWithBiometric(
        'Authenticate to access Fedha',
      );

      if (!mounted) return;

      if (success) {
        widget.onAuthSuccess();
      } else {
        setState(() {
          _errorMessage = 'Authentication failed. Try again.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      _logger.severe('Auth error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF007A39).withOpacity(0.8),
              const Color(0xFF006B31),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated biometric icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _biometricType == 'Face ID'
                      ? Icons.face
                      : Icons.fingerprint,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Status text
              Text(
                'Unlock Fedha',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Instructions
              if (_isAuthenticating)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Authenticating...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Use your $_biometricType to unlock',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Buttons
              if (_errorMessage != null) ...[
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _attemptAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        color: Color(0xFF007A39),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Skip button
              if (widget.onSkip != null)
                TextButton(
                  onPressed: _isAuthenticating ? null : widget.onSkip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
