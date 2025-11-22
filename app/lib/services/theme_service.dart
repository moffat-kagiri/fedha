import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();
  
  ThemeService._();

  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode');
    if (mode == 'light') {
      _themeMode = ThemeMode.light;  // Fixed: use _themeMode instead of themeMode
    } else if (mode == 'dark') {
      _themeMode = ThemeMode.dark;   // Fixed: use _themeMode instead of themeMode
    } else {
      _themeMode = ThemeMode.system; // Fixed: use _themeMode instead of themeMode
    }
    notifyListeners(); // Added: notify listeners after initialization
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await prefs.setString('themeMode', modeString);
    
    notifyListeners();
  }

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    // Save the new theme mode
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    switch (_themeMode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await prefs.setString('themeMode', modeString);
    
    notifyListeners();
  }

  String getThemeModeDisplayName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}