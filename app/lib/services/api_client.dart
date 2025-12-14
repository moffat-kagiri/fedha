// lib/services/api_client.dart - Backend V2 Compatible
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../config/api_config.dart';

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  factory ApiClient() => instance;

  final http.Client _http = http.Client();
  final logger = AppLogger.getLogger('ApiClient');
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  ApiConfig _config;
  String? _overrideBase;
  bool _usingFallback = false;

  /// Use development config in debug mode
  ApiClient._() : _config = kDebugMode ? ApiConfig.development() : ApiConfig.production();

  /// Initialize with a specific config
  void init({ApiConfig? config}) {
    if (config != null) {
      _config = config;
    }
  }

  // Expose current config
  ApiConfig get config => _config;
  bool get isUsingFallbackServer => _usingFallback;

  String get baseUrl {
    final host = _overrideBase ?? _config.primaryApiUrl;
    final scheme = _config.useSecureConnections ? 'https' : 'http';
    return '$scheme://$host';
  }

  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
    logger.info('Auth token set');
  }

  void clearAuthToken() {
    _headers.remove('Authorization');
    logger.info('Auth token cleared');
  }

  // ==================== HEALTH CHECK ====================

  Future<bool> checkServerHealth() async {
    try {
      logger.info('Checking server health: ${_config.healthCheckUrl}');
      final resp = await _http
          .get(Uri.parse(_config.healthCheckUrl), headers: _headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      final isHealthy = resp.statusCode == 200;
      logger.info('Server health: ${isHealthy ? "OK" : "FAIL"} (${resp.statusCode})');
      return isHealthy;
    } catch (e) {
      logger.warning('Health check failed: $e');
      return false;
    }
  }

  Future<bool> healthCheck() => checkServerHealth();

  // ==================== AUTHENTICATION ====================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/auth/login/'));
    
    try {
      logger.info('POST ${url.toString()}');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Login response: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        
        // Backend V2 returns token in 'token' field
        if (data['token'] != null) {
          setAuthToken(data['token']);
          logger.info('Login successful, token received');
        }
        
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
        };
      }
      
      logger.warning('Login failed: ${resp.statusCode} - ${resp.body}');
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
        'error': 'Invalid email or password'
      };
    } catch (e) {
      logger.severe('Login error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? avatarPath,
    String? deviceId,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/auth/register/'));
    
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    };
    
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    
    try {
      logger.info('POST ${url.toString()}');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Register response: ${resp.statusCode}');
      
      if (resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        
        // Backend V2 returns token in 'token' field
        if (data['token'] != null) {
          setAuthToken(data['token']);
          logger.info('Registration successful, token received');
        }
        
        return {
          'success': true,
          'status': 201,
          'token': data['token'],
          'user': data['user'],
        };
      }
      
      logger.warning('Registration failed: ${resp.statusCode} - ${resp.body}');
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
      };
    } catch (e) {
      logger.severe('Registration error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfile({
    required String sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/profile/'));
    
    try {
      logger.info('GET ${url.toString()}');
      
      final headers = {
        ..._headers,
        'Authorization': 'Bearer $sessionToken',
      };
      
      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Get profile response: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {
          'success': true,
          'profile': data['profile'],
        };
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
      };
    } catch (e) {
      logger.severe('Get profile error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> invalidateSession({
    bool clearLocalToken = true,
    String? userId,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/auth/logout/'));
    
    try {
      logger.info('POST ${url.toString()}');
      
      final resp = await _http
          .post(url, headers: _headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      final ok = resp.statusCode == 200 || resp.statusCode == 204;
      
      if (ok && clearLocalToken) {
        clearAuthToken();
      }
      
      logger.info('Logout: ${ok ? "OK" : "FAIL"}');
      return ok;
    } catch (e) {
      logger.warning('Logout failed: $e');
      return false;
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<Map<String, dynamic>> syncTransactions(
    String profileId,
    List<dynamic> transactions,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/transactions/bulk_sync/'));
    
    try {
      logger.info('POST ${url.toString()} - ${transactions.length} transactions');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(transactions),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('Sync complete: ${data['created']} created, ${data['updated']} updated');
        return data;
      }
      
      return {'success': false, 'status': resp.statusCode};
    } catch (e) {
      logger.severe('Sync transactions error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<dynamic>> getTransactions({
    required String profileId,
    required String sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/transactions/?profile_id=$profileId'));
    
    try {
      final headers = {
        ..._headers,
        'Authorization': 'Bearer $sessionToken',
      };
      
      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // DRF paginated response has 'results' field
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return data as List<dynamic>;
      }
      
      return [];
    } catch (e) {
      logger.severe('Get transactions error: $e');
      return [];
    }
  }

  // ==================== BUDGETS ====================

  Future<Map<String, dynamic>> syncBudgets(
    String profileId,
    List<dynamic> budgets,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/budgets/bulk_sync/'));
    
    try {
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(budgets),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      
      return {'success': false, 'status': resp.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== GOALS ====================

  Future<Map<String, dynamic>> syncGoals(
    String profileId,
    List<dynamic> goals,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/goals/bulk_sync/'));
    
    try {
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(goals),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      
      return {'success': false, 'status': resp.statusCode};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== CATEGORIES ====================

  Future<Map<String, dynamic>> syncCategories(
    String profileId,
    List<dynamic> categories,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/transactions/categories/'));
    
    try {
      // Backend V2 doesn't have bulk sync for categories yet
      // Sync one by one for now
      int created = 0;
      int updated = 0;
      
      for (final category in categories) {
        final catUrl = Uri.parse(_config.getEndpoint('api/transactions/categories/'));
        final resp = await _http.post(
          catUrl,
          headers: _headers,
          body: jsonEncode(category),
        );
        
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          created++;
        }
      }
      
      return {'success': true, 'created': created, 'updated': updated};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== LOANS ====================

  Future<List<dynamic>> getLoans({
    required String profileId,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/invoicing/loans/?profile_id=$profileId'));

    try {
      final headers = {
        ..._headers,
        if (sessionToken != null) 'Authorization': 'Bearer $sessionToken',
      };

      final resp = await _http.get(url, headers: headers).timeout(Duration(seconds: _config.timeoutSeconds));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return data as List<dynamic>;
      }

      logger.warning('Get loans failed: ${resp.statusCode} ${resp.body}');
      return [];
    } catch (e) {
      logger.severe('Get loans error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getActiveLoans({
    required String profileId,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/invoicing/loans/active/?profile_id=$profileId'));

    try {
      final headers = {
        ..._headers,
        if (sessionToken != null) 'Authorization': 'Bearer $sessionToken',
      };

      final resp = await _http.get(url, headers: headers).timeout(Duration(seconds: _config.timeoutSeconds));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      logger.severe('Get active loans error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createLoan({
    required Map<String, dynamic> loan,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/invoicing/loans/'));

    try {
      final resp = await _http.post(url, headers: _headers, body: jsonEncode(loan)).timeout(Duration(seconds: _config.timeoutSeconds));
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return {'success': false, 'status': resp.statusCode, 'body': resp.body};
    } catch (e) {
      logger.severe('Create loan error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateLoan({
    required int loanId,
    required Map<String, dynamic> loan,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/invoicing/loans/$loanId/'));

    try {
      final resp = await _http.put(url, headers: _headers, body: jsonEncode(loan)).timeout(Duration(seconds: _config.timeoutSeconds));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return {'success': false, 'status': resp.statusCode, 'body': resp.body};
    } catch (e) {
      logger.severe('Update loan error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> deleteLoan({
    required int loanId,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/invoicing/loans/$loanId/'));

    try {
      final resp = await _http.delete(url, headers: _headers).timeout(Duration(seconds: _config.timeoutSeconds));
      return resp.statusCode == 204 || resp.statusCode == 200;
    } catch (e) {
      logger.warning('Delete loan failed: $e');
      return false;
    }
  }

  // ==================== STUBS (for compatibility) ====================

  Future<Map<String, dynamic>> syncClients(String profileId, List<dynamic> clients) async {
    return {'success': true};
  }

  Future<Map<String, dynamic>> syncInvoices(String profileId, List<dynamic> invoices) async {
    return {'success': true};
  }

  // ==================== UTILITIES ====================

  void resetToPrimaryServer() {
    _overrideBase = null;
    _usingFallback = false;
  }

  void switchToFallbackServer() {
    if (_config.fallbackApiUrl != null) {
      _overrideBase = _config.fallbackApiUrl;
      _usingFallback = true;
    }
  }

  Future<bool> testConnection() => checkServerHealth();

  void updateConfig(ApiConfig newConfig) {
    _config = newConfig;
    _overrideBase = null;
    _usingFallback = false;
  }

  void dispose() => _http.close();

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String sessionToken,
    required Map<String, dynamic> profileData,
  }) async {
    final uri = Uri.parse('$baseUrl/api/accounts/profile/$userId/'); // adjust endpoint if needed
    final headers = {
      'Content-Type': 'application/json',
      ..._headers,
    };
    if (sessionToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $sessionToken';
    }

    final resp = await _http.patch(
      uri,
      headers: headers,
      body: jsonEncode(profileData),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      logger.warning('Profile update failed (${resp.statusCode}): ${resp.body}');
      throw Exception('Failed to update profile: ${resp.statusCode}');
    }
  }
}