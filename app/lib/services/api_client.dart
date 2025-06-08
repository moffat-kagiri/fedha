// Backend communication

import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/goal.dart';
import '../models/budget.dart';

class ApiClient {
  // Platform-specific base URL configuration for cross-platform sync
  static String get _baseUrl {
    if (kIsWeb) {
      // Web platform uses localhost directly
      return "http://localhost:8000/api";
    } else {
      // Mobile platforms use emulator-specific localhost
      return "http://10.0.2.2:8000/api";
    }
  }

  // Sync Transactions
  Future<Map<String, dynamic>> syncTransactions(
    String profileId,
    List<Transaction> transactions,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/$profileId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );
    return jsonDecode(response.body);
  }

  // Calculate Repayment
  Future<double> calculateRepayment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/calculate-repayment/'),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body)['total_repayment'];
  }

  // Health check for connectivity
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health/'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get transactions from backend (used by sync service)
  Future<List<Transaction>> getTransactions(String profileId) async {
    return fetchTransactions(profileId);
  }

  // Sync Categories
  Future<Map<String, dynamic>> syncCategories(
    String profileId,
    List<Category> categories,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/$profileId/categories/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(categories.map((c) => c.toJson()).toList()),
    );
    return jsonDecode(response.body);
  }

  // Sync Clients
  Future<Map<String, dynamic>> syncClients(
    String profileId,
    List<Client> clients,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/$profileId/clients/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(clients.map((c) => c.toJson()).toList()),
    );
    return jsonDecode(response.body);
  }

  // Sync Invoices
  Future<Map<String, dynamic>> syncInvoices(
    String profileId,
    List<Invoice> invoices,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/$profileId/invoices/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(invoices.map((i) => i.toJson()).toList()),
    );
    return jsonDecode(response.body);
  }

  // Sync Goals
  Future<Map<String, dynamic>> syncGoals(
    String profileId,
    List<Goal> goals,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/$profileId/goals/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(goals.map((g) => g.toJson()).toList()),
    );
    return jsonDecode(response.body);
  }

  // Sync Budgets
  Future<Map<String, dynamic>> syncBudgets(
    String profileId,
    List<Budget> budgets,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/$profileId/budgets/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(budgets.map((b) => b.toJson()).toList()),
    );
    return jsonDecode(response.body);
  }

  // Fetch updated data from backend
  Future<List<Transaction>> fetchTransactions(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profiles/$profileId/transactions/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Category>> fetchCategories(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profiles/$profileId/categories/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Client>> fetchClients(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profiles/$profileId/clients/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Client.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Invoice>> fetchInvoices(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profiles/$profileId/invoices/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Invoice.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Goal>> fetchGoals(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profiles/$profileId/goals/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Goal.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Budget>> fetchBudgets(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profiles/$profileId/budgets/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Budget.fromJson(json)).toList();
    }
    return [];
  }

  // =============================================================================
  // ENHANCED PROFILE MANAGEMENT - EMAIL/PASSWORD AUTHENTICATION
  // =============================================================================
  // Enhanced profile registration with pin-based authentication
  Future<Map<String, dynamic>> createEnhancedProfile({
    required String name,
    required String profileType,
    required String pin,
    String? email,
    String baseCurrency = 'KES',
    String timezone = 'GMT+3',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/enhanced/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'profile_type': profileType,
          'pin': pin,
          'email': email,
          'base_currency': baseCurrency,
          'timezone': timezone,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create profile: \\${response.body}');
      }
    } catch (e) {
      throw Exception('Network error creating profile: $e');
    }
  }

  // Enhanced profile login with 8-digit user ID
  Future<Map<String, dynamic>> loginEnhancedProfile({
    required String userId,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/enhanced/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'pin': pin}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error during login: $e');
    }
  }

  // Download profile data for synchronization using email
  Future<Map<String, dynamic>> downloadProfileData(String email) async {
    // Changed from userId
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/enhanced/sync/?email=$email',
        ), // Changed from user_id
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Failed to download profile data',
        );
      }
    } catch (e) {
      throw Exception('Network error downloading profile: $e');
    }
  }

  // Upload profile data for synchronization using email
  Future<Map<String, dynamic>> uploadProfileData({
    required String email,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/enhanced/sync/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'profile_data': profileData,
        }), // Changed from user_id
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to upload profile data');
      }
    } catch (e) {
      throw Exception('Network error uploading profile: $e');
    }
  }

  // Validate if a profile exists (without authentication) using email
  Future<Map<String, dynamic>> validateProfile(String email) async {
    // Changed from userId
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/enhanced/validate/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}), // Changed from user_id
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to validate profile');
      }
    } catch (e) {
      throw Exception('Network error validating profile: $e');
    }
  }

  // Change password on server using email
  Future<Map<String, dynamic>> changePasswordOnServer({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/enhanced/change-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Network error changing password: $e');
    }
  }

  // =============================================================================
  // ENHANCED PROFILE CRUD OPERATIONS - EMAIL/PASSWORD BASED
  // =============================================================================

  // Get enhanced profile by email
  Future<Map<String, dynamic>> getEnhancedProfile({
    required String email,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/enhanced/profile/?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get profile');
      }
    } catch (e) {
      throw Exception('Network error getting profile: $e');
    }
  }

  // Update enhanced profile
  Future<Map<String, dynamic>> updateEnhancedProfile({
    required String email,
    String? name,
    String? newEmail,
    String? passwordHash,
    String? baseCurrency,
    String? timezone,
  }) async {
    try {
      final updateData = <String, dynamic>{'email': email};

      if (name != null) updateData['name'] = name;
      if (newEmail != null) updateData['new_email'] = newEmail;
      if (passwordHash != null) updateData['password_hash'] = passwordHash;
      if (baseCurrency != null) updateData['base_currency'] = baseCurrency;
      if (timezone != null) updateData['timezone'] = timezone;

      final response = await http.put(
        Uri.parse('$_baseUrl/enhanced/profile/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Network error updating profile: $e');
    }
  }

  // Delete enhanced profile
  Future<Map<String, dynamic>> deleteEnhancedProfile({
    required String email,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/enhanced/profile/?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete profile');
      }
    } catch (e) {
      throw Exception('Network error deleting profile: $e');
    }
  }

  // =============================================================================
}
