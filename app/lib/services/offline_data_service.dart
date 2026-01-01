// lib/services/offline_data_service.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:fedha/data/app_database.dart' as app_db;
import 'package:fedha/models/transaction.dart' as dom;
import 'package:fedha/models/goal.dart' as dom;
import 'package:fedha/models/loan.dart' as dom;
import 'package:fedha/models/enums.dart';
import 'package:fedha/models/category.dart' as dom;
import 'package:fedha/models/budget.dart' as dom;
import '../utils/logger.dart';
import 'transaction_event_service.dart';

class OfflineDataService {
  late final SharedPreferences _prefs;
  final app_db.AppDatabase _db;
  final _logger = AppLogger.getLogger('OfflineDataService');
  
  TransactionEventService? _eventService;

  OfflineDataService({app_db.AppDatabase? db}) : _db = db ?? app_db.AppDatabase();

  /// Initialize SharedPreferences instance
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void setEventService(TransactionEventService eventService) {
    _eventService = eventService;
    _logger.info('TransactionEventService linked to OfflineDataService');
  }

  bool get onboardingComplete =>
    _prefs.getBool('onboarding_complete') ?? false;
  set onboardingComplete(bool v) =>
    _prefs.setBool('onboarding_complete', v);

  bool get darkMode =>
    _prefs.getBool('dark_mode') ?? false;
  set darkMode(bool v) =>
    _prefs.setBool('dark_mode', v);

  /// Helper to convert UUID string to int for database storage
  int _profileIdToInt(String profileId) {
    final parsed = int.tryParse(profileId);
    if (parsed != null) return parsed;
    return profileId.hashCode.abs();
  }

