// Backend communication

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/goal.dart';
import '../models/budget.dart';

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

  // Verify Profile
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
}
