import 'package:flutter/foundation.dart';

/// A utility class for logging application events
class AppLogger {
  final String _className;
  
  /// Creates a logger for a specific class
  AppLogger(this._className);
  
  /// Log info level message
  void info(String message) {
    _log('INFO', message);
  }
  
  /// Log warning level message
  void warning(String message) {
    _log('WARNING', message);
  }
  
  /// Log error level message
  void error(String message) {
    _log('ERROR', message);
  }
  
  /// Log warning level message (alternative method)
  void warn(String message) {
    warning(message);
  }
  
  /// Log severe level message
  void severe(String message) {
    _log('SEVERE', message);
  }
  
  /// Internal log method
  void _log(String level, String message) {
    if (kDebugMode) {
      print('$level [$_className] $message');
    }
  }
}
