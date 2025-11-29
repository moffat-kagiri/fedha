// lib/utils/logger.dart - COMPLETE REVISION with file output
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';


class AppLogger {
  static bool _initialized = false;
  static File? _logFile;
  static final StringBuffer _logBuffer = StringBuffer();
  static DateTime? _lastFlush;

  static void init() {
    if (_initialized) return;

    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen(_handleLogRecord);

    _initialized = true;
    _initializeLogFile();
  }

  static Future<void> _initializeLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${directory.path}/output/logs');
      
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      _logFile = File('${outputDir.path}/fedha_$timestamp.log');

      // Write session start marker
      await _writeToFile('\n${'='*60}\n');
      await _writeToFile('NEW SESSION - ${DateTime.now().toIso8601String()}\n');
      await _writeToFile('${'='*60}\n\n');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize log file: $e');
      }
    }
  }

  static void _handleLogRecord(LogRecord record) {
    final time = record.time.toString().substring(11, 23); // HH:MM:SS.mmm
    final level = record.level.name.padRight(7);
    final logger = record.loggerName.padRight(20);
    final message = record.message;

    // Format log entry
    final logEntry = '[$time] $level $logger: $message';
    
    // Console output (only important logs in release mode)
    if (kDebugMode || record.level >= Level.WARNING) {
      _printToConsole(record.level, logEntry);
    }

    // File output (all logs)
    _addToBuffer(logEntry);
    
    // Add error and stack trace if present
    if (record.error != null) {
      final errorEntry = '  Error: ${record.error}';
      if (kDebugMode || record.level >= Level.SEVERE) {
        print(errorEntry);
      }
      _addToBuffer(errorEntry);
    }
    
    if (record.stackTrace != null) {
      final stackEntry = '  StackTrace:\n${record.stackTrace}';
      if (kDebugMode) {
        print(stackEntry);
      }
      _addToBuffer(stackEntry);
    }

    // Flush buffer periodically or on important logs
    if (record.level >= Level.WARNING || _shouldFlush()) {
      _flushBuffer();
    }
  }

  static void _printToConsole(Level level, String message) {
    // Color-coded console output for debug mode
    if (kDebugMode) {
      final color = _getColorCode(level);
      print('$color$message\x1B[0m');
    } else {
      print(message);
    }
  }

  static String _getColorCode(Level level) {
    if (level >= Level.SEVERE) return '\x1B[31m';      // Red
    if (level >= Level.WARNING) return '\x1B[33m';     // Yellow
    if (level >= Level.INFO) return '\x1B[32m';        // Green
    return '\x1B[37m';                                  // White
  }

  static void _addToBuffer(String entry) {
    _logBuffer.writeln(entry);
  }

  static bool _shouldFlush() {
    // Flush every 30 seconds or every 50 log entries
    if (_lastFlush == null) return true;
    
    final timeSinceFlush = DateTime.now().difference(_lastFlush!);
    return timeSinceFlush.inSeconds >= 30 || _logBuffer.length > 5000;
  }

  static Future<void> _flushBuffer() async {
    if (_logBuffer.isEmpty || _logFile == null) return;

    try {
      await _writeToFile(_logBuffer.toString());
      _logBuffer.clear();
      _lastFlush = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to flush log buffer: $e');
      }
    }
  }

  static Future<void> _writeToFile(String content) async {
    if (_logFile == null) return;

    try {
      await _logFile!.writeAsString(
        content,
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to write to log file: $e');
      }
    }
  }

  /// Force flush all buffered logs
  static Future<void> flush() async {
    await _flushBuffer();
  }

  /// Get the current log file path
  static String? get logFilePath => _logFile?.path;

  /// Clear old log files (keep last 7 days)
  static Future<void> cleanOldLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final outputDir = Directory('${directory.path}/output/logs');
      
      if (!await outputDir.exists()) return;

      final now = DateTime.now();
      final files = await outputDir.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          if (age.inDays > 7) {
            await file.delete();
            if (kDebugMode) {
              print('Deleted old log file: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clean old logs: $e');
      }
    }
  }

  static Logger getLogger(String name) {
    return Logger(name);
  }

  /// Create a summary log entry (for important events)
  static void logSummary(String title, Map<String, dynamic> data) {
    final logger = getLogger('Summary');
    final buffer = StringBuffer();
    
    buffer.writeln('\n${'='*40}');
    buffer.writeln(title.toUpperCase());
    buffer.writeln('='*40);
    
    data.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    
    buffer.writeln('='*40);
    
    logger.info(buffer.toString());
  }
}

/// Extension for easy logging
extension LoggerExtensions on Logger {
  void debug(String message) => finest(message);
  void verbose(String message) => fine(message);
}