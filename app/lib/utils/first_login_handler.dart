import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';

/// Handler for first login prompts like biometric setup and permissions
class FirstLoginHandler {
  final AuthService _authService;
  final BuildContext _context;
  
  FirstLoginHandler(this._context, this._authService);
  
  /// Shows all required first-login prompts in sequence
  Future<void> handleFirstLogin() async {
    if (!await _authService.isFirstLogin()) {
      return; // Not a first login, exit
    }
    
    // Show biometric setup prompt if needed
    if (await _authService.shouldShowBiometricPrompt()) {
      await _showBiometricSetupPrompt();
    }
    
    // Show permissions prompt
    if (await _authService.shouldShowPermissionsPrompt()) {
      await _showPermissionsPrompt();
    }
    
    // Mark first login as completed
    await _authService.markFirstLoginCompleted();
  }
  
  /// Shows a dialog to prompt biometric setup
  Future<void> _showBiometricSetupPrompt() async {
    final bool? setupBiometric = await showDialog<bool>(
      context: _context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Secure Your Account'),
        content: const Text(
          'Would you like to use your fingerprint or face recognition '
          'to quickly and securely access your account?'
        ),
        actions: [
          TextButton(
            child: const Text('SKIP'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A39), // Fedha green
            ),
            child: const Text('ENABLE'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    
    // Mark biometric prompt as shown
    await _authService.markBiometricPromptShown();
    
    // Setup biometric if user agreed
    if (setupBiometric == true) {
      await _authService.enableBiometricAuth(true);  // Passing true to enable biometric auth
    }
  }
  
  /// Shows a dialog to prompt permissions
  Future<void> _showPermissionsPrompt() async {
    final bool? requestPermissions = await showDialog<bool>(
      context: _context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('App Permissions'),
        content: const Text(
          'To provide you with the best experience, Fedha needs permission to:\n\n'
          '• Access SMS messages to track financial transactions\n'
          '• Make & manage phone calls for support features\n'
          '• Send notifications about your financial goals and activity'
        ),
        actions: [
          TextButton(
            child: const Text('LATER'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A39), // Fedha green
            ),
            child: const Text('GRANT PERMISSIONS'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    
    // Mark permissions prompt as shown
    await _authService.markPermissionsPromptShown();
    
    // Request permissions if user agreed
    if (requestPermissions == true) {
      await _requestAppPermissions();
    }
  }
  
  /// Request all required app permissions
  Future<void> _requestAppPermissions() async {
    // Request SMS permission
    await Permission.sms.request();
    
    // Request phone permission
    await Permission.phone.request();
    
    // Request notification permission
    await Permission.notification.request();
  }
}
