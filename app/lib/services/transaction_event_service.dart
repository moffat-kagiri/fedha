// lib/services/transaction_event_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/enums.dart';
import '../utils/logger.dart';
import 'offline_data_service.dart';
import 'budget_service.dart';

/// Event types for transaction changes
enum TransactionEventType {
  created,
  updated,
  deleted,
  approved,
}

/// Transaction event data
class TransactionEvent {
  final TransactionEventType type;
  final Transaction transaction;
  final DateTime timestamp;

  TransactionEvent({
    required this.type,
    required this.transaction,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service that handles transaction events and triggers updates
class TransactionEventService extends ChangeNotifier {
  static TransactionEventService? _instance;
  static TransactionEventService get instance => _instance ??= TransactionEventService._();

  final _logger = AppLogger.getLogger('TransactionEventService');
  final _eventController = StreamController<TransactionEvent>.broadcast();
  
  OfflineDataService? _offlineDataService;
  BudgetService? _budgetService;
  String? _currentProfileId;

  TransactionEventService._();

  Stream<TransactionEvent> get eventStream => _eventController.stream;

  Future<void> initialize({
    required OfflineDataService offlineDataService,
    required BudgetService budgetService,
  }) async {
    _offlineDataService = offlineDataService;
    _budgetService = budgetService;
    
    _eventController.stream.listen(_handleTransactionEvent);
    
    _logger.info('TransactionEventService initialized');
  }

  void setCurrentProfile(String profileId) {
    _currentProfileId = profileId;
    _logger.info('Current profile set: $profileId');
  }

  // ==================== EVENT EMITTERS ====================

  Future<void> onTransactionCreated(Transaction transaction) async {
    _logger.info('Transaction created: ${transaction.id} - ${transaction.amountMinor}');
    _eventController.add(TransactionEvent(
      type: TransactionEventType.created,
      transaction: transaction,
    ));
    notifyListeners();
  }

  Future<void> onTransactionUpdated(Transaction transaction) async {
    _logger.info('Transaction updated: ${transaction.id}');
    
    // Preserve existing budget category assignment
    if (transaction.budgetCategory != null && transaction.budgetCategory!.isNotEmpty) {
      _logger.info('Preserving budget category: ${transaction.budgetCategory}');
    }
    
    _eventController.add(TransactionEvent(
      type: TransactionEventType.updated,
      transaction: transaction,
    ));
    notifyListeners();
  }

  Future<void> onTransactionDeleted(Transaction transaction) async {
    _logger.info('Transaction deleted: ${transaction.id}');
    _eventController.add(TransactionEvent(
      type: TransactionEventType.deleted,
      transaction: transaction,
    ));
    notifyListeners();
  }

  Future<void> onTransactionApproved(Transaction transaction) async {
    _logger.info('Transaction approved: ${transaction.id}');
    _eventController.add(TransactionEvent(
      type: TransactionEventType.approved,
      transaction: transaction,
    ));
    notifyListeners();
  }

  // ==================== EVENT HANDLERS ====================

  Future<void> _handleTransactionEvent(TransactionEvent event) async {
    try {
      switch (event.type) {
        case TransactionEventType.created:
        case TransactionEventType.approved:
          await _handleTransactionAdded(event.transaction);
          break;
        case TransactionEventType.updated:
          await _handleTransactionUpdated(event.transaction);
          break;
        case TransactionEventType.deleted:
          await _handleTransactionDeleted(event.transaction);
          break;
      }
    } catch (e, stackTrace) {
      _logger.severe('Error handling transaction event', e, stackTrace);
    }
  }

  Future<void> _handleTransactionAdded(Transaction transaction) async {
    if (_offlineDataService == null || _budgetService == null) {
      _logger.warning('Services not initialized');
      return;
    }

    _logger.info('Processing new transaction: ${transaction.type} - ${transaction.amountMinor}');

    // Update budgets for expense transactions
    if (transaction.type == 'expense' || transaction.isExpense == true) {
      await _updateBudgetSpending(
        transaction: transaction,
        isAddition: true,
      );
    }

    // Update savings budget for all savings transactions
    if (transaction.type == 'savings') {
      await _updateSavingsBudget(transaction, isAddition: true);
      
      // Also update goal progress if linked to a goal
      if (transaction.goalId != null && transaction.goalId!.isNotEmpty) {
        await _updateGoalProgress(
          goalId: transaction.goalId!,
          amount: transaction.amountMinor.toDouble(), // Convert minor units to double for goals
          isAddition: true,
        );
      } else {
        _logger.info('💰 Savings transaction without goal - general savings recorded');
      }
    }
  }

  Future<void> _handleTransactionUpdated(Transaction transaction) async {
    await _recalculateBudgets(transaction.profileId);
    
    if (transaction.goalId != null && transaction.goalId!.isNotEmpty) {
      await _recalculateGoalProgress(transaction.goalId!);
    }
  }

  Future<void> _handleTransactionDeleted(Transaction transaction) async {
    if (transaction.type == 'expense' || transaction.isExpense == true) {
      await _updateBudgetSpending(
        transaction: transaction,
        isAddition: false,
      );
    }

    // Update savings budget when savings transactions are deleted
    if (transaction.type == 'savings') {
      await _updateSavingsBudget(transaction, isAddition: false);
      
      if (transaction.goalId != null && transaction.goalId!.isNotEmpty) {
        await _updateGoalProgress(
          goalId: transaction.goalId!,
          amount: transaction.amountMinor.toDouble(),
          isAddition: false,
        );
      }
    }
  }

  // ==================== CATEGORY NORMALIZATION ====================

  /// Normalize category names for proper matching
  String _normalizeCategory(String category) {
    if (category.isEmpty) return 'other';
    
    // Convert to lowercase and trim
    final normalized = category.toLowerCase().trim();
    
    // Map common variations to standard names
    final categoryMap = {
      'other': 'other',
      'others': 'other',
      'other expense': 'other',
      'other income': 'other',
      'miscellaneous': 'other',
      'misc': 'other',
      'savings': 'savings',
      'saving': 'savings',
      'save': 'savings',
    };
    
    return categoryMap[normalized] ?? normalized;
  }

  /// Check if categories match (handles variations)
  bool _categoriesMatch(String category1, String category2) {
    return _normalizeCategory(category1) == _normalizeCategory(category2);
  }

  // ==================== BUDGET UPDATES WITH PERSISTENT CATEGORIES ====================

  Future<void> _updateBudgetSpending({
    required Transaction transaction,
    required bool isAddition,
  }) async {
    try {
      if (_offlineDataService == null || _budgetService == null) return;

      final budgets = await _offlineDataService!.getAllBudgets(transaction.profileId);

      // ✅ NEW: Check if transaction already has a budget category assigned
      String assignedCategory;
      bool needsCategoryUpdate = false;
      
      if (transaction.budgetCategory != null && transaction.budgetCategory!.isNotEmpty) {
        // Use previously assigned category
        assignedCategory = transaction.budgetCategory!;
        _logger.info('📝 Using previously assigned budget category: $assignedCategory');
      } else {
        // Find matching budget for this transaction
        final matchingBudgets = budgets.where((b) => 
          _categoriesMatch(b.category, transaction.category) &&
          b.isActive &&
          !transaction.date.isBefore(b.startDate) &&
          !transaction.date.isAfter(b.endDate) &&
          b.category != 'other'
        ).toList();

        if (matchingBudgets.isNotEmpty) {
          assignedCategory = matchingBudgets.first.category;
        } else {
          // Check for 'other' budget
          final otherBudgets = budgets.where((b) => 
            b.category == 'other' &&
            b.isActive &&
            !transaction.date.isBefore(b.startDate) &&
            !transaction.date.isAfter(b.endDate)
          ).toList();
          
          if (otherBudgets.isNotEmpty) {
            assignedCategory = 'other';
          } else {
            _logger.info('📊 No matching budget found for transaction. Category: ${transaction.category}');
            return; // No budget to update
          }
        }
        
        // ✅ Save the assigned category back to the transaction
        needsCategoryUpdate = true;
      }

      // Find the budget(s) with the assigned category
      final targetBudgets = budgets.where((b) => 
        b.category == assignedCategory &&
        b.isActive &&
        !transaction.date.isBefore(b.startDate) &&
        !transaction.date.isAfter(b.endDate)
      ).toList();

      if (targetBudgets.isEmpty) {
        _logger.warning('⚠️ No active budget found for category: $assignedCategory in date range');
        return;
      }

      // Update the budget(s)
      for (final budget in targetBudgets) {
        final amountMajor = transaction.amountMinor / 100.0; // Convert minor units to major units
        
        final newSpentAmount = isAddition
            ? budget.spentAmount + amountMajor
            : budget.spentAmount - amountMajor;

        final updatedBudget = budget.copyWith(
          spentAmount: newSpentAmount.clamp(0.0, double.infinity),
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await _budgetService!.updateBudget(updatedBudget);
        
        _logger.info(
          '✅ Budget updated: ${budget.name} ($assignedCategory) - '
          'spent: KSh ${updatedBudget.spentAmount.toStringAsFixed(0)} / '
          'KSh ${budget.budgetAmount.toStringAsFixed(0)}'
        );
        
        if (updatedBudget.spentAmount > budget.budgetAmount) {
          _logger.warning(
            '⚠️ Budget exceeded: ${budget.name} by '
            'KSh ${(updatedBudget.spentAmount - budget.budgetAmount).toStringAsFixed(0)}'
          );
        }
      }

      // ✅ Persist the budget category assignment
      if (needsCategoryUpdate) {
        // Create a new transaction object with the budget category
        final updatedTransaction = Transaction(
          id: transaction.id,
          profileId: transaction.profileId,
          amount: transaction.amountMinor / 100.0, // Convert to amount (major units)
          type: transaction.type,
          isExpense: transaction.isExpense,
          category: transaction.category,
          description: transaction.description,
          date: transaction.date,
          goalId: transaction.goalId,
          budgetCategory: assignedCategory,
          currency: transaction.currency,
          isSynced: false,
          createdAt: transaction.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await _offlineDataService!.updateTransaction(updatedTransaction);
        _logger.info('💾 Saved budget category "$assignedCategory" to transaction');
      }
      
    } catch (e, stackTrace) {
      _logger.severe('Error updating budget spending', e, stackTrace);
    }
  }

  Future<void> _updateSavingsBudget(
    Transaction transaction, {
    required bool isAddition,
  }) async {
    try {
      if (_offlineDataService == null || _budgetService == null) return;

      final budgets = await _offlineDataService!.getAllBudgets(transaction.profileId);

      // Find savings budget that covers this transaction's date range
      final savingsBudgets = budgets.where((b) => 
        b.category == 'savings' &&
        b.isActive &&
        !transaction.date.isBefore(b.startDate) &&
        !transaction.date.isAfter(b.endDate)
      ).toList();

      if (savingsBudgets.isEmpty) {
        _logger.info(
          '📊 No savings budget found for date range. '
          'Savings amount not tracked: KSh ${transaction.amountMinor / 100.0}'
        );
        return;
      }

      for (final budget in savingsBudgets) {
        final amountMajor = transaction.amountMinor / 100.0; // Convert minor units to major units
        
        final newSpentAmount = isAddition
            ? budget.spentAmount + amountMajor
            : budget.spentAmount - amountMajor;

        final updatedBudget = budget.copyWith(
          spentAmount: newSpentAmount.clamp(0.0, double.infinity),
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await _budgetService!.updateBudget(updatedBudget);
        
        _logger.info(
          '✅ Savings budget updated: ${budget.name} - '
          'saved: KSh ${updatedBudget.spentAmount.toStringAsFixed(0)} / '
          'KSh ${budget.budgetAmount.toStringAsFixed(0)}'
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('Error updating savings budget', e, stackTrace);
    }
  }

  Future<void> _trackUnbudgetedSpending(Transaction transaction, bool isAddition) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedCategory = _normalizeCategory(transaction.category);
      final key = 'unbudgeted_${transaction.profileId}_$normalizedCategory';
      final currentTotal = prefs.getDouble(key) ?? 0.0;

      final amountMajor = transaction.amountMinor / 100.0; // Convert minor units to major units
      final newTotal = isAddition
          ? currentTotal + amountMajor
          : currentTotal - amountMajor;

      await prefs.setDouble(key, newTotal);
      _logger.info('📈 Unbudgeted spending tracked: $normalizedCategory - KSh ${newTotal.toStringAsFixed(0)}');
    } catch (e) {
      _logger.warning('Failed to track unbudgeted spending: $e');
    }
  }

  /// ✅ FIXED: Recalculate budgets respecting persisted category assignments
  Future<void> _recalculateBudgets(String profileId) async {
    try {
      if (_offlineDataService == null || _budgetService == null) return;

      _logger.info('🔄 Recalculating budgets for profile: $profileId');

      final transactions = await _offlineDataService!.getAllTransactions(profileId);
      final budgets = await _offlineDataService!.getAllBudgets(profileId);

      // Reset all budget spent amounts to zero first
      for (final budget in budgets.where((b) => b.isActive)) {
        final resetBudget = budget.copyWith(
          spentAmount: 0.0,
          updatedAt: DateTime.now(),
          isSynced: false,
        );
        await _budgetService!.updateBudget(resetBudget);
      }

      // Re-apply all transactions to their assigned categories
      for (final transaction in transactions.where((t) => 
        t.type == 'expense' || t.isExpense == true
      )) {
        await _updateBudgetSpending(
          transaction: transaction,
          isAddition: true,
        );
      }
      
      _logger.info('✅ Budget recalculation complete (respecting persistent categories)');
    } catch (e, stackTrace) {
      _logger.severe('Error recalculating budgets', e, stackTrace);
    }
  }

  // ==================== GOAL UPDATES ====================

  Future<void> _updateGoalProgress({
    required String goalId,
    required double amount,
    required bool isAddition,
  }) async {
    try {
      if (_offlineDataService == null) return;

      final goal = await _offlineDataService!.getGoal(goalId);
      if (goal == null) {
        _logger.warning('Goal not found: $goalId');
        return;
      }

      final newCurrentAmount = isAddition
          ? goal.currentAmount + amount
          : goal.currentAmount - amount;

      final isCompleted = newCurrentAmount >= goal.targetAmount;
      final newStatus = isCompleted ? GoalStatus.completed : goal.status;

      final updatedGoal = goal.copyWith(
        currentAmount: newCurrentAmount.clamp(0.0, goal.targetAmount),
        status: newStatus,
        completedDate: isCompleted ? DateTime.now() : goal.completedDate,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _offlineDataService!.updateGoal(updatedGoal);
      
      _logger.info('✅ Goal updated: ${goal.name} - progress: ${updatedGoal.progressPercentage.toStringAsFixed(1)}%');
      
      if (isCompleted && goal.status != GoalStatus.completed) {
        _logger.info('🎉 Goal completed: ${goal.name}');
      }
      
    } catch (e, stackTrace) {
      _logger.severe('Error updating goal progress', e, stackTrace);
    }
  }

  Future<void> _recalculateGoalProgress(String goalId) async {
    try {
      if (_offlineDataService == null) return;

      final goal = await _offlineDataService!.getGoal(goalId);
      if (goal == null) return;

      _logger.info('Recalculating goal progress: ${goal.name}');

      final allTransactions = await _offlineDataService!.getAllTransactions(goal.profileId);
      final goalTransactions = allTransactions.where((tx) =>
        tx.type == 'savings' && tx.goalId == goalId
      ).toList();

      final totalSavings = goalTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + (tx.amountMinor / 100.0), // Convert minor units to major units
      );

      if ((totalSavings - goal.currentAmount).abs() > 0.01) {
        final isCompleted = totalSavings >= goal.targetAmount;
        
        final updatedGoal = goal.copyWith(
          currentAmount: totalSavings.clamp(0.0, goal.targetAmount),
          status: isCompleted ? GoalStatus.completed : goal.status,
          completedDate: isCompleted ? DateTime.now() : goal.completedDate,
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await _offlineDataService!.updateGoal(updatedGoal);
        _logger.info('✅ Recalculated goal: ${goal.name} - KSh ${totalSavings.toStringAsFixed(0)}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error recalculating goal progress', e, stackTrace);
    }
  }

  // ==================== PUBLIC UTILITY METHODS ====================

  Future<void> recalculateAll(String profileId) async {
    _logger.info('🔄 Recalculating all budgets and goals for profile: $profileId');
    
    await _recalculateBudgets(profileId);
    
    if (_offlineDataService != null) {
      final goals = await _offlineDataService!.getAllGoals(profileId);
      for (final goal in goals) {
        if (goal.status == GoalStatus.active) {
          await _recalculateGoalProgress(goal.id!);
        }
      }
    }
    
    _logger.info('✅ Recalculation complete');
  }

  /// ✅ NEW: Reassign transactions to new budgets when categories change
  Future<void> reassignTransactionsToBudgets(String profileId) async {
    try {
      if (_offlineDataService == null) return;
      
      final transactions = await _offlineDataService!.getAllTransactions(profileId);
      
      // Clear all budget category assignments by creating new transaction objects
      for (final transaction in transactions.where((t) => 
        t.type == 'expense' || t.isExpense == true
      )) {
        final updatedTransaction = Transaction(
          id: transaction.id,
          profileId: transaction.profileId,
          amount: transaction.amountMinor / 100.0, // Convert to amount (major units)
          type: transaction.type,
          isExpense: transaction.isExpense,
          category: transaction.category,
          description: transaction.description,
          date: transaction.date,
          goalId: transaction.goalId,
          budgetCategory: null,
          currency: transaction.currency,
          isSynced: false,
          createdAt: transaction.createdAt,
          updatedAt: DateTime.now(),
        );
        await _offlineDataService!.updateTransaction(updatedTransaction);
      }
      
      // Now recalculate to assign new categories
      await _recalculateBudgets(profileId);
      
      _logger.info('🔄 All transactions reassigned to budgets');
    } catch (e, stackTrace) {
      _logger.severe('Error reassigning transactions', e, stackTrace);
    }
  }

  /// ✅ NEW: Manually assign a transaction to a specific budget category
  Future<bool> assignTransactionToBudgetCategory({
    required String transactionId,
    required String budgetCategory,
  }) async {
    try {
      if (_offlineDataService == null) return false;
      
      final transaction = await _offlineDataService!.getTransaction(transactionId);
      if (transaction == null) {
        _logger.warning('Transaction not found: $transactionId');
        return false;
      }
      
      // Create a new transaction object with the budget category
      final updatedTransaction = Transaction(
        id: transaction.id,
        profileId: transaction.profileId,
        amount: transaction.amountMinor / 100.0, // Convert to amount (major units)
        type: transaction.type,
        isExpense: transaction.isExpense,
        category: transaction.category,
        description: transaction.description,
        date: transaction.date,
        goalId: transaction.goalId,
        budgetCategory: budgetCategory,
        currency: transaction.currency,
        isSynced: false,
        createdAt: transaction.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await _offlineDataService!.updateTransaction(updatedTransaction);
      
      // Trigger a budget update with the new assignment
      await _updateBudgetSpending(
        transaction: updatedTransaction,
        isAddition: true,
      );
      
      _logger.info('✅ Manually assigned transaction to budget category: $budgetCategory');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error assigning transaction to budget category', e, stackTrace);
      return false;
    }
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}
