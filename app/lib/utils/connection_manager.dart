import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

// A utility class to help with API connection configuration
class ConnectionManager {
  // Logger instance
  static final _log = AppLogger.getLogger('ConnectionManager');
  
  // List of connection options in priority order based on platform and environment
  static List<String> get _connectionOptions {
    // Base list that works for all platforms
    final baseOptions = [
      'https://lake-consistently-affects-applications.trycloudflare.com',  // Cloudflare tunnel - most reliable option
    ];
    
    // Platform-specific options
    if (kIsWeb) {
      // Web-specific options
      return [
        ...baseOptions,
      ];
    } else if (Platform.isAndroid) {
      return [
        'http://10.0.2.2:8000',                      // Android emulator loopback
        'http://127.0.0.1:8000',                     // Alternative localhost
        'http://192.168.100.6:8000',                 // Local network IP - confirmed working
        ...baseOptions,
      ];
    } else if (Platform.isIOS) {
      return [
        'http://localhost:8000',                     // iOS simulator and device
        'http://127.0.0.1:8000',                     // Alternative localhost
        'http://192.168.100.6:8000',                 // Local network IP
        ...baseOptions,
      ];
    } else {
      // Default for desktop platforms
      return [
        'http://localhost:8000',                     // Direct local connection
        'http://127.0.0.1:8000',                     // Alternative localhost
        'http://192.168.100.6:8000',                 // Local network IP - confirmed working
        ...baseOptions,
      ];
    }
  }

  // Timeout for each connection attempt
  static const Duration _connectionTimeout = Duration(seconds: 3);
  
  // Health endpoint path
  static const String _healthEndpoint = '/api/health/';

  /// ✅ PATCHED: Tests all connection options in PARALLEL and returns the first
  /// that succeeds. Worst-case latency = single timeout (3s), not N × 3s.
  static Future<String?> findWorkingConnection() async {
    _log.info('Probing ${_connectionOptions.length} connection options in parallel...');

    final options = _connectionOptions;
    if (options.isEmpty) return null;

    // Each option races independently. The first to return a non-null value wins.
    // We use a Completer so we can short-circuit as soon as one succeeds without
    // waiting for the others.
    final completer = Completer<String?>();
    int pending = options.length;

    for (final baseUrl in options) {
      _testSingleConnectionFast(baseUrl).then((winner) {
        if (winner != null && !completer.isCompleted) {
          _log.info('✅ First working connection: $winner');
          completer.complete(winner);
        }
      }).catchError((_) {
        // swallow individual errors
      }).whenComplete(() {
        pending--;
        // If all probes exhausted without a winner, complete with null
        if (pending == 0 && !completer.isCompleted) {
          _log.warning('❌ All connection probes failed');
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  /// Lightweight single-URL probe used by the parallel finder.
  static Future<String?> _testSingleConnectionFast(String baseUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_healthEndpoint'),
        headers: {'Accept': 'application/json'},
      ).timeout(_connectionTimeout);

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.contains('healthy') || body.contains('status')) {
          return baseUrl;
        }
        // Got 200 but unexpected body — still accept it
        return baseUrl;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
  
  // Helper function to get the minimum of two values
  static int min(int a, int b) => a < b ? a : b;

  // For use in your main app to configure the connection
  static Future<void> configureApiConnection() async {
    final workingBaseUrl = await findWorkingConnection();
    
    if (workingBaseUrl != null) {
      // Here you would set your application's API client configuration
      // For example:
      // ApiClient.setBaseUrl(workingBaseUrl);
      _log.info('🚀 API configured with base URL: $workingBaseUrl');
    } else {
      // Handle the case when no connection works
      _log.severe('⚠️ Could not establish API connection. Check network or server.');
      // You might want to show a dialog to the user here
    }
  }
  
  // Check all connection options and return detailed results
  static Future<Map<String, ConnectionTestResult>> testAllConnections() async {
    final results = <String, ConnectionTestResult>{};
    
    for (var baseUrl in _connectionOptions) {
      final result = await testSingleConnection(baseUrl);
      results[baseUrl] = result;
    }
    
    return results;
  }
  
  // Test a single connection and return detailed results
  static Future<ConnectionTestResult> testSingleConnection(String baseUrl) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_healthEndpoint'),
        headers: {'Accept': 'application/json'},
      ).timeout(_connectionTimeout);
      
      stopwatch.stop();
      
      return ConnectionTestResult(
        url: baseUrl,
        isSuccessful: response.statusCode == 200,
        statusCode: response.statusCode,
        responseTime: stopwatch.elapsedMilliseconds,
        errorMessage: response.statusCode != 200 ? 'HTTP ${response.statusCode}' : null,
        responseBody: response.statusCode == 200 ? response.body : null,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(
        url: baseUrl,
        isSuccessful: false,
        statusCode: 0,
        responseTime: stopwatch.elapsedMilliseconds,
        errorMessage: 'Connection refused: ${e.message}',
      );
    } on TimeoutException {
      stopwatch.stop();
      return ConnectionTestResult(
        url: baseUrl,
        isSuccessful: false,
        statusCode: 0,
        responseTime: stopwatch.elapsedMilliseconds,
        errorMessage: 'Connection timed out after ${_connectionTimeout.inSeconds} seconds',
      );
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(
        url: baseUrl,
        isSuccessful: false,
        statusCode: 0,
        responseTime: stopwatch.elapsedMilliseconds,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }
}

// Result class for connection tests
class ConnectionTestResult {
  final String url;
  final bool isSuccessful;
  final int statusCode;
  final int responseTime;
  final String? errorMessage;
  final String? responseBody;
  
  ConnectionTestResult({
    required this.url,
    required this.isSuccessful,
    required this.statusCode,
    required this.responseTime,
    this.errorMessage,
    this.responseBody,
  });
  
  @override
  String toString() {
    return 'URL: $url, Success: $isSuccessful, Status: $statusCode, Time: ${responseTime}ms, ${errorMessage ?? ""}';
  }
}
