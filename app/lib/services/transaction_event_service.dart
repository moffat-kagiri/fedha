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
    _logger.info('Transaction created: ${transaction.id} - ${transaction.amount}');
    _eventController.add(TransactionEvent(
      type: TransactionEventType.created,
      transaction: transaction,
    ));
    notifyListeners();
  }

  Future<void> onTransactionUpdated(Transaction transaction) async {
    _logger.info('Transaction updated: ${transaction.id}');
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

    _logger.info('Processing new transaction: ${transaction.type} - ${transaction.amount}');

    // Update budgets for expense transactions
    if (transaction.type == TransactionType.expense) {
      await _updateBudgetSpending(
        transaction: transaction,
        isAddition: true,
      );
    }

    // ✅ FIX: Update goals ONLY if goalId is provided
    // Allow savings transactions without goals
    if (transaction.type == TransactionType.savings && transaction.goalId != null) {
      await _updateGoalProgress(
        goalId: transaction.goalId!,
        amount: transaction.amount,
        isAddition: true,
      );
    } else if (transaction.type == TransactionType.savings) {
      _logger.info('💰 Savings transaction without goal - general savings recorded');
    }
  }

  Future<void> _handleTransactionUpdated(Transaction transaction) async {
    await _recalculateBudgets(transaction.profileId);
    
    if (transaction.goalId != null) {
      await _recalculateGoalProgress(transaction.goalId!);
    }
  }

  Future<void> _handleTransactionDeleted(Transaction transaction) async {
    if (transaction.type == TransactionType.expense) {
      await _updateBudgetSpending(
        transaction: transaction,
        isAddition: false,
      );
    }

    if (transaction.type == TransactionType.savings && transaction.goalId != null) {
      await _updateGoalProgress(
        goalId: transaction.goalId!,
        amount: transaction.amount,
        isAddition: false,
      );
    }
  }

  // ==================== BUDGET UPDATES (ENHANCED) ====================

  /// ✅ FIX: Normalize category IDs for proper matching
  String _normalizeCategoryId(String categoryId) {
    // Convert to lowercase and trim
    final normalized = categoryId.toLowerCase().trim();
    
    // Map common variations to standard names
    final categoryMap = {
      'other': 'other',
      'others': 'other',
      'other expense': 'other',
      'other income': 'other',
      'miscellaneous': 'other',
      'misc': 'other',
    };
    
    return categoryMap[normalized] ?? normalized;
  }

  /// ✅ FIX: Check if categories match (handles "other" variations)
  bool _categoriesMatch(String categoryId1, String categoryId2) {
    return _normalizeCategoryId(categoryId1) == _normalizeCategoryId(categoryId2);
  }

  Future<void> _updateBudgetSpending({
    required Transaction transaction,
    required bool isAddition,
  }) async {
    try {
      if (_offlineDataService == null || _budgetService == null) return;

      final budgets = await _offlineDataService!.getAllBudgets(transaction.profileId);

      // ✅ FIX: Use normalized category matching
      final matchingBudgets = budgets.where((b) => 
        _categoriesMatch(b.categoryId, transaction.categoryId) &&
        b.isActive &&
        !transaction.date.isBefore(b.startDate) &&
        !transaction.date.isAfter(b.endDate)
      ).toList();

      if (matchingBudgets.isEmpty) {
        _logger.info(
          '📊 Unbudgeted expense: ${transaction.categoryId} '
          '(KSh ${transaction.amount}) on ${transaction.date.toString().split(' ')[0]}'
        );
        
        await _trackUnbudgetedSpending(transaction, isAddition);
        return;
      }

      for (final budget in matchingBudgets) {
        final newSpentAmount = isAddition
            ? budget.spentAmount + transaction.amount
            : budget.spentAmount - transaction.amount;

        final updatedBudget = budget.copyWith(
          spentAmount: newSpentAmount.clamp(0.0, double.infinity),
          updatedAt: DateTime.now(),
          isSynced: false,
        );

        await _budgetService!.updateBudget(updatedBudget);
        
        _logger.info(
          '✅ Budget updated: ${budget.name} - '
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
    } catch (e, stackTrace) {
      _logger.severe('Error updating budget spending', e, stackTrace);
    }
  }

  Future<void> _trackUnbudgetedSpending(Transaction transaction, bool isAddition) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedCategory = _normalizeCategoryId(transaction.categoryId);
      final key = 'unbudgeted_${transaction.profileId}_$normalizedCategory';
      final currentTotal = prefs.getDouble(key) ?? 0.0;

      final newTotal = isAddition
          ? currentTotal + transaction.amount
          : currentTotal - transaction.amount;

      await prefs.setDouble(key, newTotal);
      _logger.info('📈 Unbudgeted spending tracked: $normalizedCategory - KSh ${newTotal.toStringAsFixed(0)}');
    } catch (e) {
      _logger.warning('Failed to track unbudgeted spending: $e');
    }
  }

  /// ✅ FIX: Recalculate with normalized category matching
  Future<void> _recalculateBudgets(String profileId) async {
    try {
      if (_offlineDataService == null || _budgetService == null) return;

      _logger.info('🔄 Recalculating budgets for profile: $profileId');

      final transactions = await _offlineDataService!.getAllTransactions(profileId);
      final budgets = await _offlineDataService!.getAllBudgets(profileId);

      for (final budget in budgets.where((b) => b.isActive)) {
        // ✅ FIX: Use normalized category matching
        final budgetTransactions = transactions.where((tx) =>
          tx.type == TransactionType.expense &&
          _categoriesMatch(tx.categoryId, budget.categoryId) &&
          !tx.date.isBefore(budget.startDate) &&
          !tx.date.isAfter(budget.endDate)
        ).toList();

        final totalSpent = budgetTransactions.fold<double>(
          0.0,
          (sum, tx) => sum + tx.amount,
        );

        if ((totalSpent - budget.spentAmount).abs() > 0.01) {
          final updatedBudget = budget.copyWith(
            spentAmount: totalSpent,
            updatedAt: DateTime.now(),
            isSynced: false,
          );

          await _budgetService!.updateBudget(updatedBudget);
          _logger.info('✅ Recalculated budget: ${budget.name} - ${totalSpent.toStringAsFixed(2)}/${budget.budgetAmount.toStringAsFixed(2)}');
        }
      }
      
      _logger.info('✅ Budget recalculation complete');
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
      
      if (isCompleted && !goal.isCompleted) {
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
        tx.type == TransactionType.savings && tx.goalId == goalId
      ).toList();

      final totalSavings = goalTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
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
        _logger.info('✅ Recalculated goal: ${goal.name} - $totalSavings');
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

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}
