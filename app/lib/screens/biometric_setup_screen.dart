import 'package:flutter/material.dart';
import '../services/biometric_auth_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

/// Simple, dedicated screen for biometric setup after first login
class BiometricSetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  final VoidCallback? onSkip;

  const BiometricSetupScreen({
    Key? key,
    required this.onSetupComplete,
    this.onSkip,
  }) : super(key: key);

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _logger = AppLogger.getLogger('BiometricSetupScreen');
  late BiometricAuthService _biometricService;
  bool _isSettingUp = false;
  bool _isAvailable = false;
  String? _errorMessage;
  String? _biometricType;

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricAuthService.instance!;
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await _biometricService.canAuthenticate();
      final biometricTypes = await _biometricService.getAvailableBiometrics();
      
      String? typeLabel;
      if (biometricTypes.contains('face')) {
        typeLabel = 'Face Recognition';
      } else if (biometricTypes.contains('fingerprint')) {
        typeLabel = 'Fingerprint';
      }

      if (mounted) {
        setState(() {
          _isAvailable = available;
          _biometricType = typeLabel;
        });
      }
    } catch (e) {
      _logger.severe('Error checking biometric availability: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not check biometric availability';
          _isAvailable = false;
        });
      }
    }
  }

  Future<void> _setupBiometric() async {
    setState(() {
      _isSettingUp = true;
      _errorMessage = null;
    });

    try {
      // Try to authenticate first to ensure biometric works
      final authenticated = await _biometricService.authenticateWithBiometric(
        'Set up biometric authentication for quick access',
      );

      if (!authenticated) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Biometric setup cancelled. You can skip for now.';
            _isSettingUp = false;
          });
        }
        return;
      }

      // Save current email/session for biometric login
      final authService = AuthService.instance;
      if (authService.currentProfile != null) {
        await _biometricService.setBiometricEnabled(true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric setup successful! You can now use biometric login.'),
              duration: Duration(seconds: 2),
            ),
          );
          widget.onSetupComplete();
        }
      }
    } catch (e) {
      _logger.severe('Error setting up biometric: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Setup failed: ${e.toString()}. Please try again.';
          _isSettingUp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Icon(
                _biometricType == 'Face Recognition' 
                  ? Icons.face 
                  : Icons.fingerprint,
                size: 80,
                color: const Color(0xFF007A39),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Secure Your Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                _isAvailable
                  ? 'Enable $_biometricType to unlock Fedha quickly and securely.\n\nYour biometric data stays on your device and is never shared.'
                  : 'Your device does not support biometric authentication.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Error message if any
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 24),

              // Buttons
              if (_isAvailable) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSettingUp ? null : _setupBiometric,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A39),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isSettingUp
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Enable $_biometricType',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Skip button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isSettingUp ? null : () {
                    widget.onSkip?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF007A39)),
                  ),
                  child: const Text(
                    'Skip for Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007A39),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your biometric data is stored securely on your device and is never sent to our servers.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
