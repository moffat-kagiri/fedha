import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/settings_service.dart';
import '../utils/logger.dart';

class BiometricAuthService {
  // Singleton instance
  static BiometricAuthService? _instance;
  
  // Get singleton instance
  static BiometricAuthService get instance {
    if (_instance == null) {
      _instance = BiometricAuthService._(SettingsService());
      _instance!._init();
    }
    return _instance!;
  }
  
  static Future<void> initializeService(SettingsService settingsService) async {
    if (_instance == null) {
      _instance = BiometricAuthService._(settingsService);
      await _instance!._init();
    }
  }
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  final _logger = AppLogger.getLogger('BiometricAuthService');
  final SettingsService _settingsService;
  
  // Constants for storage keys
  final _biometricEnabledKey = 'biometric_enabled';
  final _lastAuthTimeKey = 'last_biometric_auth_time';
  final _sessionTokenKey = 'biometric_session_token';
  final _biometricAuthKey = 'biometric_auth_key';
  
  // Session duration in minutes - determines how long auth session remains valid after successful biometric auth
  // Set to 5 minutes to avoid immediate re-prompt on resume
  final _sessionDurationMinutes = 5;

  Future<void> initialize() async {
    _logger.info('Initializing BiometricAuthService');
    // No initialization needed currently
  }

  Future<bool> canAuthenticate() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || 
          await _localAuth.isDeviceSupported();
      
      _logger.info('Can authenticate with biometrics: $canAuthenticate');
      return canAuthenticate;
    } catch (e) {
      _logger.severe('Error checking biometric availability: $e');
      return false;
    }
  }
  
  // This is the actual authentication method
  Future<bool> authenticateWithBiometric(String reason) async {
    try {
  // Attempt authentication directly; LocalAuthentication will handle availability
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,       // allow device PIN/passcode fallback
          useErrorDialogs: true,      // show system error dialogs
        ),
      );
      
      if (authenticated) {
        await _saveAuthenticationSession();
      }
      
      return authenticated;
    } catch (e) {
      _logger.severe('Biometric authentication error: $e');
      return false;
    }
  }
  
  BiometricAuthService._(this._settingsService);

  Future<void> _init() async {
    _logger.info('Initializing BiometricAuthService');
  }

  Future<bool> hasValidBiometricSession() async {
    try {
      final lastAuthTime = await _secureStorage.read(key: _lastAuthTimeKey);
      final sessionToken = await _secureStorage.read(key: _sessionTokenKey);
      
      if (lastAuthTime == null || sessionToken == null) {
        return false;
      }
      
      final authTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAuthTime));
      final now = DateTime.now();
      
  final sessionExpiry = authTime.add(Duration(minutes: _sessionDurationMinutes));
      
      return now.isBefore(sessionExpiry);
    } catch (e) {
      _logger.severe('Error checking biometric session: $e');
      return false;
    }
  }
  
  /// Check if biometric authentication can be attempted (device supports biometrics and/or passcode)
  Future<bool> isAvailable() async {
    return await canAuthenticate();
  }
  
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _settingsService.setBiometricEnabled(enabled);
      _logger.info('Biometric auth set to: $enabled');
    } catch (e) {
      _logger.severe('Error setting biometric enabled: $e');
    }
  }
  
  Future<bool> isBiometricEnabled() async {
    try {
      return _settingsService.biometricEnabled;
    } catch (e) {
      _logger.severe('Error checking if biometric is enabled: $e');
      return false;
    }
  }
  
  Future<void> _saveAuthenticationSession() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Generate a session token - in a real app, this would be more secure
      final sessionToken = DateTime.now().toIso8601String();
      
      await _secureStorage.write(key: _lastAuthTimeKey, value: now.toString());
      await _secureStorage.write(key: _sessionTokenKey, value: sessionToken);
      
      _logger.info('Saved authentication session');
    } catch (e) {
      _logger.severe('Error saving authentication session: $e');
    }
  }
  
  // Alias for authenticateWithBiometric to maintain compatibility with extension methods
  Future<bool> authenticate({required String localizedReason}) async {
    return authenticateWithBiometric(localizedReason);
  }
  
  Future<void> clearBiometricSession() async {
    try {
      await _secureStorage.delete(key: _lastAuthTimeKey);
      await _secureStorage.delete(key: _sessionTokenKey);
      await _secureStorage.delete(key: _biometricAuthKey);
      
      _logger.info('Cleared biometric session');
    } catch (e) {
      _logger.severe('Error clearing biometric session: $e');
    }
  }

  // Backwards compatibility method expected by some screens and login_screen
  Future<void> setBiometricSession() async {
    await _saveAuthenticationSession();
  }
  
  /// Save credentials for biometric authentication
  Future<void> saveCredentials({
    required String userId,
    required String email,
    required String sessionToken,
  }) async {
    try {
      // Store the credentials securely
      final credentialsJson = {
        'userId': userId,
        'email': email,
        'sessionToken': sessionToken,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: _biometricAuthKey,
        value: credentialsJson.toString(),
      );
      
      _logger.info('Saved credentials for biometric authentication');
    } catch (e) {
      _logger.severe('Error saving credentials for biometric authentication: $e');
      rethrow;
    }
  }
}
