// lib/services/offline_data_service.dart - UPDATED FOR NEW SCHEMA
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
  final _uuid = const Uuid();
  
  TransactionEventService? _eventService;

  OfflineDataService({app_db.AppDatabase? db}) : _db = db ?? app_db.AppDatabase();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void setEventService(TransactionEventService eventService) {
    _eventService = eventService;
    _logger.info('TransactionEventService linked to OfflineDataService');
  }

  bool get onboardingComplete => _prefs.getBool('onboarding_complete') ?? false;
  set onboardingComplete(bool v) => _prefs.setBool('onboarding_complete', v);

  bool get darkMode => _prefs.getBool('dark_mode') ?? false;
  set darkMode(bool v) => _prefs.setBool('dark_mode', v);

  int _profileIdToInt(String profileId) {
    final parsed = int.tryParse(profileId);
    if (parsed != null) return parsed;
    return profileId.hashCode.abs();
  }

  void _validateProfileId(String profileId) {
    if (profileId.isEmpty) {
      throw Exception('Profile ID cannot be empty');
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<dom.Transaction?> getTransaction(String transactionId) async {
    try {
      final id = int.tryParse(transactionId);
      if (id == null) return null;
      
      final tx = await _db.getTransactionById(id);
      if (tx == null) return null;
      
      return _mapDbTransactionToDomain(tx);
    } catch (e) {
      _logger.severe('Error getting transaction: $e');
      return null;
    }
  }

  Future<void> saveTransaction(dom.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    // Check if updating existing transaction
    if (tx.id != null && tx.id!.isNotEmpty) {
      final existingId = int.tryParse(tx.id!);
      if (existingId != null) {
        try {
          final existing = await _db.getTransactionById(existingId);
          if (existing != null) {
            await updateTransaction(tx);
            
            // Emit created event for new transactions
            if (_eventService != null) {
              await _eventService!.onTransactionCreated(tx);
            }
            
            return;
          }
        } catch (e) {
          // Transaction doesn't exist, proceed with insert
        }
      }
    }
    
    final companion = app_db.TransactionsCompanion.insert(
      amountMinor: tx.amount,
      currency: Value(tx.currency ?? 'KES'),
      type: Value(tx.type),
      description: Value(tx.description ?? ''),
      category: Value(tx.category),
      goalId: Value(tx.goalId),
      date: tx.date,
      isExpense: Value(tx.isExpense ?? (tx.type == 'expense')),
      isPending: Value(tx.isPending),
      rawSms: Value(tx.smsSource),
      profileId: _profileIdToInt(tx.profileId),
      budgetCategory: Value(tx.budgetCategory),
      paymentMethod: Value(tx.paymentMethod),
      merchantName: Value(tx.merchantName),
      merchantCategory: Value(tx.merchantCategory),
      tags: Value(tx.tags),
      reference: Value(tx.reference),
      recipient: Value(tx.recipient),
      status: Value(tx.status ?? 'completed'),
      isRecurring: Value(tx.isRecurring),
      isSynced: Value(tx.isSynced),
      remoteId: Value(tx.remoteId),
      createdAt: Value(tx.createdAt),
      updatedAt: Value(tx.updatedAt),
    );
    
    final insertedId = await _db.insertTransaction(companion);
    _logger.info('✅ Transaction saved with ID: $insertedId');
    
    // Emit created event
    if (_eventService != null) {
      await _eventService!.onTransactionCreated(tx.copyWith(id: insertedId.toString()));
    }
  }

  Future<void> updateTransaction(dom.Transaction tx) async {
    _validateProfileId(tx.profileId);
    
    final txId = int.tryParse(tx.id ?? '');
    if (txId == null) {
      throw Exception('Invalid transaction ID for update: ${tx.id}');
    }
    
    final companion = app_db.TransactionsCompanion(
      id: Value(txId),
      amountMinor: Value(tx.amount),
      currency: Value(tx.currency ?? 'KES'),
      type: Value(tx.type),
      description: Value(tx.description ?? ''),
      category: Value(tx.category),
      goalId: Value(tx.goalId),
      date: Value(tx.date),
      isExpense: Value(tx.isExpense ?? (tx.type == 'expense')),
      isPending: Value(tx.isPending),
      rawSms: Value(tx.smsSource),
      profileId: Value(_profileIdToInt(tx.profileId)),
      budgetCategory: Value(tx.budgetCategory),
      paymentMethod: Value(tx.paymentMethod),
      merchantName: Value(tx.merchantName),
      merchantCategory: Value(tx.merchantCategory),
      tags: Value(tx.tags),
      reference: Value(tx.reference),
      recipient: Value(tx.recipient),
      status: Value(tx.status ?? 'completed'),
      isRecurring: Value(tx.isRecurring),
      isSynced: Value(tx.isSynced),
      remoteId: Value(tx.remoteId),
      updatedAt: Value(DateTime.now()),
    );
    
    await _db.updateTransaction(companion);
    _logger.info('✅ Transaction updated: ${tx.id}');
    
    // Emit updated event
    if (_eventService != null) {
      await _eventService!.onTransactionUpdated(tx);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final numericId = int.tryParse(id);
    if (numericId == null) {
      throw Exception('Invalid transaction ID format: $id');
    }
    
    // Get transaction before deleting for event
    final tx = await getTransaction(id);
    
    await _db.deleteTransactionById(numericId);
    _logger.info('✅ Transaction deleted: $id');
    
    // Emit deleted event
    if (_eventService != null && tx != null) {
      await _eventService!.onTransactionDeleted(tx);
    }
  }

  Future<void> approvePendingTransaction(dom.Transaction tx) async {
    final mainTransaction = tx.copyWith(isPending: false);
    
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
      .map((r) => _mapDbTransactionToDomain(r))
      .toList();
  }

  Future<List<dom.Transaction>> getTransactionsByProfile(String profileId) async {
    return await getAllTransactions(profileId);
  }

  /// Map database transaction to domain model
  dom.Transaction _mapDbTransactionToDomain(app_db.Transaction r) {
    return dom.Transaction(
      id: r.id.toString(),
      remoteId: r.remoteId,
      amount: r.amountMinor,
      type: r.type,
      category: r.category,
      description: r.description,
      date: r.date,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      budgetCategory: r.budgetCategory,
      notes: null, // Not stored in DB
      isSynced: r.isSynced,
      profileId: r.profileId.toString(),
      goalId: r.goalId,
      smsSource: r.rawSms,
      reference: r.reference,
      recipient: r.recipient,
      isPending: r.isPending,
      isExpense: r.isExpense,
      isRecurring: r.isRecurring,
      paymentMethod: r.paymentMethod,
      currency: r.currency,
      status: r.status,
      merchantName: r.merchantName,
      merchantCategory: r.merchantCategory,
      tags: r.tags,
    );
  }

  // ==================== BUDGETS ====================

  Future<void> saveBudget(dom.Budget budget) async {
    _validateProfileId(budget.profileId);
    
    try {
      final budgetsKey = 'budgets_${_profileIdToInt(budget.profileId)}';
      final existingJson = _prefs.getString(budgetsKey);
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
      
      await _prefs.setString(budgetsKey, jsonEncode(budgets));
      _logger.info('Budget saved: ${budget.name}');
    } catch (e) {
      _logger.severe('Error saving budget: $e');
      rethrow;
    }
  }

  Future<void> addBudget(dom.Budget budget) async {
    await saveBudget(budget);
  }

  Future<List<dom.Budget>> getAllBudgets(String profileId) async {
    _validateProfileId(profileId);
    
    try {
      final budgetsKey = 'budgets_${_profileIdToInt(profileId)}';
      final existingJson = _prefs.getString(budgetsKey);
      
      if (existingJson == null) return [];
      
      final decoded = jsonDecode(existingJson) as List;
      final budgets = decoded.cast<Map<String, dynamic>>();
      
      return budgets.map((json) {
        json['profileId'] = profileId;
        return dom.Budget.fromJson(json);
      }).toList();
    } catch (e) {
      _logger.severe('Error loading budgets: $e');
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
      final keys = _prefs.getKeys().where((k) => k.startsWith('budgets_'));
      
      for (final key in keys) {
        final existingJson = _prefs.getString(key);
        if (existingJson == null) continue;
        
        final decoded = jsonDecode(existingJson) as List;
        var budgets = decoded.cast<Map<String, dynamic>>();
        
        final originalLength = budgets.length;
        budgets.removeWhere((b) => b['id'] == budgetId);
        
        if (budgets.length < originalLength) {
          await _prefs.setString(key, jsonEncode(budgets));
          _logger.info('Budget deleted: $budgetId');
          return;
        }
      }
    } catch (e) {
      _logger.severe('Error deleting budget: $e');
      rethrow;
    }
  }

  // ==================== GOALS ====================

  Future<void> saveGoal(dom.Goal goal) async {
    _validateProfileId(goal.profileId);
    
    final companion = app_db.GoalsCompanion.insert(
      title: goal.name,
      targetMinor: goal.targetAmount,
      currentMinor: Value(goal.currentAmount),
      currency: Value(goal.currency ?? 'KES'),
      dueDate: goal.targetDate,
      completed: Value(goal.status == GoalStatus.completed),
      profileId: _profileIdToInt(goal.profileId),
      goalType: Value(goal.goalType.name),
      status: Value(goal.status.name),
      description: Value(goal.description),
      isSynced: Value(goal.isSynced),
      remoteId: Value(goal.remoteId),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt ?? DateTime.now()),
    );
    
    final insertedId = await _db.insertGoal(companion);
    _logger.info('✅ Goal saved: ${goal.name} (ID: $insertedId)');
  }

  Future<void> addGoal(dom.Goal goal) async {
    await saveGoal(goal);
  }

  Future<List<dom.Goal>> getAllGoals(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllGoals();
    
    return rows
      .where((r) => r.profileId == profileIdInt)
      .map((r) => _mapDbGoalToDomain(r, profileId))
      .toList();
  }

  Future<dom.Goal?> getGoal(String goalId) async {
    try {
      final id = int.tryParse(goalId);
      if (id == null) return null;
      
      final goal = await _db.getGoalById(id);
      if (goal == null) return null;
      
      return _mapDbGoalToDomain(goal, goal.profileId.toString());
    } catch (e) {
      _logger.warning('Goal not found: $goalId - $e');
      return null;
    }
  }

  Future<void> updateGoal(dom.Goal goal) async {
    _validateProfileId(goal.profileId);
    
    final goalId = int.tryParse(goal.id!);
    if (goalId == null) {
      throw Exception('Invalid goal ID format: ${goal.id}');
    }

    final companion = app_db.GoalsCompanion(
      id: Value(goalId),
      title: Value(goal.name),
      targetMinor: Value(goal.targetAmount),
      currentMinor: Value(goal.currentAmount),
      currency: Value(goal.currency ?? 'KES'),
      dueDate: Value(goal.targetDate),
      completed: Value(goal.status == GoalStatus.completed),
      profileId: Value(_profileIdToInt(goal.profileId)),
      goalType: Value(goal.goalType.name),
      status: Value(goal.status.name),
      description: Value(goal.description),
      isSynced: Value(goal.isSynced),
      remoteId: Value(goal.remoteId),
      updatedAt: Value(DateTime.now()),
    );

    await _db.updateGoal(companion);
    _logger.info('✅ Goal updated: ${goal.name}');
  }

  Future<void> deleteGoal(String goalId) async {
    final goalIdInt = int.tryParse(goalId);
    if (goalIdInt == null) {
      throw Exception('Invalid goal ID format: $goalId');
    }
    
    await _db.deleteGoalById(goalIdInt);
    _logger.info('✅ Goal deleted: $goalId');
  }

  dom.Goal _mapDbGoalToDomain(app_db.Goal r, String profileId) {
    return dom.Goal(
      id: r.id.toString(),
      remoteId: r.remoteId,
      name: r.title,
      targetAmount: r.targetMinor,
      currentAmount: r.currentMinor,
      targetDate: r.dueDate,
      profileId: profileId,
      goalType: _parseGoalType(r.goalType),
      status: _parseGoalStatus(r.status),
      description: r.description,
      currency: r.currency,
      isSynced: r.isSynced,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  GoalType _parseGoalType(String? type) {
    if (type == null) return GoalType.savings;
    try {
      return GoalType.values.firstWhere((e) => e.name == type);
    } catch (e) {
      return GoalType.savings;
    }
  }

  GoalStatus _parseGoalStatus(String? status) {
    if (status == null) return GoalStatus.active;
    try {
      return GoalStatus.values.firstWhere((e) => e.name == status);
    } catch (e) {
      return GoalStatus.active;
    }
  }

  Future<double> calculateGoalCurrentAmount(String goalId, String profileId) async {
    try {
      final allTransactions = await getAllTransactions(profileId);
      
      final goalTransactions = allTransactions.where((tx) =>
        tx.type == 'savings' &&
        tx.goalId == goalId
      ).toList();
      
      return goalTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
      );
    } catch (e) {
      _logger.warning('Error calculating goal amount: $e');
      return 0.0;
    }
  }

  Future<void> recalculateAllGoalAmounts(String profileId) async {
    try {
      _logger.info('🔄 Recalculating goal amounts for profile: $profileId');
      
      final goals = await getAllGoals(profileId);
      
      for (final goal in goals) {
        final calculatedAmount = await calculateGoalCurrentAmount(goal.id!, profileId);
        
        if (calculatedAmount != goal.currentAmount) {
          _logger.info('Updating goal ${goal.name}: ${goal.currentAmount} -> $calculatedAmount');
          
          final updatedGoal = goal.copyWith(currentAmount: calculatedAmount);
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
      id: tx.id ?? _uuid.v4(),
      amountMinor: tx.amount,
      currency: Value(tx.currency ?? 'KES'),
      description: Value(tx.description),
      date: tx.date,
      isExpense: Value(tx.isExpense ?? true),
      rawSms: Value(tx.smsSource),
      profileId: _profileIdToInt(tx.profileId),
      type: Value(tx.type),
      category: Value(tx.category),
      budgetCategory: Value(tx.budgetCategory),
    );
    
    await _db.insertPending(companion);
    _logger.info('✅ Pending transaction saved');
  }

  Future<List<dom.Transaction>> getPendingTransactions(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllPending(profileIdInt);
    
    return rows.map((r) => dom.Transaction(
      id: r.id,
      remoteId: null,
      amount: r.amountMinor,
      type: r.type,
      category: r.category,
      description: r.description ?? '',
      date: r.date,
      smsSource: r.rawSms ?? '',
      profileId: profileId,
      isPending: true,
      isExpense: r.isExpense,
      currency: r.currency,
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
      profileId: _profileIdToInt(loan.profileId),
      description: Value(loan.description),
      isSynced: Value(loan.isSynced),
      remoteId: Value(loan.remoteId),
      createdAt: Value(loan.createdAt ?? DateTime.now()),
      updatedAt: Value(loan.updatedAt ?? DateTime.now()),
    );
    
    return await _db.insertLoan(companion);
  }

  Future<List<dom.Loan>> getAllLoans(String profileId) async {
    _validateProfileId(profileId);
    
    final profileIdInt = _profileIdToInt(profileId);
    final rows = await _db.getAllLoans();
    
    return rows
      .where((r) => r.profileId == profileIdInt)
      .map((r) => _mapDbLoanToDomain(r, profileId))
      .toList();
  }

  Future<void> updateLoan(dom.Loan loan) async {
    final loanIdInt = int.tryParse(loan.id);
    if (loanIdInt == null) {
      throw Exception('Invalid loan ID format: ${loan.id}');
    }

    final companion = app_db.LoansCompanion(
      id: Value(loanIdInt),
      name: Value(loan.name),
      principalMinor: Value(loan.principalMinor.toInt()),
      currency: Value(loan.currency),
      interestRate: Value(loan.interestRate),
      startDate: Value(loan.startDate),
      endDate: Value(loan.endDate),
      profileId: Value(_profileIdToInt(loan.profileId)),
      description: Value(loan.description),
      isSynced: Value(loan.isSynced),
      remoteId: Value(loan.remoteId),
      updatedAt: Value(DateTime.now()),
    );

    await _db.updateLoan(companion);
  }

  Future<void> deleteLoan(String loanId) async {
    final loanIdInt = int.tryParse(loanId);
    if (loanIdInt == null) {
      throw Exception('Invalid loan ID format: $loanId');
    }
    
    await _db.deleteLoanById(loanIdInt);
  }

  dom.Loan _mapDbLoanToDomain(app_db.Loan r, String profileId) {
    return dom.Loan(
      id: r.id.toString(),
      remoteId: r.remoteId,
      name: r.name,
      principalMinor: r.principalMinor.toDouble(),
      currency: r.currency,
      interestRate: r.interestRate,
      startDate: r.startDate,
      endDate: r.endDate,
      profileId: profileId,
      description: r.description,
      isSynced: r.isSynced,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  // ==================== UTILITY METHODS ====================

  Future<double> getAverageMonthlySpending(String profileId) async {
    final transactions = await getAllTransactions(profileId);
    
    if (transactions.isEmpty) return 0;

    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    final expenses = transactions
      .where((tx) => tx.type == 'expense' && tx.date.isAfter(threeMonthsAgo))
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
      _logger.warning('Error updating pending transaction count: $e');
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

  Future<void> clearSyncMarkers(String profileId) async {
    try {
      _validateProfileId(profileId);
      
      final transactions = await getAllTransactions(profileId);
      for (final tx in transactions) {
        await updateTransaction(tx.copyWith(isSynced: false));
      }
      
      final budgets = await getAllBudgets(profileId);
      for (final budget in budgets) {
        await updateBudget(budget.copyWith(isSynced: false));
      }
      
      final goals = await getAllGoals(profileId);
      for (final goal in goals) {
        await updateGoal(goal.copyWith(isSynced: false));
      }
      
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
