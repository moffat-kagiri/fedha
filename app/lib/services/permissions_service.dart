import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/settings_service.dart';
import '../utils/logger.dart';

/// Service to handle all app permissions
class PermissionsService extends ChangeNotifier {
  static PermissionsService? _instance;
  final SettingsService _settingsService;
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
  
  PermissionsService._(this._settingsService);
  
  static void initialize(SettingsService settingsService) {
    _instance = PermissionsService._(settingsService);
  }
  
  static PermissionsService get instance {
    if (_instance == null) {
      throw Exception('PermissionsService not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the service and check permission status
  Future<void> initializePermissions() async {
    try {
      _permissionsPromptShown = _settingsService.permissionsPromptShown;
      
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
      // Storage: either legacy storage or Android 13+ media permissions
      final legacyStorage = await Permission.storage.isGranted;
      bool mediaStorage = false;
      try {
        mediaStorage = await Permission.photos.isGranted && await Permission.videos.isGranted;
      } catch (_) {}
      _storagePermissionGranted = legacyStorage || mediaStorage;
    } else {
      _storagePermissionGranted = await Permission.storage.isGranted;
    }
    _notificationsPermissionGranted = await Permission.notification.isGranted;
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
    if (Platform.isAndroid) {
      // On Android 13+, request media permissions instead of legacy storage
      bool granted = false;
      try {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        granted = photos.isGranted && videos.isGranted;
      } catch (_) {
        // Fallback to legacy storage
        final status = await Permission.storage.request();
        granted = status.isGranted;
      }
      _storagePermissionGranted = granted;
    } else {
      final status = await Permission.storage.request();
      _storagePermissionGranted = status.isGranted;
    }
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
    
    // Request SMS permissions on Android
    if (Platform.isAndroid) {
      results['sms'] = await requestSmsPermission();
    }
    // Request camera permission
    results['camera'] = await requestCameraPermission();
    // Request storage permission
    results['storage'] = await requestStoragePermission();
    // On Android 13+, request granular media permissions
    try {
      final photosStatus = await Permission.photos.request();
      results['photos'] = photosStatus.isGranted;
      final videosStatus = await Permission.videos.request();
      results['videos'] = videosStatus.isGranted;
    } catch (_) {
      // If granular media perms not supported, ignore
    }
    // Request notification permission last
    results['notifications'] = await requestNotificationsPermission();
    // Optionally mark prompt shown only if all core permissions granted
    final coreGranted = _smsPermissionGranted && _storagePermissionGranted && _cameraPermissionGranted;
    if (coreGranted) {
      await markPermissionsPromptShown();
    }
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
  // Prompt if storage or camera not granted
  if (!_storagePermissionGranted) return true;
  if (!_cameraPermissionGranted) return true;
    
    return false;
  }
}
