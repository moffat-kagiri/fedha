// lib/services/api_client.dart - PostgreSQL Backend Compatible
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
  bool get isAuthenticated => _headers.containsKey('Authorization');

  String get baseUrl {
    final host = _overrideBase ?? _config.primaryApiUrl;
    final scheme = _config.useSecureConnections ? 'https' : 'http';
    return '$scheme://$host';
  }

  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
    logger.info('✅ Auth token set (${token.length} chars)');
  }

  void clearAuthToken() {
    _headers.remove('Authorization');
    logger.info('Auth token cleared');
  }

  /// Get headers with optional custom token
  Map<String, String> _getHeaders({String? customToken}) {
    final headers = Map<String, String>.from(_headers);
    if (customToken != null) {
      headers['Authorization'] = 'Bearer $customToken';
    }
    return headers;
  }

  // ==================== HEALTH CHECK ====================

  Future<bool> checkServerHealth() async {
    try {
      logger.info('Checking server health: ${_config.healthCheckUrl}');
      final resp = await _http
          .get(Uri.parse(_config.healthCheckUrl), headers: _headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      final isHealthy = resp.statusCode == 200;
      logger.info('Server health: ${isHealthy ? "✅ OK" : "❌ FAIL"} (${resp.statusCode})');
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
        
        // Extract token
        final token = data['token'] as String?;
        
        if (token != null && token.isNotEmpty) {
          setAuthToken(token);
          logger.info('✅ Login successful, token received');
          
          return {
            'success': true,
            'token': token,
            'user': data['user'],
          };
        } else {
          logger.warning('⚠️ Login response missing token');
          return {
            'success': false,
            'error': 'Invalid response from server'
          };
        }
      }
      
      logger.warning('Login failed: ${resp.statusCode} - ${resp.body}');
      
      // Try to parse error message
      String errorMessage = 'Invalid email or password';
      try {
        final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
        errorMessage = errorData['error']?.toString() ?? 
                      errorData['detail']?.toString() ?? 
                      errorMessage;
      } catch (e) {
        // Use default error message
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
        'error': errorMessage
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
      body['phone_number'] = phone;
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
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        
        // Extract token
        final token = data['token'] as String?;
        
        if (token != null && token.isNotEmpty) {
          setAuthToken(token);
          logger.info('✅ Registration successful, token received');
        }
        
        return {
          'success': true,
          'status': resp.statusCode,
          'token': token,
          'user': data['user'],
        };
      }
      
      logger.warning('Registration failed: ${resp.statusCode} - ${resp.body}');
      
      // Try to parse error message
      String errorMessage = 'Registration failed';
      try {
        final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
        errorMessage = errorData['error']?.toString() ?? 
                      errorData['detail']?.toString() ?? 
                      errorData['email']?.toString() ?? 
                      errorMessage;
      } catch (e) {
        // Use default error message
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
        'error': errorMessage,
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
      
      final headers = _getHeaders(customToken: sessionToken);
      
      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Get profile response: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {
          'success': true,
          'profile': data,
        };
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Profile request unauthorized - token may be expired');
        clearAuthToken();
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
      
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;
      
      final resp = await _http
          .post(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      final ok = resp.statusCode == 200 || resp.statusCode == 204;
      
      if (ok && clearLocalToken) {
        clearAuthToken();
      }
      
      logger.info('Logout: ${ok ? "✅ OK" : "❌ FAIL"}');
      return ok;
    } catch (e) {
      logger.warning('Logout failed: $e');
      if (clearLocalToken) {
        clearAuthToken();
      }
      return false;
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transaction) async {
    final url = Uri.parse(_config.getEndpoint('api/transactions/'));
    
    try {
      logger.info('POST ${url.toString()}');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(transaction),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Create transaction response: ${resp.statusCode}');
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Transaction created successfully');
        return data;
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
      };
    } catch (e) {
      logger.severe('Create transaction error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== GOAL METHODS ====================

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> goal) async {
    final url = Uri.parse(_config.getEndpoint('api/goals/'));
    
    try {
      logger.info('POST ${url.toString()}');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(goal),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Create goal response: ${resp.statusCode}');
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Goal created successfully');
        return data;
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
      };
    } catch (e) {
      logger.severe('Create goal error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Update getTransactions method to be optional sessionToken
  Future<List<dynamic>> getTransactions({
    required String profileId,
    String? sessionToken, // Make this optional
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/transactions/?profile_id=$profileId'));
    
    try {
      logger.info('GET ${url.toString()}');
      
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;
      
      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Get transactions response: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return data as List<dynamic>;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Transactions request unauthorized');
        clearAuthToken();
      }
      
      return [];
    } catch (e) {
      logger.severe('Get transactions error: $e');
      return [];
    }
  }
  Future<Map<String, dynamic>> syncTransactions(
    String profileId,
    List<dynamic> transactions,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/transactions/bulk_sync/'));
    
    try {
      logger.info('POST ${url.toString()} - ${transactions.length} transactions');
      
      if (!isAuthenticated) {
        logger.warning('⚠️ No auth token for sync - request may fail');
      }
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'profile_id': profileId,
              'transactions': transactions,
            }),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Sync complete: ${data['created']} created, ${data['updated']} updated');
        return data;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Sync unauthorized - token may be expired');
        clearAuthToken();
      }
      
      logger.warning('Sync failed: ${resp.statusCode} - ${resp.body}');
      return {'success': false, 'status': resp.statusCode};
    } catch (e) {
      logger.severe('Sync transactions error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== BUDGETS ====================

  /// ✅ NEW: Get all budgets for a profile
  Future<List<dynamic>> getBudgets({
    required String profileId,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/budgets/?profile_id=$profileId'));
    
    try {
      logger.info('GET ${url.toString()}');
      
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;
      
      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Get budgets response: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return data as List<dynamic>;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Budgets request unauthorized');
        clearAuthToken();
      }
      
      return [];
    } catch (e) {
      logger.severe('Get budgets error: $e');
      return [];
    }
  }

  /// ✅ NEW: Create a new budget
  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> budget) async {
    final url = Uri.parse(_config.getEndpoint('api/budgets/'));
    
    try {
      logger.info('POST ${url.toString()}');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(budget),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Create budget response: ${resp.statusCode}');
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Budget created successfully');
        return data;
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
      };
    } catch (e) {
      logger.severe('Create budget error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> syncBudgets(
    String profileId,
    List<dynamic> budgets,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/budgets/bulk_sync/'));
    
    try {
      logger.info('POST ${url.toString()} - ${budgets.length} budgets');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'profile_id': profileId,
              'budgets': budgets,
            }),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Budget sync complete');
        return data;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Budget sync unauthorized');
        clearAuthToken();
      }
      
      return {'success': false, 'status': resp.statusCode};
    } catch (e) {
      logger.severe('Sync budgets error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== GOALS ====================

  Future<List<dynamic>> getGoals({
    required String profileId,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/goals/?profile_id=$profileId'));
    
    try {
      logger.info('GET ${url.toString()}');
      
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;
      
      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Get goals response: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        // DRF paginated response has 'results' field
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return data as List<dynamic>;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Goals request unauthorized');
        clearAuthToken();
      }
      
      logger.warning('Get goals failed: ${resp.statusCode}');
      return [];
    } catch (e) {
      logger.severe('Get goals error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateGoal({
    required int goalId,
    required Map<String, dynamic> goal,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/goals/$goalId/'));
    
    try {
      logger.info('PUT ${url.toString()}');
      
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;
      
      final resp = await _http
          .put(
            url,
            headers: headers,
            body: jsonEncode(goal),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Update goal response: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Goal updated successfully');
        return data;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Goal update unauthorized');
        clearAuthToken();
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
      };
    } catch (e) {
      logger.severe('Update goal error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> deleteGoal({
    required int goalId,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/goals/$goalId/'));
    
    try {
      logger.info('DELETE ${url.toString()}');
      
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;
      
      final resp = await _http
          .delete(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      final success = resp.statusCode == 204 || resp.statusCode == 200;
      logger.info('Delete goal: ${success ? "✅ OK" : "❌ FAIL"}');
      return success;
    } catch (e) {
      logger.warning('Delete goal failed: $e');
      return false;
    }
  }
  Future<Map<String, dynamic>> syncGoals(
    String profileId,
    List<dynamic> goals,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/goals/bulk_sync/'));
    
    try {
      logger.info('POST ${url.toString()} - ${goals.length} goals');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'profile_id': profileId,
              'goals': goals,
            }),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Goals sync complete');
        return data;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Goals sync unauthorized');
        clearAuthToken();
      }
      
      return {'success': false, 'status': resp.statusCode};
    } catch (e) {
      logger.severe('Sync goals error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== CATEGORIES ====================

  Future<Map<String, dynamic>> syncCategories(
    String profileId,
    List<dynamic> categories,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/transactions/categories/bulk_sync/'));
    
    try {
      logger.info('POST ${url.toString()} - ${categories.length} categories');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'profile_id': profileId,
              'categories': categories,
            }),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Categories sync complete');
        return data;
      }
      
      return {'success': false, 'status': resp.statusCode};
    } catch (e) {
      logger.severe('Sync categories error: $e');
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
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;
      
      if (!headers.containsKey('Authorization')) {
        logger.warning('⚠️ No Authorization header for loans request');
      }
      
      logger.info('GET ${url.toString()}');
      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));

      logger.info('Get loans response: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List<dynamic>;
        }
        return data as List<dynamic>;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Loans request unauthorized - token may be expired');
        clearAuthToken();
      }
      
      logger.warning('Get loans failed: ${resp.statusCode}');
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
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;

      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      }
      
      if (resp.statusCode == 401) {
        clearAuthToken();
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
      final resp = await _http
          .post(url, headers: _headers, body: jsonEncode(loan))
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
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
      final resp = await _http
          .put(url, headers: _headers, body: jsonEncode(loan))
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
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
      final resp = await _http
          .delete(url, headers: _headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      return resp.statusCode == 204 || resp.statusCode == 200;
    } catch (e) {
      logger.warning('Delete loan failed: $e');
      return false;
    }
  }

  // ==================== PROFILE UPDATES ====================

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String sessionToken,
    required Map<String, dynamic> profileData,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/profile/'));
    
    try {
      logger.info('PATCH ${url.toString()}');
      
      final headers = _getHeaders(customToken: sessionToken);
      
      final resp = await _http.patch(
        url,
        headers: headers,
        body: jsonEncode(profileData),
      ).timeout(Duration(seconds: _config.timeoutSeconds));

      logger.info('Update profile response: ${resp.statusCode}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Profile update unauthorized');
        clearAuthToken();
      }
      
      logger.warning('Profile update failed (${resp.statusCode}): ${resp.body}');
      throw Exception('Failed to update profile: ${resp.statusCode}');
    } catch (e) {
      logger.severe('Update profile error: $e');
      rethrow;
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
}