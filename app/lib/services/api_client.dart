// lib/services/api_client.dart - PostgreSQL Backend Compatible (REWRITTEN)
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
      
      // Ensure the transaction data matches serializer expectations
      final processedTransaction = Map<String, dynamic>.from(transaction);
      
      // ✅ FIX: Add is_synced field with default true (as per serializer extra_kwargs)
      if (!processedTransaction.containsKey('is_synced')) {
        processedTransaction['is_synced'] = true;
      }
      
      // ✅ FIX: Ensure date is in ISO 8601 format
      if (processedTransaction.containsKey('date') && 
          processedTransaction['date'] is! String) {
        // Convert DateTime to ISO string if needed
        processedTransaction['date'] = processedTransaction['date'].toString();
      }
      // ✅ FIX: Ensure amount is numeric and positive
      if (processedTransaction.containsKey('amount') && 
          processedTransaction['amount'] is String) {
        processedTransaction['amount'] = double.parse(processedTransaction['amount']);
      }
      // ✅ FIX: If using amount_minor, convert to amount
      if (processedTransaction.containsKey('amount_minor') && 
          !processedTransaction.containsKey('amount')) {
        final amountMinor = processedTransaction['amount_minor'];
        processedTransaction['amount'] = (amountMinor is int ? amountMinor : double.parse(amountMinor.toString())) / 100.0;
        processedTransaction.remove('amount_minor');
      }
      // ✅ FIX: Map 'transaction' to 'type' if needed
      if (processedTransaction.containsKey('transaction') && 
          !processedTransaction.containsKey('type')) {
        processedTransaction['type'] = processedTransaction['transaction'];
        processedTransaction.remove('transaction');
      }

      logger.info('Sending transaction data: $processedTransaction');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(processedTransaction),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Create transaction response: ${resp.statusCode} - ${resp.body}');
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Transaction created successfully');
        return data;
      }
      
      // Parse validation errors for debugging
      if (resp.statusCode == 400) {
        try {
          final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
          logger.warning('Transaction validation errors: $errorData');
        } catch (e) {
          logger.warning('Transaction error body: ${resp.body}');
        }
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
      
      // Ensure the goal data matches serializer expectations
      final processedGoal = Map<String, dynamic>.from(goal);
      
      // ✅ FIX: Add required goal_type field if missing (default to 'savings')
      if (!processedGoal.containsKey('goal_type')) {
        processedGoal['goal_type'] = 'savings';
        logger.info('Added default goal_type: savings');
      }
      
      // ✅ FIX: Map due_date to target_date (serializer will map due_date -> target_date)
      if (processedGoal.containsKey('due_date') && 
          !processedGoal.containsKey('target_date')) {
        // Keep due_date, serializer will handle mapping
        if (processedGoal['due_date'] is! String) {
          processedGoal['due_date'] = processedGoal['due_date'].toString();
        }
      }
      
      // ✅ FIX: Ensure target_amount is numeric
      if (processedGoal.containsKey('target_amount') && 
          processedGoal['target_amount'] is String) {
        processedGoal['target_amount'] = double.parse(processedGoal['target_amount']);
      }
      
      // ✅ FIX: Ensure current_amount is numeric with default 0
      if (!processedGoal.containsKey('current_amount')) {
        processedGoal['current_amount'] = 0.0;
      } else if (processedGoal['current_amount'] is String) {
        processedGoal['current_amount'] = double.parse(processedGoal['current_amount']);
      }
      
      // ✅ FIX: Add status field if missing (default to 'active')
      if (!processedGoal.containsKey('status')) {
        processedGoal['status'] = 'active';
      }
      
      // ✅ FIX: Add currency field if missing (default to 'KES')
      if (!processedGoal.containsKey('currency')) {
        processedGoal['currency'] = 'KES';
      }
      
      logger.info('Sending goal data: $processedGoal');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(processedGoal),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Create goal response: ${resp.statusCode} - ${resp.body}');
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Goal created successfully');
        return data;
      }
      
      // Parse validation errors for debugging
      if (resp.statusCode == 400) {
        try {
          final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
          logger.warning('Goal validation errors: $errorData');
        } catch (e) {
          logger.warning('Goal error body: ${resp.body}');
        }
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
    String? sessionToken,
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
      
      // Process each transaction to ensure it matches serializer expectations
      final processedTransactions = transactions.map((transaction) {
        final processed = Map<String, dynamic>.from(transaction);
        
        // Ensure each transaction has required fields
        if (!processed.containsKey('is_synced')) {
          processed['is_synced'] = true;
        }
        
        // Ensure amount_minor is integer
        if (processed.containsKey('amount_minor') && 
            processed['amount_minor'] is double) {
          processed['amount_minor'] = (processed['amount_minor'] as double).toInt();
        }
        
        return processed;
      }).toList();
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'profile_id': profileId,
              'transactions': processedTransactions,
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

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> budget) async {
    final url = Uri.parse(_config.getEndpoint('api/budgets/'));
    
    try {
      logger.info('POST ${url.toString()}');
      
      // ✅ Ensure required fields are present
      final processedBudget = Map<String, dynamic>.from(budget);
      
      // Validate required fields
      if (!processedBudget.containsKey('profile_id') || processedBudget['profile_id'] == null) {
        throw Exception('profile_id is required');
      }
      
      if (!processedBudget.containsKey('name') || processedBudget['name'] == null) {
        throw Exception('name is required');
      }
      
      // Convert date fields to ISO strings if needed
      if (processedBudget['startDate'] is! String) {
        processedBudget['startDate'] = processedBudget['startDate'].toString();
      }
      if (processedBudget['endDate'] is! String) {
        processedBudget['endDate'] = processedBudget['endDate'].toString();
      }
      
      // Map Flutter field names to backend field names
      final backendData = {
        'profile_id': processedBudget['profile_id'] ?? processedBudget['profileId'],
        'name': processedBudget['name'],
        'budget_amount': processedBudget['budgetAmount'] ?? processedBudget['budget_amount'],
        'spent_amount': processedBudget['spentAmount'] ?? processedBudget['spent_amount'] ?? 0.0,
        'category': processedBudget['category'] ?? '',
        'start_date': processedBudget['startDate'] ?? processedBudget['start_date'],
        'end_date': processedBudget['endDate'] ?? processedBudget['end_date'],
        'period': processedBudget['period'] ?? 'monthly',
        'is_active': processedBudget['isActive'] ?? processedBudget['is_active'] ?? true,
        'currency': processedBudget['currency'] ?? 'KES',
      };
      
      logger.info('Sending budget data: $backendData');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(backendData),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Create budget response: ${resp.statusCode} - ${resp.body}');
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Budget created successfully');
        return data;
      }
      
      // Log validation errors
      if (resp.statusCode == 400) {
        try {
          final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
          logger.warning('Budget validation errors: $errorData');
        } catch (e) {
          logger.warning('Budget error body: ${resp.body}');
        }
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
    required String goalId,
    required Map<String, dynamic> goal,
    String? sessionToken,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/goals/$goalId/'));
    
    try {
      logger.info('PUT ${url.toString()}');
      
      final headers = sessionToken != null 
          ? _getHeaders(customToken: sessionToken)
          : _headers;
      
      final processedGoal = Map<String, dynamic>.from(goal);
      
      // Ensure required fields are present for update
      if (!processedGoal.containsKey('goal_type')) {
        processedGoal['goal_type'] = 'savings';
      }
      
      logger.info('Updating goal with data: $processedGoal');
      
      final resp = await _http
          .put(
            url,
            headers: headers,
            body: jsonEncode(processedGoal),
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
    required String goalId,
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
      
      // Process each goal to ensure it matches serializer expectations
      final processedGoals = goals.map((goal) {
        final processed = Map<String, dynamic>.from(goal);
        
        // Ensure required fields
        if (!processed.containsKey('goal_type')) {
          processed['goal_type'] = 'savings';
        }
        
        if (!processed.containsKey('status')) {
          processed['status'] = 'active';
        }
        
        if (!processed.containsKey('currency')) {
          processed['currency'] = 'KES';
        }
        
        if (!processed.containsKey('current_amount')) {
          processed['current_amount'] = 0.0;
        }
        
        // Ensure numeric types
        if (processed.containsKey('target_amount') && 
            processed['target_amount'] is String) {
          processed['target_amount'] = double.parse(processed['target_amount']);
        }
        
        if (processed.containsKey('current_amount') && 
            processed['current_amount'] is String) {
          processed['current_amount'] = double.parse(processed['current_amount']);
        }
        
        return processed;
      }).toList();
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'profile_id': profileId,
              'goals': processedGoals,
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

  // ============================ LOANS =======================================
  /// Process loan data to match backend schema
  Map<String, dynamic> _processLoanData(Map<String, dynamic> loan) {
    final processedLoan = Map<String, dynamic>.from(loan);

    // ✅ FIX: Map 'principal_minor' to 'principal_amount' if needed
    if (processedLoan.containsKey('principal_minor') && 
        !processedLoan.containsKey('principal_amount')) {
      final minor = processedLoan['principal_minor'];
      processedLoan['principal_amount'] = 
          (minor is int ? minor : double.parse(minor.toString())) / 100.0;
      processedLoan.remove('principal_minor');
    }

    // ✅ FIX: Ensure interest_model is present (default to 'simple')
    if (!processedLoan.containsKey('interest_model')) {
      processedLoan['interest_model'] = 'simple';
    }

    // ✅ FIX: Remove 'status' field if it exists (not in backend model)
    processedLoan.remove('status');

    // ✅ FIX: Ensure numeric types are correct
    if (processedLoan.containsKey('principal_amount') && 
        processedLoan['principal_amount'] is String) {
      processedLoan['principal_amount'] = 
          double.parse(processedLoan['principal_amount']);
    }
    
    if (processedLoan.containsKey('interest_rate') && 
        processedLoan['interest_rate'] is String) {
      processedLoan['interest_rate'] = 
          double.parse(processedLoan['interest_rate']);
    }

    // ✅ FIX: Ensure dates are ISO strings
    if (processedLoan.containsKey('start_date') && 
        processedLoan['start_date'] is! String) {
      if (processedLoan['start_date'] is DateTime) {
        processedLoan['start_date'] = 
            (processedLoan['start_date'] as DateTime).toIso8601String();
      } else {
        processedLoan['start_date'] = processedLoan['start_date'].toString();
      }
    }
    
    if (processedLoan.containsKey('end_date') && 
        processedLoan['end_date'] is! String) {
      if (processedLoan['end_date'] is DateTime) {
        processedLoan['end_date'] = 
            (processedLoan['end_date'] as DateTime).toIso8601String();
      } else {
        processedLoan['end_date'] = processedLoan['end_date'].toString();
      }
    }

    // ✅ FIX: Ensure profile_id exists (required field)
    if (!processedLoan.containsKey('profile_id') && 
        processedLoan.containsKey('profileId')) {
      processedLoan['profile_id'] = processedLoan['profileId'];
      processedLoan.remove('profileId');
    }

    return processedLoan;
  }

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

      logger.info('GET ${url.toString()}');
      final resp = await _http
          .get(url, headers: headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        logger.info('Got ${data.length} active loans');
        return data as List<dynamic>;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Active loans request unauthorized');
        clearAuthToken();
      }
      
      logger.warning('Get active loans failed: ${resp.statusCode}');
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
      // ✅ Process loan data to match backend schema
      final processedLoan = _processLoanData(loan);
      
      logger.info('POST ${url.toString()}');
      logger.info('Sending loan data: $processedLoan');
      
      final resp = await _http
          .post(url, headers: _headers, body: jsonEncode(processedLoan))
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Create loan response: ${resp.statusCode} - ${resp.body}');
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Loan created successfully');
        return data;
      }
      
      // Log validation errors
      if (resp.statusCode == 400) {
        try {
          final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
          logger.warning('Loan validation errors: $errorData');
        } catch (e) {
          logger.warning('Loan error body: ${resp.body}');
        }
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
      };
    } catch (e) {
      logger.severe('Create loan error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateLoan({
    required String loanId,
    required Map<String, dynamic> loan,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/invoicing/loans/$loanId/'));

    try {
      // ✅ Process loan data to match backend schema
      final processedLoan = _processLoanData(loan);
      
      logger.info('PUT ${url.toString()}');
      logger.info('Updating loan with data: $processedLoan');
      
      final resp = await _http
          .put(url, headers: _headers, body: jsonEncode(processedLoan))
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      logger.info('Update loan response: ${resp.statusCode} - ${resp.body}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Loan updated successfully');
        return data;
      }
      
      // Log validation errors
      if (resp.statusCode == 400) {
        try {
          final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
          logger.warning('Loan update validation errors: $errorData');
        } catch (e) {
          logger.warning('Loan update error body: ${resp.body}');
        }
      }
      
      return {
        'success': false,
        'status': resp.statusCode,
        'body': resp.body,
      };
    } catch (e) {
      logger.severe('Update loan error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> deleteLoan({
    required String loanId,
  }) async {
    final url = Uri.parse(_config.getEndpoint('api/invoicing/loans/$loanId/'));

    try {
      logger.info('DELETE ${url.toString()}');
      
      final resp = await _http
          .delete(url, headers: _headers)
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      final success = resp.statusCode == 204 || resp.statusCode == 200;
      logger.info('Delete loan: ${success ? "✅ OK" : "❌ FAIL"} (${resp.statusCode})');
      return success;
    } catch (e) {
      logger.warning('Delete loan failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> syncLoans(
    String profileId,
    List<dynamic> loans,
  ) async {
    final url = Uri.parse(_config.getEndpoint('api/invoicing/loans/bulk_sync/'));

    try {
      logger.info('POST ${url.toString()} - ${loans.length} loans');
      
      // Process each loan to match backend schema
      final processedLoans = loans.map((loan) {
        final processed = _processLoanData(loan);
        return processed;
      }).toList();
      
      final body = {
        'profile_id': profileId,
        'loans': processedLoans,
      };
      
      logger.info('Syncing loans with data: $body');
      
      final resp = await _http
          .post(
            url,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: _config.timeoutSeconds));
      
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        logger.info('✅ Loans sync complete');
        return data;
      }
      
      if (resp.statusCode == 401) {
        logger.warning('Loans sync unauthorized - token may be expired');
        clearAuthToken();
      }
      
      logger.warning('Loans sync failed: ${resp.statusCode} - ${resp.body}');
      return {'success': false, 'status': resp.statusCode};
    } catch (e) {
      logger.severe('Sync loans error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Prepares loan data for API submission
  static Map<String, dynamic> prepareLoanData({
    required String profileId,
    required String name,
    required double principalAmount,  // Major units (KES 100.00)
    required double interestRate,     // Percentage (5.5 for 5.5%)
    required String interestModel,    // 'simple', 'compound', 'reducingBalance'
    required DateTime startDate,
    required DateTime endDate,
    String currency = 'KES',
    bool isSynced = true,
    String? description,
  }) {
    final data = <String, dynamic>{
      'profile_id': profileId,
      'name': name,
      'principal_amount': principalAmount,
      'interest_rate': interestRate,
      'interest_model': interestModel,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'currency': currency,
      'is_synced': isSynced,
    };

    if (description != null && description.isNotEmpty) {
      data['description'] = description;
    }

    return data;
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

  // ==================== DATA PREPARATION HELPERS ====================
  /// Prepares transaction data for API submission
  static Map<String, dynamic> prepareTransactionData({
    required String profileId,
    required double amount,  // Not amount_minor
    required String type,    // Not 'transaction'
    required String description,
    String? category,
    String? goalId,
    DateTime? date,
    bool isExpense = false,
    String currency = 'KES',
    bool isSynced = true,
    String status = 'completed',  // NEW
    String? paymentMethod,        // NEW
    String? reference,            // NEW
    String? recipient,            // NEW
    String? merchantName,         // NEW
    String? merchantCategory,     // NEW
    String? tags,                 // NEW
    bool isRecurring = false,     // NEW
  }) {
    final data = <String, dynamic>{
      'profile_id': profileId,
      'amount': amount,          // Changed from amount_minor
      'type': type,              // Changed from 'transaction'
      'description': description,
      'category': category ?? '',
      'currency': currency,
      'is_synced': isSynced,
      'is_expense': isExpense,
      'status': status,          // Added
      'is_recurring': isRecurring, // Added
    };

    if (goalId != null) {
      data['goal_id'] = goalId;
    }

    if (date != null) {
      data['date'] = date.toIso8601String();  // FIXED: Use ISO format
    } else {
      data['date'] = DateTime.now().toIso8601String();
    }

    // Optional fields
    if (paymentMethod != null) data['payment_method'] = paymentMethod;
    if (reference != null) data['reference'] = reference;
    if (recipient != null) data['recipient'] = recipient;
    if (merchantName != null) data['merchant_name'] = merchantName;
    if (merchantCategory != null) data['merchant_category'] = merchantCategory;
    if (tags != null) data['tags'] = tags;

    return data;
  }

  /// Prepares goal data for API submission
  static Map<String, dynamic> prepareGoalData({
    required String profileId,
    required String name,
    required double targetAmount,
    String goalType = 'savings',
    String status = 'active',
    String? description,
    DateTime? dueDate,
    double currentAmount = 0.0,
    String currency = 'KES',
  }) {
    final data = <String, dynamic>{
      'profile_id': profileId,
      'name': name,
      'goal_type': goalType,
      'status': status,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'currency': currency,
    };

    if (description != null) {
      data['description'] = description;
    }

    if (dueDate != null) {
      data['due_date'] = dueDate.toIso8601String();
    }

    return data;
  }
}