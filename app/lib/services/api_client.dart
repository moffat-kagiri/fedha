// Backend communication

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/goal.dart';
import '../models/budget.dart';
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
}
