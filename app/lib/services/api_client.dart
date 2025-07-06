// Backend communication

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class ApiClient {
  static const String _baseUrl =
      "http://10.0.2.2:8000/api"; // Android emulator localhost

  // Create Profile
  Future<Map<String, dynamic>> createProfile({
    required String profileId,
    required bool isBusiness,
    required String pinHash,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/profiles/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': profileId,
        'is_business': isBusiness,
        'pin_hash': pinHash,
      }),
    );
    return jsonDecode(response.body);
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

  Future<Map<String, dynamic>> verifyProfile({
    required String profileId,
    required String pinHash,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/profiles/verify/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': profileId, 'pin_hash': pinHash}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to verify profile');
    }

    return jsonDecode(response.body);
  }

  /// Get transactions from server
  Future<List<Transaction>> getTransactions(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/transactions/$profileId/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get transactions');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Transaction.fromJson(json)).toList();
  }

  /// Check if server is reachable
  Future<void> healthCheck() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Server health check failed');
    }
  }

  /// Enhanced profile methods
  Future<Map<String, dynamic>> createEnhancedProfile({
    required String profileId,
    required Map<String, dynamic> profileData,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/profiles/enhanced/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': profileId, ...profileData}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create enhanced profile');
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateEnhancedProfile({
    required String profileId,
    required Map<String, dynamic> profileData,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/profiles/enhanced/$profileId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update enhanced profile');
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getEnhancedProfile(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profiles/enhanced/$profileId/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get enhanced profile');
    }

    return jsonDecode(response.body);
  }

  Future<void> deleteEnhancedProfile(String profileId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/profiles/enhanced/$profileId/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete enhanced profile');
    }
  }

  /// Get base URL for external use
  String getBaseUrl() {
    return _baseUrl;
  }

  /// Sync goals with server
  Future<Map<String, dynamic>> syncGoals(
    String profileId,
    List<Map<String, dynamic>> goals,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/goals/$profileId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(goals),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync goals');
    }

    return jsonDecode(response.body);
  }

  /// Sync budgets with server
  Future<Map<String, dynamic>> syncBudgets(
    String profileId,
    List<Map<String, dynamic>> budgets,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/budgets/$profileId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(budgets),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync budgets');
    }

    return jsonDecode(response.body);
  }
}
