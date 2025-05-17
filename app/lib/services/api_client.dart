// Backend communication

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class ApiClient {
  static const String _baseUrl = "http://10.0.2.2:8000/api"; // Android emulator localhost

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
      body: jsonEncode({
        'id': profileId,
        'pin_hash': pinHash,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to verify profile');
    }
    
    return jsonDecode(response.body);
  }
}