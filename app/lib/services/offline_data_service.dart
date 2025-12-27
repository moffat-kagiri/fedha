import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:fedha/data/app_database.dart';
import 'package:fedha/models/transaction.dart' as dom_tx;
import 'package:fedha/models/goal.dart' as dom_goal;
import 'package:fedha/models/loan.dart' as dom_loan;
import 'package:fedha/models/enums.dart';
import 'package:fedha/models/category.dart' as dom_cat;
import 'package:fedha/models/budget.dart' as dom_budget;

class OfflineDataService {
  late final SharedPreferences _prefs;
  final AppDatabase _db;

  OfflineDataService({AppDatabase? db}) : _db = db ?? AppDatabase();

  /// Initialize SharedPreferences instance
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
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
  /// Returns 0 if conversion fails (for backwards compatibility)
  int _profileIdToInt(String profileId) {
    // Try to parse as int first (for backwards compatibility)
    final parsed = int.tryParse(profileId);
    if (parsed != null) return parsed;
    
    // If it's a UUID, generate a consistent hash
    // This maintains consistency for the same UUID
    return profileId.hashCode.abs();
  }

  /// Helper to validate profile ID
  void _validateProfileId(String profileId) {
    if (profileId.isEmpty) {
      throw Exception('Profile ID cannot be empty');
    }
  }

  // Transactions
  Future<void> saveTransaction(dom_tx.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    // Check if this is an update (transaction has an ID that exists in DB)
    if (tx.id != null && tx.id!.isNotEmpty) {
      final existingId = int.tryParse(tx.id!);
      if (existingId != null) {
        // Check if transaction exists
        try {
          final existing = await _db.getTransactionById(existingId);
          if (existing != null) {
            // Update existing transaction
            await updateTransaction(tx);
            
            // If it's a savings transaction, update the goal
            if (tx.type == TransactionType.savings && tx.goalId != null) {
              await _updateGoalProgress(tx.goalId!);
            }
            return;
          }
        } catch (e) {
          // Transaction doesn't exist, proceed with insert
        }
      }
    }
    
    // Insert new transaction
    final companion = TransactionsCompanion.insert(
      amountMinor: tx.amount,
      currency: 'KES',
      description: tx.description ?? '',
      categoryId: Value(tx.categoryId),
      date: tx.date,
      isExpense: Value(tx.isExpense),
      rawSms: Value(tx.smsSource),
      profileId: _profileIdToInt(tx.profileId),
      // Store transaction type properly
      transactionType: Value(tx.type.toString()),
      goalId: Value(tx.goalId),
    );
    
    final insertedId = await _db.insertTransaction(companion);
    
    // If it's a savings transaction, update the goal
    if (tx.type == TransactionType.savings && tx.goalId != null) {
      await _updateGoalProgress(tx.goalId!);
    }
  }

  Future<void> updateTransaction(dom_tx.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    final txId = int.tryParse(tx.id ?? '');
    if (txId == null) {
      throw Exception('Invalid transaction ID for update: ${tx.id}');
    }
    
    // Get old transaction to check if goal changed
    final oldTx = await _db.getTransactionById(txId);
    final oldGoalId = oldTx?.goalId;
    
    await _db.update(_db.transactions).replace(
      TransactionsCompanion(
        id: Value(txId),
        amountMinor: Value(tx.amount),
        currency: const Value('KES'),
        description: Value(tx.description ?? ''),
        categoryId: Value(tx.categoryId),
        date: Value(tx.date),
        isExpense: Value(tx.isExpense),
        rawSms: Value(tx.smsSource),
        profileId: Value(_profileIdToInt(tx.profileId)),
        transactionType: Value(tx.type.toString()),
      ),
    );
    
    // Update affected goals
    if (tx.type == TransactionType.savings) {
      // Update new goal if exists
      if (tx.goalId != null) {
        await _updateGoalProgress(tx.goalId!);
      }
      // Update old goal if it changed
      if (oldGoalId != null && oldGoalId != tx.goalId) {
        await _updateGoalProgress(oldGoalId);
      }
    }
  }

