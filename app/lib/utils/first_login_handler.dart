import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../services/permissions_service.dart';

/// Handler for first login prompts like biometric setup and permissions
class FirstLoginHandler {
  final AuthService _authService;
  final BuildContext _context;
  
  FirstLoginHandler(this._context, this._authService);
  
  /// Shows all required first-login prompts in sequence
  /// Returns true if the required prompts completed (or were skipped
  /// non-forced), false if a forced biometric setup was not completed.
  Future<bool> handleFirstLogin({bool forceBiometric = false}) async {
    if (!await _authService.isFirstLogin()) return true;

    // Biometric setup prompt
    if (await _authService.shouldShowBiometricPrompt()) {
      final biometricResult = await _showBiometricSetupPrompt(force: forceBiometric);
      if (!biometricResult && forceBiometric) {
        // User did not complete forced biometric setup
        return false;
      }
    }

    // Permissions prompt (SMS, notifications, storage, camera)
    final permissionsService = PermissionsService.instance;
    if (await permissionsService.shouldShowPermissionsPrompt()) {
      await _showPermissionsPrompt(permissionsService);
    }

    // Mark first login as completed
    await _authService.markFirstLoginCompleted();
    return true;
  }
  
  /// Shows a dialog to prompt biometric setup
  /// Shows a dialog to prompt biometric setup. If [force] is true the dialog
  /// will not offer a SKIP option and will only return true when biometric
  /// setup was enabled.
  Future<bool> _showBiometricSetupPrompt({bool force = false}) async {
    final bool? setupBiometric = await showDialog<bool>(
      context: _context,
      barrierDismissible: !force,
      builder: (context) => AlertDialog(
        title: const Text('Secure Your Account'),
        content: const Text(
          'Would you like to use your fingerprint or face recognition '
          'to quickly and securely access your account?'
        ),
        actions: [
          if (!force)
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
      final enabled = await _authService.enableBiometricAuth(true);
      return enabled;
    }
    return false;
  }
  
  /// Shows a dialog to prompt permissions
  Future<void> _showPermissionsPrompt(PermissionsService permissionsService) async {
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
    await permissionsService.markPermissionsPromptShown();
    
    // Request all app permissions if user agreed
    if (requestPermissions == true) {
      await permissionsService.requestAllPermissions();
    }
  }
  
  /// Request all required app permissions
  // Permissions request replaced by PermissionsService.requestAllPermissions()
}
