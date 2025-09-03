import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

/// A utility class for logging
class AppLogger {
  static final Map<String, Logger> _loggers = {};

  /// Initialize the logging system
  static void init() {
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        print('${record.level.name}: ${record.time}: ${record.message}');
        if (record.error != null) {
          print('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          print('Stack trace:\n${record.stackTrace}');
        }
      }
    });
  }

  /// Get a logger instance for a specific class or context
  static Logger getLogger(String name) {
    if (!_loggers.containsKey(name)) {
      _loggers[name] = Logger(name);
    }
    return _loggers[name]!;
  }
}
