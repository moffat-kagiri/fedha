// Stub services for missing functionality

import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'offline_data_service.dart';
import '../data/app_database.dart';
import '../models/enums.dart';

class TextRecognitionService {
  final OfflineDataService _offlineService;
  
  TextRecognitionService(this._offlineService);
  
  Future<String?> extractTextFromImage(String imagePath) async {
    // Placeholder
    return null;
  }
}

class CSVUploadService {
  final OfflineDataService _offlineService;
  
  CSVUploadService(this._offlineService);
  
  Future<List<Map<String, dynamic>>> parseCSV(String filePath) async {
    // Placeholder
    return [];
  }
}

class SmsTransactionExtractor {
  final OfflineDataService _offlineService;
  
  SmsTransactionExtractor(this._offlineService);
  
  Map<String, dynamic>? extractTransactionFromSms(String smsText) {
    // Placeholder
    return null;
  }
}

class SmsListenerService {
  final OfflineDataService _offlineService;
  final SmsTransactionExtractor _extractor;
  
  SmsListenerService(this._offlineService, this._extractor);
  
  Future<void> startListening() async {
    // Placeholder
  }
  
  Future<void> stopListening() async {
    // Placeholder
  }

  void setCurrentProfile(String profileId) {
    // Placeholder
  }
}

class GoalTransactionService {
  final OfflineDataService _offlineService;
  
  GoalTransactionService(this._offlineService);
  
  Future<void> createSavingsTransaction(int goalId, double amount) async {
    await _offlineService.saveTransaction(
      TransactionsCompanion.insert(
        amountMinor: amount,
        isExpense: false,
        date: DateTime.now(),
        profileId: 1, // Default profile
        categoryId: goalId.toString(),
        description: 'Goal Savings Transaction',
        currency: 'KES',
        rawSms: const Value.absent(),
      )
    );
  }

  Future<List<Goal>> getSuggestedGoals() async {
    // Return the user's active goals from the DB
    final goals = await _offlineService.getAllGoals();
    return goals.where((goal) => !goal.completed).toList();
  }

  Future<Map<String, dynamic>> getGoalProgressSummary(int goalId) async {
    final goal = await _offlineService.getGoal(goalId);
    if (goal == null) return {'progress': 0.0};
    
    // Get all transactions for this goal
    final transactions = await _offlineService.getTransactions();
    final goalTransactions = transactions.where((tx) => 
        !tx.isExpense && tx.categoryId == goalId.toString()).toList();
    
    // Calculate progress
    final totalSaved = goalTransactions.fold<double>(
        0, (sum, tx) => sum + tx.amountMinor);
    final targetAmount = goal.targetMinor;
        
    return {
      'goal': goal,
      'progress': targetAmount > 0 ? (totalSaved / targetAmount) : 0.0,
      'totalSaved': totalSaved / 100.0, // Convert minor units to major
      'transactions': transactions,
    };
  }
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();
  
  Future<void> initialize() async {
    // Placeholder
  }
  
  Future<void> showNotification(String title, String body) async {
    // Placeholder
  }
}

class ThemeService {
  dynamic getLightTheme() {
    // Placeholder
    return null;
  }
  
  dynamic getDarkTheme() {
    // Placeholder  
    return null;
  }
  
  dynamic get themeMode {
    // Placeholder
    return null;
  }
  
  Future<void> initialize() async {
    // Placeholder
  }
}

class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();
  
  NavigationService._();
  
  static dynamic get navigatorKey {
    // Placeholder
    return null;
  }
}

class SenderManagementService {
  static SenderManagementService? _instance;
  static SenderManagementService get instance => _instance ??= SenderManagementService._();
  
  SenderManagementService._();
}

class OfflineManager {
  Future<void> initialize() async {
    // Placeholder
  }
}

class BackgroundTransactionMonitor {
  final OfflineDataService _offlineService;
  final SmsTransactionExtractor _extractor;
  
  BackgroundTransactionMonitor(this._offlineService, this._extractor);
  
  Future<void> start() async {
    // Placeholder
  }

  Future<void> initialize() async {
    // Placeholder
  }
}

class GoogleAuthService {
  static GoogleAuthService? _instance;
  static GoogleAuthService get instance => _instance ??= GoogleAuthService._();
  
  GoogleAuthService._();

  Future<bool> saveCredentialsToGoogle({required String email, required String name}) async {
    // Placeholder
    return false;
  }

  Future<void> clearSavedCredentials() async {
    // Placeholder
  }
}

class CurrencyService {
  static String formatCurrency(double amount, {String? currency}) {
    final curr = currency ?? 'KES';
    return '$curr ${amount.toStringAsFixed(2)}';
  }
}
