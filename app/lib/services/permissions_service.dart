import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Service to handle all app permissions
class PermissionsService extends ChangeNotifier {
  static PermissionsService? _instance;
  static PermissionsService get instance => _instance ??= PermissionsService._();
  
  final _logger = AppLogger.getLogger('PermissionsService');
  
  // Permission status tracking
  bool _smsPermissionGranted = false;
  bool _notificationsPermissionGranted = false;
  bool _storagePermissionGranted = false;
  bool _cameraPermissionGranted = false;
  
  // Flag to track if permissions prompt has been shown
  bool _permissionsPromptShown = false;
  
  // Getters
  bool get smsPermissionGranted => _smsPermissionGranted;
  bool get notificationsPermissionGranted => _notificationsPermissionGranted;
  bool get storagePermissionGranted => _storagePermissionGranted;
  bool get cameraPermissionGranted => _cameraPermissionGranted;
  bool get permissionsPromptShown => _permissionsPromptShown;
  
  PermissionsService._();
  
  /// Initialize the service and check permission status
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _permissionsPromptShown = prefs.getBool('permissions_prompt_shown') ?? false;
      
      // Check current permission status
      await checkPermissionsStatus();
      
      _logger.info('PermissionsService initialized');
    } catch (e) {
      _logger.severe('Error initializing PermissionsService: $e');
    }
  }
  
  /// Check status of all permissions
  Future<void> checkPermissionsStatus() async {
    if (Platform.isAndroid) {
      _smsPermissionGranted = await Permission.sms.isGranted;
    }
    
    _notificationsPermissionGranted = await Permission.notification.isGranted;
    _storagePermissionGranted = await Permission.storage.isGranted;
    _cameraPermissionGranted = await Permission.camera.isGranted;
    
    notifyListeners();
  }
  
  /// Request SMS permissions (Android only)
  Future<bool> requestSmsPermission() async {
    if (!Platform.isAndroid) return false;
    
    final status = await Permission.sms.request();
    _smsPermissionGranted = status.isGranted;
    notifyListeners();
    
    return _smsPermissionGranted;
  }
  
  /// Request notification permissions
  Future<bool> requestNotificationsPermission() async {
    final status = await Permission.notification.request();
    _notificationsPermissionGranted = status.isGranted;
    notifyListeners();
    
    return _notificationsPermissionGranted;
  }
  
  /// Request storage permissions
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    _storagePermissionGranted = status.isGranted;
    notifyListeners();
    
    return _storagePermissionGranted;
  }
  
  /// Request camera permissions
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    _cameraPermissionGranted = status.isGranted;
    notifyListeners();
    
    return _cameraPermissionGranted;
  }
  
  /// Request all necessary permissions at once
  Future<Map<String, bool>> requestAllPermissions() async {
    Map<String, bool> results = {};
    
    // Request notifications permission
    results['notifications'] = await requestNotificationsPermission();
    
    // Request SMS permission on Android
    if (Platform.isAndroid) {
      results['sms'] = await requestSmsPermission();
    }
    
    // Request storage permission
    results['storage'] = await requestStoragePermission();
    
    // Request camera permission
    results['camera'] = await requestCameraPermission();
    
    // Mark permissions prompt as shown
    await markPermissionsPromptShown();
    
    return results;
  }
  
  /// Mark permissions prompt as shown
  Future<void> markPermissionsPromptShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_prompt_shown', true);
      _permissionsPromptShown = true;
      notifyListeners();
    } catch (e) {
      _logger.warning('Error marking permissions prompt as shown: $e');
    }
  }
  
  /// Check if the app needs to show permissions prompt
  Future<bool> shouldShowPermissionsPrompt() async {
    // If we've already shown it, no need to show again
    if (_permissionsPromptShown) return false;
    
    // Check current status
    await checkPermissionsStatus();
    
    // If any required permission is not granted, we should show the prompt
    if (Platform.isAndroid && !_smsPermissionGranted) return true;
    if (!_notificationsPermissionGranted) return true;
    
    return false;
  }
}
