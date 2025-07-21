// Backend communication

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/goal.dart';
import '../models/budget.dart';

class ApiClient {
  // Enhanced base URL configuration for all platforms with USB debugging support
  // Server health check result
  static Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Server health check timed out'),
      );

      if (response.statusCode == 200) {
        return {
          'isConnected': true,
          'canCreateProfile': true,
          'message': 'Server is healthy'
        };
      } else {
        return {
          'isConnected': true,
          'canCreateProfile': false,
          'message': 'Server is experiencing issues'
        };
      }
    } on SocketException catch (_) {
      return {
        'isConnected': false,
        'canCreateProfile': false,
        'message': 'No internet connection'
      };
    } on TimeoutException catch (_) {
      return {
        'isConnected': false,
        'canCreateProfile': false,
        'message': 'Server is not responding'
      };
    } catch (e) {
      return {
        'isConnected': false,
        'canCreateProfile': false,
        'message': 'Unable to reach server'
      };
    }
  }

  // Profile creation pre-check
  static Future<Map<String, dynamic>> validateProfileCreation({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/profiles/validate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Profile validation timed out'),
      );

      if (response.statusCode == 200) {
        return {
          'canCreate': true,
          'message': 'Profile can be created'
        };
      } else {
        final data = json.decode(response.body);
        return {
          'canCreate': false,
          'message': data['message'] ?? 'Unable to create profile'
        };
      }
    } catch (e) {
      return {
        'canCreate': false,
        'message': 'Server error: Unable to validate profile creation'
      };
    }
  }

  static String get _baseUrl {
    final String url;
    
    if (kIsWeb) {
      // Web platform uses localhost directly
      url = "http://127.0.0.1:8000/api";
    } else {
      // Mobile platforms - Dynamic configuration for development
      if (kDebugMode) {
        // Check if running on physical device vs emulator
        if (Platform.isAndroid) {
          // For physical device via USB debugging
          url = "http://192.168.100.6:8002/api";
        } else {
          // For Android emulator
          url = "http://10.0.2.2:8000/api";
        }
      } else {
        // Production - using ngrok tunnel for real device access
        // ngrok URL: https://7a9a-41-209-9-54.ngrok-free.app
        url = "https://7a9a-41-209-9-54.ngrok-free.app/api";
      }
    }

    if (kDebugMode) {
      final platform = kIsWeb ? "Web" : (Platform.isAndroid ? "Android" : "iOS");
      final deviceType = kDebugMode && !kIsWeb ? 
        (Platform.isAndroid ? "Physical Device (USB)" : "Simulator") : "Production";
      print('🔗 API_CLIENT: Using base URL: $url');
      print('🔗 API_CLIENT: Platform: $platform, Mode: $deviceType');
    }

    return url;
  }

  // Debug method to get current base URL
  static String getBaseUrl() {
    final url = _baseUrl;
    if (kDebugMode) {
      print('ApiClient: Current base URL: $url');
    }
    return url;
  }

  // Development helper: Get different server URLs for testing
  static Map<String, String> getServerOptions() {
    return {
      'usb_debug': 'http://192.168.100.6:8002/api',
      'emulator': 'http://10.0.2.2:8000/api',
      'localhost': 'http://127.0.0.1:8000/api',
      'ngrok': 'https://7a9a-41-209-9-54.ngrok-free.app/api',
    };
  }

  // Test connection to server
  static Future<bool> testConnection({String? customUrl}) async {
    try {
      final testUrl = customUrl ?? _baseUrl;
      final healthUrl = testUrl.replaceAll('/api', '/api/health/');
      
      if (kDebugMode) {
        print('🧪 API_CLIENT: Testing connection to: $healthUrl');
      }
      
      final response = await http.get(
        Uri.parse(healthUrl), 
        headers: _commonHeaders,
      ).timeout(const Duration(seconds: 5));
      
      final success = response.statusCode == 200;
      if (kDebugMode) {
        print('🧪 API_CLIENT: Connection test ${success ? "✅ SUCCESS" : "❌ FAILED"} - Status: ${response.statusCode}');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('🧪 API_CLIENT: Connection test ❌ FAILED - Error: $e');
      }
      return false;
    }
  }

  // Sync Transactions
  Future<Map<String, dynamic>> syncTransactions(
    String profileId,
    List<Transaction> transactions,
  ) async {
    final url = '$_baseUrl/sync/$profileId/';
    if (kDebugMode) {
      print('🔄 API_CLIENT: Syncing transactions to: $url');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: _commonHeaders,
      body: jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );

    if (kDebugMode) {
      print('🔄 API_CLIENT: Sync response - Status: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }

  // Calculate Repayment
  Future<double> calculateRepayment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/calculate-repayment/'),
      headers: _commonHeaders,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body)['total_repayment'];
  }

  // Common headers for all requests
  static Map<String, String> get _commonHeaders {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-App/1.0',
      'Cache-Control': 'no-cache',
    };
    
    // Add ngrok-specific headers only when using ngrok in production
    if (!kDebugMode) {
      headers['ngrok-skip-browser-warning'] = 'true';
    }
    
    return headers;
  }

  // Enhanced health check for connectivity with timeout and better error handling
  Future<bool> healthCheck() async {
    try {
      final url = '$_baseUrl/health/';
      if (kDebugMode) {
        print('🌐 API_CLIENT: Making health check request to: $url');
        print('🌐 API_CLIENT: Headers: $_commonHeaders');
      }

      final response = await http.get(
        Uri.parse(url), 
        headers: _commonHeaders,
      ).timeout(const Duration(seconds: 10)); // Increased timeout for USB debugging

      if (kDebugMode) {
        print('🌐 API_CLIENT: Health check response - Status: ${response.statusCode}, Body: ${response.body}');
        print('🌐 API_CLIENT: Response Headers: ${response.headers}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('🌐 API_CLIENT: Health check error: $e');
        // Suggest alternative configurations on failure
        print('🌐 API_CLIENT: Available server options: ${getServerOptions()}');
      }
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
      headers: _commonHeaders,
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
      headers: _commonHeaders,
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
      headers: _commonHeaders,
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
      headers: _commonHeaders,
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
      headers: _commonHeaders,
      body: jsonEncode(budgets.map((b) => b.toJson()).toList()),
    );
    return jsonDecode(response.body);
  }

  // Fetch updated data from backend
  Future<List<Transaction>> fetchTransactions(String profileId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profiles/$profileId/transactions/'),
      headers: _commonHeaders,
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
      headers: _commonHeaders,
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
      headers: _commonHeaders,
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
      headers: _commonHeaders,
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
      headers: _commonHeaders,
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
      headers: _commonHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Budget.fromJson(json)).toList();
    }
    return [];
  }

  // =============================================================================
  // ENHANCED PROFILE MANAGEMENT - EMAIL/PASSWORD AUTHENTICATION
  // =============================================================================  // Enhanced profile registration with password-based authentication
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
        headers: _commonHeaders,
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
        headers: _commonHeaders,
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
        headers: _commonHeaders,
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
        headers: _commonHeaders,
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
        headers: _commonHeaders,
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
        headers: _commonHeaders,
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
        headers: _commonHeaders,
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
        headers: _commonHeaders,
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
        headers: _commonHeaders,
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
  // LOAN CALCULATOR METHODS
  // =============================================================================

  /// Calculate loan payment using the comprehensive calculator
  Future<Map<String, dynamic>> calculateLoanPayment({
    required double principal,
    required double annualRate,
    required int termYears,
    required String interestType, // 'SIMPLE', 'COMPOUND', 'REDUCING', 'FLAT'
    required String
    paymentFrequency, // 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUALLY', 'ANNUALLY'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculators/loan/'),
        headers: _commonHeaders,
        body: jsonEncode({
          'principal': principal,
          'annual_rate': annualRate,
          'term_years': termYears,
          'interest_type': interestType,
          'payment_frequency': paymentFrequency,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to calculate loan payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error calculating loan payment: $e');
    }
  }

  /// Solve for interest rate given payment amount
  Future<Map<String, dynamic>> solveInterestRate({
    required double principal,
    required double payment,
    required int termYears,
    required String paymentFrequency, // 'MONTHLY', 'QUARTERLY', etc.
    double tolerance = 0.00001,
    int maxIterations = 100,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculators/interest-rate-solver/'),
        headers: _commonHeaders,
        body: jsonEncode({
          'principal': principal,
          'payment': payment,
          'term_years': termYears,
          'payment_frequency': paymentFrequency,
          'tolerance': tolerance,
          'max_iterations': maxIterations,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to solve interest rate: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error solving interest rate: $e');
    }
  }

  /// Generate complete amortization schedule
  Future<Map<String, dynamic>> generateAmortizationSchedule({
    required double principal,
    required double annualRate,
    required int termYears,
    required String paymentFrequency, // 'MONTHLY', 'QUARTERLY', etc.
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculators/amortization-schedule/'),
        headers: _commonHeaders,
        body: jsonEncode({
          'principal': principal,
          'annual_rate': annualRate,
          'term_years': termYears,
          'payment_frequency': paymentFrequency,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to generate amortization schedule: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error generating amortization schedule: $e');
    }
  }

  /// Calculate early payment savings
  Future<Map<String, dynamic>> calculateEarlyPaymentSavings({
    required double principal,
    required double annualRate,
    required int termYears,
    required double extraPayment,
    required String paymentFrequency, // 'MONTHLY', 'QUARTERLY', etc.
    required String extraPaymentType, // 'MONTHLY', 'ONE_TIME'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculators/early-payment/'),
        headers: _commonHeaders,
        body: jsonEncode({
          'principal': principal,
          'annual_rate': annualRate,
          'term_years': termYears,
          'extra_payment': extraPayment,
          'payment_frequency': paymentFrequency,
          'extra_payment_type': extraPaymentType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to calculate early payment savings: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error calculating early payment savings: $e');
    }
  }

  /// Calculate Return on Investment (ROI)
  Future<Map<String, dynamic>> calculateROI({
    required double initialInvestment,
    required double finalValue,
    double? timeYears,
  }) async {
    try {
      final body = {
        'initial_investment': initialInvestment,
        'final_value': finalValue,
      };

      if (timeYears != null) {
        body['time_years'] = timeYears;
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/calculators/roi/'),
        headers: _commonHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to calculate ROI: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error calculating ROI: $e');
    }
  }

  /// Calculate compound interest
  Future<Map<String, dynamic>> calculateCompoundInterest({
    required double principal,
    required double annualRate,
    required double timeYears,
    required String compoundingFrequency, // 'MONTHLY', 'QUARTERLY', etc.
    double additionalPayment = 0,
    String additionalFrequency = 'MONTHLY',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculators/compound-interest/'),
        headers: _commonHeaders,
        body: jsonEncode({
          'principal': principal,
          'annual_rate': annualRate,
          'time_years': timeYears,
          'compounding_frequency': compoundingFrequency,
          'additional_payment': additionalPayment,
          'additional_frequency': additionalFrequency,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to calculate compound interest: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error calculating compound interest: $e');
    }
  }

  /// Calculate portfolio metrics
  Future<Map<String, dynamic>> calculatePortfolioMetrics({
    required List<Map<String, double>> investments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculators/portfolio-metrics/'),
        headers: _commonHeaders,
        body: jsonEncode({'investments': investments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to calculate portfolio metrics: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error calculating portfolio metrics: $e');
    }
  }

  /// Assess investment risk profile
  Future<Map<String, dynamic>> assessRiskProfile({
    required List<int> answers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculators/risk-assessment/'),
        headers: _commonHeaders,
        body: jsonEncode({'answers': answers}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to assess risk profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error assessing risk profile: $e');
    }
  }

  // =============================================================================
}
