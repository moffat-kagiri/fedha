// Backend communication

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/profile.dart';
import '../utils/logger.dart';

/// API Client for handling all server communication
class ApiClient {
  final String _baseUrl;
  final http.Client _httpClient = http.Client();
  final Map<String, String> _commonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  final logger = AppLogger.getLogger('ApiClient');
  
  // Constructor with configurable base URL
  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? 'https://api.fedha.app/v1';
  
  // Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/health'),
        headers: _commonHeaders,
      );
      return response.statusCode == 200;
    } catch (e) {
      logger.warning('Connection test failed: $e');
      return false;
    }
  }
  
  // Create an enhanced profile with more options
  Future<Map<String, dynamic>> createEnhancedProfile({
    required String email,
    required String name,
    required String pin,
    String? phoneNumber,
    String profileType = 'personal',
    String? deviceId,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final body = jsonEncode({
        'email': email,
        'name': name,
        'pin': pin,
        'phone_number': phoneNumber,
        'profile_type': profileType,
        'device_id': deviceId,
        'preferences': preferences ?? {},
      });
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/profiles/enhanced'),
        headers: _commonHeaders,
        body: body,
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw HttpException('Failed to create profile: ${response.statusCode}');
      }
    } catch (e) {
      logger.severe('Enhanced profile creation failed: $e');
      return {'error': e.toString(), 'success': false};
    }
  }
  
  // Check server connection
  Future<bool> checkServerConnection() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/health'),
        headers: _commonHeaders,
      );
      return response.statusCode == 200;
    } catch (e) {
      logger.warning('Server connection check failed: $e');
      return false;
    }
  }
  
  // Instance method for checking server health
  Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/health'),
        headers: _commonHeaders,
      );
      
      if (response.statusCode == 200) {
        return {
          'isConnected': true,
          'canCreateProfile': true,
          'message': 'Server is online'
        };
      } else {
        return {
          'isConnected': false,
          'canCreateProfile': false,
          'message': 'Server is experiencing issues'
        };
      }
    } catch (e) {
      return {
        'isConnected': false,
        'canCreateProfile': false,
        'message': 'Unable to connect to server'
      };
    }
  }
  
  // Instance method for validating profile creation
  Future<Map<String, dynamic>> validateProfileCreation({
    required String email,
    String? phoneNumber,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/profiles/validate'),
        headers: _commonHeaders,
        body: jsonEncode({
          'email': email,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'canCreate': data['available'] ?? true,
          'message': data['message'] ?? 'Email is available'
        };
      } else if (response.statusCode == 409) {
        return {
          'canCreate': false,
          'message': 'Email already registered'
        };
      } else {
        return {
          'canCreate': false,
          'message': 'Unable to validate email'
        };
      }
    } catch (e) {
      return {
        'canCreate': false,
        'message': 'Error checking email availability'
      };
    }
  }
  
  // Invalidate a session token on the server
  Future<bool> invalidateSession({
    required String userId,
    required String sessionToken,
    String? deviceId,
  }) async {
    try {
      final body = jsonEncode({
        'user_id': userId,
        'session_token': sessionToken,
        'device_id': deviceId,
      });
      
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _commonHeaders,
        body: body,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      logger.warning('Failed to invalidate session: $e');
      return false;
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _commonHeaders,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Login failed with status ${response.statusCode}');
        return {'error': 'Invalid credentials', 'code': response.statusCode};
      }
    } catch (e) {
      logger.severe('Login error: $e');
      return {'error': e.toString()};
    }
  }
  
  // Create account
  Future<Map<String, dynamic>> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? deviceId,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _commonHeaders,
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'deviceId': deviceId,
        }),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        logger.warning('Account creation failed with status ${response.statusCode}');
        return {'error': 'Failed to create account', 'code': response.statusCode};
      }
    } catch (e) {
      logger.severe('Account creation error: $e');
      return {'error': e.toString()};
    }
  }
  
  // Get user profile
  Future<Profile?> getProfile({
    required String userId,
    required String sessionToken,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/users/$userId/profile'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $sessionToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Profile.fromJson(data);
      } else {
        logger.warning('Get profile failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.severe('Get profile error: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String sessionToken,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/users/$userId/profile'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $sessionToken',
        },
        body: json.encode(profileData),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Profile update failed with status ${response.statusCode}');
        return {'error': 'Failed to update profile'};
      }
    } catch (e) {
      logger.severe('Error updating profile: $e');
      return {'error': e.toString()};
    }
  }
  
  // Change password
  Future<Map<String, dynamic>> updatePassword({
    required String userId,
    required String sessionToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/users/$userId/password'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $sessionToken',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Password update failed with status ${response.statusCode}');
        return {'error': 'Failed to update password'};
      }
    } catch (e) {
      logger.severe('Error updating password: $e');
      return {'error': e.toString()};
    }
  }
  
  // Request password reset
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: _commonHeaders,
        body: json.encode({
          'email': email,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Password reset request failed with status ${response.statusCode}');
        return {'error': 'Failed to request password reset'};
      }
    } catch (e) {
      logger.severe('Error requesting password reset: $e');
      return {'error': e.toString()};
    }
  }
  
  // Get transactions for a user
  Future<List<Transaction>> getTransactions({
    required String profileId, 
    required String sessionToken,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/transactions?profileId=$profileId'),
        headers: {
          ..._commonHeaders, 
          'Authorization': 'Bearer $sessionToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> transactionsJson = json.decode(response.body);
        return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
      } else {
        logger.warning('Getting transactions failed with status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logger.severe('Error getting transactions: $e');
      return [];
    }
  }
  
  // Assess risk profile for investments
  Future<Map<String, dynamic>> assessRiskProfile({
    required String userId,
    required String sessionToken,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/users/$userId/risk-profile'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $sessionToken',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Risk profile assessment failed with status ${response.statusCode}');
        return {'error': 'Failed to assess risk profile', 'code': response.statusCode};
      }
    } catch (e) {
      logger.severe('Error assessing risk profile: $e');
      return {'error': e.toString()};
    }
  }

  // Sync offline transactions with server
  Future<Map<String, dynamic>> syncOfflineTransactions({
    required String userId,
    required String sessionToken,
    required List<Transaction> transactions,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sync/transactions'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $sessionToken',
        },
        body: json.encode({
          'userId': userId,
          'transactions': transactions.map((t) => t.toJson()).toList(),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Transaction sync failed with status ${response.statusCode}');
        return {'error': 'Failed to sync transactions', 'code': response.statusCode};
      }
    } catch (e) {
      logger.severe('Error syncing transactions: $e');
      return {'error': e.toString()};
    }
  }

  // Get user goals
  Future<List<Goal>> fetchUserGoals({
    required String userId,
    required String sessionToken,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/users/$userId/goals'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $sessionToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> goalsJson = json.decode(response.body);
        return goalsJson.map((json) => Goal.fromJson(json)).toList();
      } else {
        logger.warning('Fetching goals failed with status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logger.severe('Error fetching goals: $e');
      return [];
    }
  }

  // Get budget summary
  Future<Map<String, dynamic>> fetchBudgetSummary({
    required String userId,
    required String sessionToken,
  }) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/users/$userId/budget-summary'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $sessionToken',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Fetching budget summary failed with status ${response.statusCode}');
        return {'error': 'Failed to fetch budget summary'};
      }
    } catch (e) {
      logger.severe('Error fetching budget summary: $e');
      return {'error': e.toString()};
    }
  }

  // Refresh auth token
  Future<Map<String, dynamic>> refreshToken({
    required String userId,
    required String refreshToken,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: _commonHeaders,
        body: json.encode({
          'userId': userId,
          'refreshToken': refreshToken,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Token refresh failed with status ${response.statusCode}');
        return {'error': 'Failed to refresh token'};
      }
    } catch (e) {
      logger.severe('Error refreshing token: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Synchronize transactions with the server
  Future<Map<String, dynamic>> syncTransactions(
    String profileId, 
    List<Transaction> transactions,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sync/transactions'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $profileId', // Assuming profileId is used as token
        },
        body: json.encode({
          'transactions': transactions.map((t) => t.toJson()).toList(),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Sync transactions failed with status ${response.statusCode}');
        return {'error': 'Failed to sync transactions'};
      }
    } catch (e) {
      logger.severe('Error syncing transactions: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Synchronize categories with the server
  Future<Map<String, dynamic>> syncCategories(
    String profileId, 
    List<dynamic> categories,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sync/categories'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $profileId',
        },
        body: json.encode({
          'categories': categories.map((c) => c.toJson()).toList(),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Sync categories failed with status ${response.statusCode}');
        return {'error': 'Failed to sync categories'};
      }
    } catch (e) {
      logger.severe('Error syncing categories: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Synchronize goals with the server
  Future<Map<String, dynamic>> syncGoals(
    String profileId, 
    List<dynamic> goals,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sync/goals'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $profileId',
        },
        body: json.encode({
          'goals': goals.map((g) => g.toJson()).toList(),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Sync goals failed with status ${response.statusCode}');
        return {'error': 'Failed to sync goals'};
      }
    } catch (e) {
      logger.severe('Error syncing goals: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Synchronize budgets with the server
  Future<Map<String, dynamic>> syncBudgets(
    String profileId, 
    List<dynamic> budgets,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sync/budgets'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $profileId',
        },
        body: json.encode({
          'budgets': budgets.map((b) => b.toJson()).toList(),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Sync budgets failed with status ${response.statusCode}');
        return {'error': 'Failed to sync budgets'};
      }
    } catch (e) {
      logger.severe('Error syncing budgets: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Synchronize clients with the server
  Future<Map<String, dynamic>> syncClients(
    String profileId, 
    List<dynamic> clients,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sync/clients'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $profileId',
        },
        body: json.encode({
          'clients': clients.map((c) => c.toJson()).toList(),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Sync clients failed with status ${response.statusCode}');
        return {'error': 'Failed to sync clients'};
      }
    } catch (e) {
      logger.severe('Error syncing clients: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Synchronize invoices with the server
  Future<Map<String, dynamic>> syncInvoices(
    String profileId, 
    List<dynamic> invoices,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/sync/invoices'),
        headers: {
          ..._commonHeaders,
          'Authorization': 'Bearer $profileId',
        },
        body: json.encode({
          'invoices': invoices.map((i) => i.toJson()).toList(),
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.warning('Sync invoices failed with status ${response.statusCode}');
        return {'error': 'Failed to sync invoices'};
      }
    } catch (e) {
      logger.severe('Error syncing invoices: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Server health check
  Future<bool> healthCheck() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/health'),
        headers: _commonHeaders,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      logger.severe('Error checking server health: $e');
      return false;
    }
  }
}
