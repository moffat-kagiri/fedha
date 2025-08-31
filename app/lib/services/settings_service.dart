import 'package:flutter/material.dart';
import '../data/app_database.dart';

class SettingsService extends ChangeNotifier {
  final AppDatabase _db;
  AppSetting? _currentSettings;
  String? _savedEmail;
  bool _rememberMe = false;
  bool _onboardingComplete = false;
  
  SettingsService(this._db);
  
  // Initialize settings
  Future<void> initialize() async {
    _currentSettings = await _db.getAppSettings();
    _savedEmail = _currentSettings?.savedEmail;
    _rememberMe = _currentSettings?.rememberMe ?? false;
    _onboardingComplete = _currentSettings?.onboardingComplete ?? false;
    notifyListeners();
  }
  
  // Email and Remember Me settings
  String? get savedEmail => _savedEmail;
  bool get rememberMe => _rememberMe;
  
  Future<void> setSavedEmail(String? email, bool remember) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        savedEmail: Value(email),
        rememberMe: Value(remember),
      ),
    );
    _savedEmail = email;
    _rememberMe = remember;
    notifyListeners();
  }
  
  // Onboarding status
  bool get onboardingComplete => _onboardingComplete;
  Future<void> setOnboardingComplete(bool complete) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        onboardingComplete: Value(complete),
      ),
    );
    _onboardingComplete = complete;
    notifyListeners();
  }

  // Permissions prompt status
  bool get permissionsPromptShown => _currentSettings?.permissionsPromptShown ?? false;
  Future<void> setPermissionsPromptShown(bool shown) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        permissionsPromptShown: Value(shown),
      ),
    );
    await _refreshSettings();
  }
  
  // Theme settings
  String get theme => _currentSettings?.theme ?? 'system';
  Future<void> setTheme(String theme) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        theme: Value(theme),
      ),
    );
    await _refreshSettings();
  }
  
  // Security settings
  bool get biometricEnabled => _currentSettings?.biometricEnabled ?? false;
  Future<void> setBiometricEnabled(bool enabled) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        biometricEnabled: Value(enabled),
      ),
    );
    await _refreshSettings();
  }
  
  // SMS settings
  bool get smsEnabled => _currentSettings?.smsEnabled ?? true;
  Future<void> setSmsEnabled(bool enabled) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        smsEnabled: Value(enabled),
      ),
    );
    await _refreshSettings();
  }
  
  // Notification settings
  bool get budgetAlerts => _currentSettings?.budgetAlerts ?? true;
  Future<void> setBudgetAlerts(bool enabled) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        budgetAlerts: Value(enabled),
      ),
    );
    await _refreshSettings();
  }
  
  bool get goalReminders => _currentSettings?.goalReminders ?? true;
  Future<void> setGoalReminders(bool enabled) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        goalReminders: Value(enabled),
      ),
    );
    await _refreshSettings();
  }
  
  // Backup settings
  String get backupFrequency => _currentSettings?.backupFrequency ?? 'weekly';
  Future<void> setBackupFrequency(String frequency) async {
    if (_currentSettings == null) return;
    
    await _db.updateAppSettings(
      AppSettingsCompanion(
        id: Value(_currentSettings!.id),
        backupFrequency: Value(frequency),
      ),
    );
    await _refreshSettings();
  }
  
  // Helper to refresh settings
  Future<void> _refreshSettings() async {
    _currentSettings = await _db.getAppSettings();
    notifyListeners();
  }
}
