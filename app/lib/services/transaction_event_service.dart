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
  approved, // From pending to confirmed
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
/// to budgets and goals automatically
class TransactionEventService extends ChangeNotifier {
  static TransactionEventService? _instance;
  static TransactionEventService get instance => _instance ??= TransactionEventService._();

  final _logger = AppLogger.getLogger('TransactionEventService');
  final _eventController = StreamController<TransactionEvent>.broadcast();
  
  OfflineDataService? _offlineDataService;
  BudgetService? _budgetService;
  String? _currentProfileId;

  TransactionEventService._();

  /// Stream of transaction events
  Stream<TransactionEvent> get eventStream => _eventController.stream;

  /// Initialize with dependencies
  Future<void> initialize({
    required OfflineDataService offlineDataService,
    required BudgetService budgetService,
  }) async {
    _offlineDataService = offlineDataService;
    _budgetService = budgetService;
    
    // Listen to transaction events and process them
    _eventController.stream.listen(_handleTransactionEvent);
    
    _logger.info('TransactionEventService initialized');
  }

  /// Set current profile
  void setCurrentProfile(String profileId) {
    _currentProfileId = profileId;
    _logger.info('Current profile set: $profileId');
  }

  // ==================== EVENT EMITTERS ====================

  /// Emit transaction created event
  Future<void> onTransactionCreated(Transaction transaction) async {
    _logger.info('Transaction created: ${transaction.id} - ${transaction.amount}');
    _eventController.add(TransactionEvent(
      type: TransactionEventType.created,
      transaction: transaction,
    ));
    notifyListeners();
  }

  /// Emit transaction updated event
  Future<void> onTransactionUpdated(Transaction transaction) async {
    _logger.info('Transaction updated: ${transaction.id}');
    _eventController.add(TransactionEvent(
      type: TransactionEventType.updated,
      transaction: transaction,
    ));
    notifyListeners();
  }

  /// Emit transaction deleted event
  Future<void> onTransactionDeleted(Transaction transaction) async {
    _logger.info('Transaction deleted: ${transaction.id}');
    _eventController.add(TransactionEvent(
      type: TransactionEventType.deleted,
      transaction: transaction,
    ));
    notifyListeners();
  }

  /// Emit transaction approved event (from pending)
  Future<void> onTransactionApproved(Transaction transaction) async {
    _logger.info('Transaction approved: ${transaction.id}');
    _eventController.add(TransactionEvent(
      type: TransactionEventType.approved,
      transaction: transaction,
    ));
    notifyListeners();
  }

  // ==================== EVENT HANDLERS ====================

  /// Handle transaction events and trigger updates
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

  /// Handle new transaction - update budgets and goals
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