  Future<List<dom_tx.Transaction>> getAllTransactions(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllTransactions();
    
    return rows
      .where((r) => r.profileId == profileIdInt)
      .map((r) {
        // Determine transaction type from stored type or fallback to isExpense
        TransactionType type;
        if (r.transactionType != null && r.transactionType!.isNotEmpty) {
          // Parse stored type
          if (r.transactionType!.contains('savings')) {
            type = TransactionType.savings;
          } else if (r.transactionType!.contains('expense')) {
            type = TransactionType.expense;
          } else {
            type = TransactionType.income;
          }
        } else {
          // Fallback for old data
          type = r.isExpense ? TransactionType.expense : TransactionType.income;
        }
        
        return dom_tx.Transaction(
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
          goalId: r.goalId, // FIXED: This now references the actual column
        );
      })
      .toList();
  }

  // Helper to update goal progress when savings transactions change
  Future<void> _updateGoalProgress(String goalId) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) return;
      
      // Calculate total savings for this goal
      final profileId = goal.profileId;
      final allTransactions = await getAllTransactions(profileId);
      
      final savingsForGoal = allTransactions
          .where((tx) => 
              tx.type == TransactionType.savings && 
              tx.goalId == goalId)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      
      // Update goal's current amount
      final updatedGoal = dom_goal.Goal(
        id: goal.id,
        name: goal.name,
        description: goal.description,
        targetAmount: goal.targetAmount,
        currentAmount: savingsForGoal,
        targetDate: goal.targetDate,
        profileId: goal.profileId,
        goalType: goal.goalType,
        status: goal.status,
        isSynced: false, // Mark for sync
      );
      
      await updateGoal(updatedGoal);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goal progress: $e');
      }
    }
  }

  // Helper method to convert categoryId to TransactionCategory
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

  // ==================== BUDGETS (IMPLEMENTATION) ====================

  Future<void> saveBudget(dom_budget.Budget budget) async {
    _validateProfileId(budget.profileId);
    
    try {
      // Store in SharedPreferences as JSON for now
      // TODO: Move to Drift database when budget table is added
      final prefs = await SharedPreferences.getInstance();
      final budgetsKey = 'budgets_${_profileIdToInt(budget.profileId)}';
      
      // Get existing budgets
      final existingJson = prefs.getString(budgetsKey);
      List<Map<String, dynamic>> budgets = [];
      
      if (existingJson != null) {
        final decoded = jsonDecode(existingJson) as List;
        budgets = decoded.cast<Map<String, dynamic>>();
      }
      
      // Add or update budget
      final budgetJson = budget.toJson();
      final index = budgets.indexWhere((b) => b['id'] == budget.id);
      
      if (index != -1) {
        budgets[index] = budgetJson;
      } else {
        budgets.add(budgetJson);
      }
      
      // Save back
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
  
  Future<void> addBudget(dom_budget.Budget budget) async {
    await saveBudget(budget);
  }
  
  Future<List<dom_budget.Budget>> getAllBudgets(String profileId) async {
    _validateProfileId(profileId);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetsKey = 'budgets_${_profileIdToInt(profileId)}';
      
      final existingJson = prefs.getString(budgetsKey);
      if (existingJson == null) return [];
      
      final decoded = jsonDecode(existingJson) as List;
      final budgets = decoded.cast<Map<String, dynamic>>();
      
      return budgets.map((json) {
        // Ensure profileId is set correctly
        json['profileId'] = profileId;
        return dom_budget.Budget.fromJson(json);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading budgets: $e');
      }
      return [];
    }
  }
  
  Future<dom_budget.Budget?> getCurrentBudget(String profileId) async {
    final budgets = await getAllBudgets(profileId);
    if (budgets.isEmpty) return null;
    
    // Get most recent active budget
    final activeBudgets = budgets.where((b) => b.isActive).toList();
    if (activeBudgets.isEmpty) return null;
    
    activeBudgets.sort((a, b) => b.startDate.compareTo(a.startDate));
    return activeBudgets.first;
  }

  Future<void> updateBudget(dom_budget.Budget budget) async {
    // Update is the same as save for budgets
    await saveBudget(budget);
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // We need to find which profile this budget belongs to
      // For now, check all profile budgets (not ideal, but works)
      final keys = prefs.getKeys().where((k) => k.startsWith('budgets_'));
      
      for (final key in keys) {
        final existingJson = prefs.getString(key);
        if (existingJson == null) continue;
        
        final decoded = jsonDecode(existingJson) as List;
        var budgets = decoded.cast<Map<String, dynamic>>();
        
        final originalLength = budgets.length;
        budgets.removeWhere((b) => b['id'] == budgetId);
        
        if (budgets.length < originalLength) {
          // Budget was found and removed
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

  // Goals
  Future<void> saveGoal(dom_goal.Goal goal) async {
    _validateProfileId(goal.profileId);
    
    final companion = GoalsCompanion.insert(
      title: goal.name,
      targetMinor: goal.targetAmount,
      currency: 'KES',
      dueDate: goal.targetDate,
      completed: Value(goal.status == GoalStatus.completed),
      profileId: _profileIdToInt(goal.profileId),
    );
    await _db.insertGoal(companion);
  }
  
  Future<void> addGoal(dom_goal.Goal goal) async {
    await saveGoal(goal);
  }

  Future<List<dom_goal.Goal>> getAllGoals(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllGoals();
    
    return rows
      .where((r) => r.profileId == profileIdInt)
      .map((r) => dom_goal.Goal(
        id: r.id.toString(),
        name: r.title,
        targetAmount: r.targetMinor,
        targetDate: r.dueDate,
        profileId: profileId, // Return original UUID string
        goalType: GoalType.other,
        status: r.completed ? GoalStatus.completed : GoalStatus.active,
      ))
      .toList();
  }

  // ==================== LOANS (FIX STRING PARAMETER) ====================

  /// Saves a loan to the local DB. Returns the local inserted ID.
  Future<int> saveLoan(dom_loan.Loan loan) async {
    final companion = LoansCompanion.insert(
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

  Future<List<dom_loan.Loan>> getAllLoans(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.select(_db.loans).get();
    
    return rows
      .where((r) => r.profileId == profileIdInt)
      .map((r) => dom_loan.Loan(
        id: r.id,
        name: r.name,
        principalMinor: r.principalMinor.toDouble(),
        currency: r.currency,
        interestRate: r.interestRate,
        startDate: r.startDate,
        endDate: r.endDate,
        profileId: profileId, // Return original UUID string
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

  // Remote ID mapping helpers stored in SharedPreferences
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

  Future<void> updateLoan(dom_loan.Loan loan) async {
    final loanIdInt = int.tryParse(loan.id.toString());
    if (loanIdInt == null) {
      throw Exception('Invalid loan ID format: ${loan.id}');
    }

    await _db.update(_db.loans).replace(
      LoansCompanion(
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
  // SMS-review helpers (pending transactions)
  Future<void> savePendingTransaction(dom_tx.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    final companion = PendingTransactionsCompanion.insert(
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

  Future<List<dom_tx.Transaction>> getPendingTransactions(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllPending(profileIdInt);
    
    return rows.map((r) => dom_tx.Transaction(
      id: r.id,
      amount: r.amountMinor,
      type: r.isExpense ? TransactionType.expense : TransactionType.income,
      categoryId: '',
      category: null,
      description: r.description ?? '',
      date: r.date,
      smsSource: r.rawSms ?? '',
      profileId: profileId, // Return original UUID string
      isPending: true,
      isExpense: r.isExpense,
    )).toList();
  }

  Future<void> approvePendingTransaction(dom_tx.Transaction tx) async {
    final mainTransaction = dom_tx.Transaction(
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
    );
    
    await saveTransaction(mainTransaction);
    await _db.deletePending(tx.id ?? '');
  }

  Future<void> deletePendingTransaction(String id) async {
    await _db.deletePending(id);
  }

  Future<void> deleteTransaction(String id) async {
    int? numericId = int.tryParse(id);
    if (numericId != null) {
      await _db.deleteTransactionById(numericId);
    } else {
      throw Exception('Invalid transaction ID format: $id');
    }
  }

  Future<List<dom_cat.Category>> getCategories(String profileId) async {
    return [];
  }

  Future<dom_goal.Goal?> getGoal(String goalId) async {
    try {
      final rows = await _db.getAllGoals();
      final goal = rows.firstWhere(
        (r) => r.id.toString() == goalId,
      );
      return dom_goal.Goal(
        id: goal.id.toString(),
        name: goal.title,
        targetAmount: goal.targetMinor,
        targetDate: goal.dueDate,
        profileId: goal.profileId.toString(),
        goalType: GoalType.other,
        status: goal.completed ? GoalStatus.completed : GoalStatus.active,
      );
    } catch (e) {
      return null;
    }
  }

  Future<int> getPendingTransactionCount(String profileId) async {
    final pending = await getPendingTransactions(profileId);
    return pending.length;
  }

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

  Future<void> updateGoal(dom_goal.Goal goal) async {
    _validateProfileId(goal.profileId);
    
    final goalId = int.tryParse(goal.id);
    if (goalId == null) {
      throw Exception('Invalid goal ID format: ${goal.id}');
    }

    await _db.update(_db.goals)
      .replace(GoalsCompanion(
        id: Value(goalId),
        title: Value(goal.name),
        targetMinor: Value(goal.targetAmount),
        currency: const Value('KES'),
        dueDate: Value(goal.targetDate),
        completed: Value(goal.status == GoalStatus.completed),
        profileId: Value(_profileIdToInt(goal.profileId)),
      ));
  }

  /// Save pending transaction and update count in SharedPreferences
  /// This allows the background worker to track pending counts
  Future<void> savePendingTransactionWithCount(dom_tx.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    // Save the pending transaction
    await savePendingTransaction(tx);
    
    // Update pending count in SharedPreferences for background tasks
    try {
      final pending = await getPendingTransactions(tx.profileId);
      await _prefs.setInt('pending_transaction_count_${tx.profileId}', pending.length);
      
      if (kDebugMode) {
        print('Updated pending transaction count for ${tx.profileId}: ${pending.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pending transaction count: $e');
      }
    }
  }

  /// Get pending transaction count from SharedPreferences
  /// Faster than querying database, useful for notifications
  Future<int> getPendingTransactionCountFast(String profileId) async {
    try {
      return _prefs.getInt('pending_transaction_count_$profileId') ?? 0;
    } catch (e) {
      // Fallback to database query
      return await getPendingTransactionCount(profileId);
    }
  }

  /// Update pending transaction count after approval or deletion
  Future<void> updatePendingTransactionCount(String profileId) async {
    try {
      final pending = await getPendingTransactions(profileId);
      await _prefs.setInt('pending_transaction_count_$profileId', pending.length);
      
      if (kDebugMode) {
        print('Updated pending transaction count for $profileId: ${pending.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pending transaction count: $e');
      }
    }
  }

  /// Modified approvePendingTransaction to update count
  Future<void> approvePendingTransactionWithCount(dom_tx.Transaction tx) async {
    await approvePendingTransaction(tx);
    await updatePendingTransactionCount(tx.profileId);
  }

  /// Modified deletePendingTransaction to update count
  Future<void> deletePendingTransactionWithCount(String id, String profileId) async {
    await deletePendingTransaction(id);
    await updatePendingTransactionCount(profileId);
  }
}