  /// Helper to validate profile ID
  void _validateProfileId(String profileId) {
    if (profileId.isEmpty) {
      throw Exception('Profile ID cannot be empty');
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<dom.Transaction?> getTransaction(String transactionId) async {
    try {
      // Get all transactions and filter
      final allTransactions = await getAllTransactions('all');
      for (final tx in allTransactions) {
        if (tx.id == transactionId) {
          return tx;
        }
      }
      return null;
    } catch (e) {
      _logger.severe('Error getting transaction: $e');
      return null;
    }
  }

  Future<List<dom.Transaction>> getTransactionsByProfile(String profileId) async {
    return await getAllTransactions(profileId);
  }

  /// Save a new transaction to the database
  Future<void> saveTransaction(dom.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    // Check if this is an update
    if (tx.id != null && tx.id!.isNotEmpty) {
      final existingId = int.tryParse(tx.id!);
      if (existingId != null) {
        try {
          final existing = await _db.getTransactionById(existingId);
          if (existing != null) {
            await updateTransaction(tx);
            return;
          }
        } catch (e) {
          // Transaction doesn't exist, proceed with insert
        }
      }
    }
    
    final companion = app_db.TransactionsCompanion.insert(
      amountMinor: tx.amount,
      currency: 'KES',
      description: tx.description ?? '',
      categoryId: Value(tx.categoryId),
      date: tx.date,
      isExpense: Value(tx.isExpense),
      rawSms: Value(tx.smsSource),
      profileId: _profileIdToInt(tx.profileId),
      transactionType: Value(tx.type.name),
      goalId: Value(tx.goalId),
    );
    
    final insertedId = await _db.insertTransaction(companion);
    _logger.info('✅ Transaction saved with ID: $insertedId');
  }

  /// Update an existing transaction in the database
  Future<void> updateTransaction(dom.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    final txId = int.tryParse(tx.id ?? '');
    if (txId == null) {
      throw Exception('Invalid transaction ID for update: ${tx.id}');
    }
    
    await _db.update(_db.transactions).replace(
      app_db.TransactionsCompanion(
        id: Value(txId),
        amountMinor: Value(tx.amount),
        currency: const Value('KES'),
        description: Value(tx.description ?? ''),
        categoryId: Value(tx.categoryId),
        date: Value(tx.date),
        isExpense: Value(tx.isExpense),
        rawSms: Value(tx.smsSource),
        profileId: Value(_profileIdToInt(tx.profileId)),
        transactionType: Value(tx.type.name),
        goalId: Value(tx.goalId),
      ),
    );
    
    _logger.info('✅ Transaction updated: ${tx.id}');
  }

  /// Delete a transaction from the database
  Future<void> deleteTransaction(String id) async {
    int? numericId = int.tryParse(id);
    if (numericId == null) {
      throw Exception('Invalid transaction ID format: $id');
    }
    
    await _db.deleteTransactionById(numericId);
    _logger.info('✅ Transaction deleted: $id');
  }

  /// Approve pending transaction (convert to regular transaction)
  Future<void> approvePendingTransaction(dom.Transaction tx) async {
    final mainTransaction = dom.Transaction(
      id: tx.id,
      amount: tx.amount,
      type: tx.type,
      categoryId: tx.categoryId,
      category: tx.category,
      date: tx.date,
      description: tx.description,
      smsSource: tx.smsSource,
      profileId: tx.profileId,
      isExpense: tx.isExpense,
      goalId: tx.goalId,
    );
    
    await saveTransaction(mainTransaction);
    await _db.deletePending(tx.id ?? '');
    
    if (_eventService != null) {
      await _eventService!.onTransactionApproved(mainTransaction);
      _logger.info('📢 Transaction approved event emitted');
    }
    
    _logger.info('✅ Pending transaction approved and saved');
  }

  Future<List<dom.Transaction>> getAllTransactions(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllTransactions();
    
    return rows
      .where((r) => r.profileId == profileIdInt)
      .map((r) {
        TransactionType type;
        if (r.transactionType != null && r.transactionType!.isNotEmpty) {
          if (r.transactionType!.contains('savings')) {
            type = TransactionType.savings;
          } else if (r.transactionType!.contains('expense')) {
            type = TransactionType.expense;
          } else {
            type = TransactionType.income;
          }
        } else {
          type = r.isExpense ? TransactionType.expense : TransactionType.income;
        }
        
        return dom.Transaction(
          id: r.id.toString(),
          amount: r.amountMinor,
          type: type,
          categoryId: r.categoryId ?? '',
          category: _getTransactionCategoryFromId(r.categoryId),
          description: r.description,
          date: r.date,
          smsSource: r.rawSms ?? '',
          profileId: profileId,
          isExpense: r.isExpense,
          goalId: r.goalId,
        );
      })
      .toList();
  }

  TransactionCategory? _getTransactionCategoryFromId(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return TransactionCategory.values.firstWhere(
        (category) => category.name == categoryId.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== BUDGETS ====================

  Future<void> saveBudget(dom.Budget budget) async {
    _validateProfileId(budget.profileId);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetsKey = 'budgets_${_profileIdToInt(budget.profileId)}';
      
      final existingJson = prefs.getString(budgetsKey);
      List<Map<String, dynamic>> budgets = [];
      
      if (existingJson != null) {
        final decoded = jsonDecode(existingJson) as List;
        budgets = decoded.cast<Map<String, dynamic>>();
      }
      
      final budgetJson = budget.toJson();
      final index = budgets.indexWhere((b) => b['id'] == budget.id);
      
      if (index != -1) {
        budgets[index] = budgetJson;
      } else {
        budgets.add(budgetJson);
      }
      
      await prefs.setString(budgetsKey, jsonEncode(budgets));
      
      if (kDebugMode) {
        print('Budget saved: ${budget.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving budget: $e');
      }
      rethrow;
    }
  }
  
  Future<void> addBudget(dom.Budget budget) async {
    await saveBudget(budget);
  }
  
  Future<List<dom.Budget>> getAllBudgets(String profileId) async {
    _validateProfileId(profileId);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetsKey = 'budgets_${_profileIdToInt(profileId)}';
      
      final existingJson = prefs.getString(budgetsKey);
      if (existingJson == null) return [];
      
      final decoded = jsonDecode(existingJson) as List;
      final budgets = decoded.cast<Map<String, dynamic>>();
      
      return budgets.map((json) {
        json['profileId'] = profileId;
        return dom.Budget.fromJson(json);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading budgets: $e');
      }
      return [];
    }
  }
  
  Future<dom.Budget?> getCurrentBudget(String profileId) async {
    final budgets = await getAllBudgets(profileId);
    if (budgets.isEmpty) return null;
    
    final activeBudgets = budgets.where((b) => b.isActive).toList();
    if (activeBudgets.isEmpty) return null;
    
    activeBudgets.sort((a, b) => b.startDate.compareTo(a.startDate));
    return activeBudgets.first;
  }

  Future<void> updateBudget(dom.Budget budget) async {
    await saveBudget(budget);
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('budgets_'));
      
      for (final key in keys) {
        final existingJson = prefs.getString(key);
        if (existingJson == null) continue;
        
        final decoded = jsonDecode(existingJson) as List;
        var budgets = decoded.cast<Map<String, dynamic>>();
        
        final originalLength = budgets.length;
        budgets.removeWhere((b) => b['id'] == budgetId);
        
        if (budgets.length < originalLength) {
          await prefs.setString(key, jsonEncode(budgets));
          if (kDebugMode) {
            print('Budget deleted: $budgetId');
          }
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting budget: $e');
      }
      rethrow;
    }
  }

  // ==================== GOALS ====================

  /// Save a new goal with current amount
  Future<void> saveGoal(dom.Goal goal) async {
    _validateProfileId(goal.profileId);
    
    final companion = app_db.GoalsCompanion.insert(
      title: goal.name,
      targetMinor: goal.targetAmount,
      currentMinor: Value(goal.currentAmount),
      currency: 'KES',
      dueDate: goal.targetDate,
      completed: Value(goal.status == GoalStatus.completed),
      profileId: _profileIdToInt(goal.profileId),
    );
    
    final insertedId = await _db.insertGoal(companion);
    _logger.info('✅ Goal saved: ${goal.name} (ID: $insertedId)');
  }

  Future<void> addGoal(dom.Goal goal) async {
    await saveGoal(goal);
  }

  /// Get all goals for a profile with current amounts
  Future<List<dom.Goal>> getAllGoals(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllGoals();
    
    return rows
      .where((r) => r.profileId == profileIdInt)
      .map((r) {
        return dom.Goal(
          id: r.id.toString(),
          name: r.title,
          targetAmount: r.targetMinor,
          currentAmount: r.currentMinor,
          targetDate: r.dueDate,
          profileId: profileId,
          goalType: GoalType.other,
          status: r.completed ? GoalStatus.completed : GoalStatus.active,
        );
      })
      .toList();
  }

  /// Get a single goal by ID with current amount
  Future<dom.Goal?> getGoal(String goalId) async {
    try {
      final rows = await _db.getAllGoals();
      final goal = rows.firstWhere(
        (r) => r.id.toString() == goalId,
      );
      
      return dom.Goal(
        id: goal.id.toString(),
        name: goal.title,
        targetAmount: goal.targetMinor,
        currentAmount: goal.currentMinor,
        targetDate: goal.dueDate,
        profileId: goal.profileId.toString(),
        goalType: GoalType.other,
        status: goal.completed ? GoalStatus.completed : GoalStatus.active,
      );
    } catch (e) {
      _logger.warning('Goal not found: $goalId - $e');
      return null;
    }
  }

  /// Update goal including current amount
  Future<void> updateGoal(dom.Goal goal) async {
    _validateProfileId(goal.profileId);
    
    final goalId = int.tryParse(goal.id!);
    if (goalId == null) {
      throw Exception('Invalid goal ID format: ${goal.id}');
    }

    await _db.update(_db.goals)
      .replace(app_db.GoalsCompanion(
        id: Value(goalId),
        title: Value(goal.name),
        targetMinor: Value(goal.targetAmount),
        currentMinor: Value(goal.currentAmount),
        currency: const Value('KES'),
        dueDate: Value(goal.targetDate),
        completed: Value(goal.status == GoalStatus.completed),
        profileId: Value(_profileIdToInt(goal.profileId)),
      ));
      
    _logger.info('✅ Goal updated: ${goal.name} - Current: ${goal.currentAmount}/${goal.targetAmount}');
  }

  /// Delete a goal
  Future<void> deleteGoal(String goalId) async {
    final goalIdInt = int.tryParse(goalId);
    if (goalIdInt == null) {
      throw Exception('Invalid goal ID format: $goalId');
    }
    
    await (_db.delete(_db.goals)..where((g) => g.id.equals(goalIdInt))).go();
    _logger.info('✅ Goal deleted: $goalId');
  }

  /// Helper: Calculate current amount from transactions
  Future<double> calculateGoalCurrentAmount(String goalId, String profileId) async {
    try {
      final allTransactions = await getAllTransactions(profileId);
      
      final goalTransactions = allTransactions.where((tx) =>
        tx.type == TransactionType.savings &&
        tx.goalId == goalId
      ).toList();
      
      final totalSavings = goalTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
      );
      
      return totalSavings;
    } catch (e) {
      _logger.warning('Error calculating goal amount: $e');
      return 0.0;
    }
  }

  /// Helper: Recalculate all goal amounts from transactions
  Future<void> recalculateAllGoalAmounts(String profileId) async {
    try {
      _logger.info('🔄 Recalculating goal amounts for profile: $profileId');
      
      final goals = await getAllGoals(profileId);
      
      for (final goal in goals) {
        final calculatedAmount = await calculateGoalCurrentAmount(goal.id!, profileId);
        
        if (calculatedAmount != goal.currentAmount) {
          _logger.info('Updating goal ${goal.name}: ${goal.currentAmount} -> $calculatedAmount');
          
          final updatedGoal = goal.copyWith(
            currentAmount: calculatedAmount,
          );
          
          await updateGoal(updatedGoal);
        }
      }
      
      _logger.info('✅ Goal amount recalculation complete');
    } catch (e, stackTrace) {
      _logger.severe('Error recalculating goal amounts', e, stackTrace);
    }
  }

  // ==================== PENDING TRANSACTIONS ====================

  Future<void> savePendingTransaction(dom.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    final companion = app_db.PendingTransactionsCompanion.insert(
      id: tx.id ?? const Uuid().v4(),
      amountMinor: tx.amount,
      currency: const Value('KES'),
      description: Value(tx.description),
      date: tx.date,
      isExpense: Value(tx.isExpense),
      rawSms: Value(tx.smsSource),
      profileId: _profileIdToInt(tx.profileId),
    );
    await _db.insertPending(companion);
  }

  Future<List<dom.Transaction>> getPendingTransactions(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllPending(profileIdInt);
    
    return rows.map((r) => dom.Transaction(
      id: r.id,
      amount: r.amountMinor,
      type: r.isExpense ? TransactionType.expense : TransactionType.income,
      categoryId: '',
      category: null,
      description: r.description ?? '',
      date: r.date,
      smsSource: r.rawSms ?? '',
      profileId: profileId,
      isPending: true,
      isExpense: r.isExpense,
    )).toList();
  }

  Future<void> deletePendingTransaction(String id) async {
    await _db.deletePending(id);
  }

  Future<int> getPendingTransactionCount(String profileId) async {
    final pending = await getPendingTransactions(profileId);
    return pending.length;
  }

  // ==================== LOANS ====================

  Future<int> saveLoan(dom.Loan loan) async {
    final companion = app_db.LoansCompanion.insert(
      name: loan.name,
      principalMinor: loan.principalMinor.toInt(),
      currency: Value(loan.currency),
      interestRate: Value(loan.interestRate),
      startDate: loan.startDate,
      endDate: loan.endDate,
      profileId: _profileIdToInt(loan.profileId.toString()),
    );
    final insertedId = await _db.into(_db.loans).insert(companion);
    return insertedId;
  }

  Future<List<dom.Loan>> getAllLoans(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.select(_db.loans).get();
    
    return rows
      .where((r) => r.profileId == profileIdInt)
      .map((r) => dom.Loan(
        id: r.id.toString(),
        name: r.name,
        principalMinor: r.principalMinor.toDouble(),
        currency: r.currency,
        interestRate: r.interestRate,
        startDate: r.startDate,
        endDate: r.endDate,
        profileId: profileId,
      ))
      .toList();
  }

  Future<void> deleteLoan(String loanId) async {
    final loanIdInt = int.tryParse(loanId);
    if (loanIdInt == null) {
      throw Exception('Invalid loan ID format: $loanId');
    }
    
    await (_db.delete(_db.loans)..where((l) => l.id.equals(loanIdInt))).go();
  }

  Future<void> setRemoteLoanId(int localId, String remoteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loan_remote_$localId', remoteId);
  }

  Future<String?> getRemoteLoanId(int localId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loan_remote_$localId');
  }

  Future<void> removeRemoteLoanId(int localId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loan_remote_$localId');
  }

  Future<void> updateLoan(dom.Loan loan) async {
    final loanIdInt = int.tryParse(loan.id.toString());
    if (loanIdInt == null) {
      throw Exception('Invalid loan ID format: ${loan.id}');
    }

    await _db.update(_db.loans).replace(
      app_db.LoansCompanion(
        id: Value(loanIdInt),
        name: Value(loan.name),
        principalMinor: Value(loan.principalMinor.toInt()),
        currency: Value(loan.currency),
        interestRate: Value(loan.interestRate),
        startDate: Value(loan.startDate),
        endDate: Value(loan.endDate),
        profileId: Value(_profileIdToInt(loan.profileId.toString())),
      ),
    );
  }

  // ==================== UTILITY METHODS ====================

  Future<double> getAverageMonthlySpending(String profileId) async {
    final transactions = await getAllTransactions(profileId);
    
    if (transactions.isEmpty) return 0;

    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    final expenses = transactions
      .where((tx) => tx.type == TransactionType.expense && tx.date.isAfter(threeMonthsAgo))
      .map((tx) => tx.amount)
      .toList();

    if (expenses.isEmpty) return 0;

    final total = expenses.reduce((a, b) => a + b);
    return total / 3;
  }

  Future<List<dom.Category>> getCategories(String profileId) async {
    return [];
  }

  Future<int> getPendingTransactionCountFast(String profileId) async {
    try {
      return _prefs.getInt('pending_transaction_count_$profileId') ?? 0;
    } catch (e) {
      return await getPendingTransactionCount(profileId);
    }
  }

  Future<void> updatePendingTransactionCount(String profileId) async {
    try {
      final pending = await getPendingTransactions(profileId);
      await _prefs.setInt('pending_transaction_count_$profileId', pending.length);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pending transaction count: $e');
      }
    }
  }