    // Update goals for savings transactions
    if (transaction.type == TransactionType.savings && transaction.goalId != null) {
      await _updateGoalProgress(
        goalId: transaction.goalId!,
        amount: transaction.amount,
        isAddition: true,
      );
    }
  }

  /// Handle transaction update
  Future<void> _handleTransactionUpdated(Transaction transaction) async {
    // For updates, we need to recalculate everything
    // This is safer than trying to calculate the delta
    await _recalculateBudgets(transaction.profileId);
    
    if (transaction.goalId != null) {
      await _recalculateGoalProgress(transaction.goalId!);
    }
  }

  /// Handle transaction deletion
  Future<void> _handleTransactionDeleted(Transaction transaction) async {
    // Update budgets for expense transactions
    if (transaction.type == TransactionType.expense) {
      await _updateBudgetSpending(
        transaction: transaction,
        isAddition: false,
      );
    }

    // Update goals for savings transactions
    if (transaction.type == TransactionType.savings && transaction.goalId != null) {
      await _updateGoalProgress(
        goalId: transaction.goalId!,
        amount: transaction.amount,
        isAddition: false,
      );
    }
  }

  // ==================== BUDGET UPDATES (ENHANCED) ====================

  /// Update budget spending based on transaction (ENHANCED)
  Future<void> _updateBudgetSpending({
    required Transaction transaction,
    required bool isAddition,
  }) async {
    try {
      if (_offlineDataService == null || _budgetService == null) return;

      // Get all budgets for this profile
      final budgets = await _offlineDataService!.getAllBudgets(transaction.profileId);

      // Find matching budgets (active and date-appropriate)
      final matchingBudgets = budgets.where((b) => 
        b.categoryId == transaction.categoryId &&
        b.isActive &&
        !transaction.date.isBefore(b.startDate) &&
        !transaction.date.isAfter(b.endDate)
      ).toList();

      if (matchingBudgets.isEmpty) {
        // ✅ IMPROVED: Log but don't treat as error - track unbudgeted spending
        _logger.info(
          '📊 Unbudgeted expense: ${transaction.categoryId} '
          '(KSh ${transaction.amount}) on ${transaction.date.toString().split(' ')[0]}'
        );
        
        // Could create a separate "unbudgeted spending" tracker here
        await _trackUnbudgetedSpending(transaction, isAddition);
        return;
      }

      // Update all matching budgets (usually just one, but could be multiple)
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
        
        // Check if budget exceeded
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

  /// Track unbudgeted spending for analysis (NEW)
  Future<void> _trackUnbudgetedSpending(Transaction transaction, bool isAddition) async {
    try {
      // Store unbudgeted spending summary in SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      final key = 'unbudgeted_${transaction.profileId}_${transaction.categoryId}';
      final currentTotal = prefs.getDouble(key) ?? 0.0;

      final newTotal = isAddition
          ? currentTotal + transaction.amount
          : currentTotal - transaction.amount;

      await prefs.setDouble(key, newTotal);
      _logger.info('📈 Unbudgeted spending tracked: ${transaction.categoryId} - KSh ${newTotal.toStringAsFixed(0)}');
    } catch (e) {
      _logger.warning('Failed to track unbudgeted spending: $e');
    }
  }

  /// 🔴 FIXED: Recalculate all budgets with proper date filtering
  Future<void> _recalculateBudgets(String profileId) async {
    try {
      if (_offlineDataService == null || _budgetService == null) return;

      _logger.info('🔄 Recalculating budgets for profile: $profileId');

      // Get all transactions and budgets
      final transactions = await _offlineDataService!.getAllTransactions(profileId);
      final budgets = await _offlineDataService!.getAllBudgets(profileId);

      // Recalculate spending for each active budget
      for (final budget in budgets.where((b) => b.isActive)) {
        // 🔴 CRITICAL: Filter transactions within budget period
        final budgetTransactions = transactions.where((tx) =>
          tx.type == TransactionType.expense &&
          tx.categoryId == budget.categoryId &&
          !tx.date.isBefore(budget.startDate) &&
          !tx.date.isAfter(budget.endDate)
        ).toList();

        // Calculate total spending
        final totalSpent = budgetTransactions.fold<double>(
          0.0,
          (sum, tx) => sum + tx.amount,
        );

        // Update budget if spending changed
        if ((totalSpent - budget.spentAmount).abs() > 0.01) { // Use small epsilon for float comparison
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

  // ==================== GOAL UPDATES (Unchanged) ====================

  /// Update goal progress based on transaction
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

      // Calculate new current amount
      final newCurrentAmount = isAddition
          ? goal.currentAmount + amount
          : goal.currentAmount - amount;

      // Determine if goal is now completed
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
      
      // Notify if goal completed
      if (isCompleted && !goal.isCompleted) {
        _logger.info('🎉 Goal completed: ${goal.name}');
      }
      
    } catch (e, stackTrace) {
      _logger.severe('Error updating goal progress', e, stackTrace);
    }
  }

  /// Recalculate goal progress from all linked transactions
  Future<void> _recalculateGoalProgress(String goalId) async {
    try {
      if (_offlineDataService == null) return;

      final goal = await _offlineDataService!.getGoal(goalId);
      if (goal == null) return;

      _logger.info('Recalculating goal progress: ${goal.name}');

      // Get all transactions linked to this goal
      final allTransactions = await _offlineDataService!.getAllTransactions(goal.profileId);
      final goalTransactions = allTransactions.where((tx) =>
        tx.type == TransactionType.savings && tx.goalId == goalId
      ).toList();

      // Calculate total savings
      final totalSavings = goalTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
      );

      // Update goal if progress changed
      if ((totalSavings - goal.currentAmount).abs() > 0.01) { // Use epsilon for float comparison
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

  /// Manually trigger recalculation for all budgets and goals
  /// 🔴 NEW: Call this when app starts to ensure data consistency
  Future<void> recalculateAll(String profileId) async {
    _logger.info('🔄 Recalculating all budgets and goals for profile: $profileId');
    
    // Recalculate budgets
    await _recalculateBudgets(profileId);
    
    // Recalculate all active goals
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

  /// Dispose resources
  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}