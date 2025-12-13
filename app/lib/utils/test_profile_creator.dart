// lib/utils/test_profile_creator.dart
// Simple test profile creation utility aligned with Material 3 theme

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../models/profile.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

class TestProfileCreator {
  static const _uuid = Uuid();

  /// Static method to create both personal and business profiles
  static Future<Map<String, Profile?>> createBothProfiles() async {
    try {
      final authService = AuthService.instance;

      // Create personal profile via signup
      final personalSuccess = await authService.signup(
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe.${DateTime.now().millisecondsSinceEpoch}@test.fedha',
        password: 'TestPass123!',
      );

      final personalProfile = personalSuccess ? authService.currentProfile : null;

      // Create business profile via signup
      final businessSuccess = await authService.signup(
        firstName: 'Business',
        lastName: 'Account',
        email: 'business.${DateTime.now().millisecondsSinceEpoch}@test.fedha',
        password: 'TestPass123!',
      );

      final businessProfile = businessSuccess ? authService.currentProfile : null;

      if (kDebugMode) {
        print('[TestProfileCreator] Created profiles: Personal=$personalSuccess, Business=$businessSuccess');
      }

      return {
        'personal': personalProfile,
        'business': businessProfile,
      };
    } catch (e) {
      if (kDebugMode) {
        print('[TestProfileCreator] Error creating profiles: $e');
      }
      return {'personal': null, 'business': null};
    }
  }

  /// Static method to list all profiles (currently returns empty - profiles are managed by AuthService)
  static Future<List<Profile>> listAllProfiles() async {
    // Profiles are managed by AuthService singleton
    // This is a placeholder for future profile listing functionality
    if (kDebugMode) {
      print('[TestProfileCreator] Listed profiles (stub)');
    }
    return [];
  }

  /// Instance constructor for advanced operations
  final AuthService authService;
  final OfflineDataService offlineDataService;

  TestProfileCreator({
    required this.authService,
    required this.offlineDataService,
  });

  /// Create a single test profile (instance method)
  Future<Profile?> createTestProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final testEmail = email ?? 'test.${DateTime.now().millisecondsSinceEpoch}@test.fedha';
      final testFirstName = firstName ?? 'Test';
      final testLastName = lastName ?? 'User';

      if (kDebugMode) {
        print('[TestProfileCreator] Creating test profile: $testEmail');
      }

      final success = await authService.signup(
        firstName: testFirstName,
        lastName: testLastName,
        email: testEmail,
        password: 'TestPass123!',
      );

      if (!success) {
        if (kDebugMode) {
          print('[TestProfileCreator] Failed to create test profile');
        }
        return null;
      }

      final profile = authService.currentProfile;
      if (kDebugMode) {
        print('[TestProfileCreator] Created profile: ${profile?.name}');
      }

      return profile;
    } catch (e) {
      if (kDebugMode) {
        print('[TestProfileCreator] Error creating test profile: $e');
      }
      return null;
    }
  }

  /// Load sample transactions for a profile
  Future<void> loadSampleTransactions(String profileId) async {
    try {
      if (kDebugMode) {
        print('[TestProfileCreator] Loading sample transactions for profile: $profileId');
      }

      final transactions = _generateSampleTransactions(profileId);
      
      for (final txn in transactions) {
        await offlineDataService.saveTransaction(txn);
      }

      if (kDebugMode) {
        print('[TestProfileCreator] Loaded ${transactions.length} sample transactions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TestProfileCreator] Error loading transactions: $e');
      }
    }
  }

  /// Generate sample transactions with valid enum values
  List<Transaction> _generateSampleTransactions(String profileId) {
    final now = DateTime.now();
    
    return [
      // Salary income
      Transaction(
        amount: 50000.0,
        type: TransactionType.income,
        categoryId: TransactionCategory.salary.toString().split('.').last,
        category: TransactionCategory.salary,
        date: now.subtract(const Duration(days: 30)),
        description: 'Monthly Salary',
        profileId: profileId,
        isSynced: false,
      ),
      // Housing expense
      Transaction(
        amount: 15000.0,
        type: TransactionType.expense,
        categoryId: TransactionCategory.shopping.toString().split('.').last,
        category: TransactionCategory.shopping,
        date: now.subtract(const Duration(days: 25)),
        description: 'Rent Payment',
        profileId: profileId,
        isSynced: false,
      ),
      // Food expense
      Transaction(
        amount: 3500.0,
        type: TransactionType.expense,
        categoryId: TransactionCategory.food.toString().split('.').last,
        category: TransactionCategory.food,
        date: now.subtract(const Duration(days: 15)),
        description: 'Weekly Groceries',
        profileId: profileId,
        isSynced: false,
      ),
      // Transport
      Transaction(
        amount: 2000.0,
        type: TransactionType.expense,
        categoryId: TransactionCategory.transport.toString().split('.').last,
        category: TransactionCategory.transport,
        date: now.subtract(const Duration(days: 10)),
        description: 'Fuel & Transport',
        profileId: profileId,
        isSynced: false,
      ),
      // Utilities
      Transaction(
        amount: 1500.0,
        type: TransactionType.expense,
        categoryId: TransactionCategory.utilities.toString().split('.').last,
        category: TransactionCategory.utilities,
        date: now.subtract(const Duration(days: 7)),
        description: 'Electricity Bill',
        profileId: profileId,
        isSynced: false,
      ),
      // Savings
      Transaction(
        amount: 10000.0,
        type: TransactionType.savings,
        categoryId: TransactionCategory.emergencyFund.toString().split('.').last,
        category: TransactionCategory.emergencyFund,
        date: now.subtract(const Duration(days: 3)),
        description: 'Emergency Fund Contribution',
        profileId: profileId,
        isSynced: false,
      ),
    ];
  }

  /// Delete all data for current profile (cleanup)
  Future<void> deleteTestProfile() async {
    try {
      final currentProfile = authService.currentProfile;
      if (currentProfile != null) {
        await authService.logout();
        if (kDebugMode) {
          print('[TestProfileCreator] Cleaned up profile: ${currentProfile.id}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TestProfileCreator] Error deleting profile: $e');
      }
    }
  }
}