  Future<void> savePendingTransactionWithCount(dom.Transaction tx) async {
    await savePendingTransaction(tx);
    await updatePendingTransactionCount(tx.profileId);
  }

  Future<void> approvePendingTransactionWithCount(dom.Transaction tx) async {
    await approvePendingTransaction(tx);
    await updatePendingTransactionCount(tx.profileId);
  }

  Future<void> deletePendingTransactionWithCount(String id, String profileId) async {
    await deletePendingTransaction(id);
    await updatePendingTransactionCount(profileId);
  }

  // ==================== SYNC MARKERS ====================

  /// Clear sync markers for a profile (reset sync status)
  Future<void> clearSyncMarkers(String profileId) async {
    try {
      _validateProfileId(profileId);
      
      // Clear synced flag on all transactions for this profile
      final transactions = await getAllTransactions(profileId);
      for (final tx in transactions) {
        await updateTransaction(tx.copyWith(isSynced: false));
      }
      
      // Clear synced flag on all budgets
      final budgets = await getAllBudgets(profileId);
      for (final budget in budgets) {
        await updateBudget(budget.copyWith(isSynced: false));
      }
      
      // Clear synced flag on all goals
      final goals = await getAllGoals(profileId);
      for (final goal in goals) {
        await updateGoal(goal.copyWith(isSynced: false));
      }
      
      // Clear synced flag on all loans
      final loans = await getAllLoans(profileId);
      for (final loan in loans) {
        await updateLoan(loan.copyWith(isSynced: false));
      }
      
      _logger.info('✅ Sync markers cleared for profile: $profileId');
    } catch (e, stackTrace) {
      _logger.severe('Error clearing sync markers', e, stackTrace);
      rethrow;
    }
  }
}
