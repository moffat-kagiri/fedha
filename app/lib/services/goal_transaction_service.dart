// lib/services/goal_transaction_service.dart

import '../models/goal.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import 'offline_data_service.dart';
import 'transaction_event_service.dart';
import '../utils/logger.dart';

/// Service for linking transactions to goals and managing goal contributions
class GoalTransactionService {
  final OfflineDataService _offlineService;
  final _logger = AppLogger.getLogger('GoalTransactionService');

  GoalTransactionService(this._offlineService);

  /// ✅ FIX: Allow general savings without linking to a goal
  /// Creates a savings transaction that can optionally be linked to a goal
  Future<Transaction> createSavingsTransaction({
    required double amount,
    String? goalId, // ✅ NOW OPTIONAL
    String? description,
    String? category,
    DateTime? date,
    required String profileId, // ✅ ADDED: Need profileId for general savings
  }) async {
    // ✅ FIX: Validate goal exists if goalId provided
    if (goalId != null) {
      final goal = await _offlineService.getGoal(goalId);
      if (goal == null) {
        throw Exception('Goal not found: $goalId');
      }
      _logger.info('💰 Creating savings transaction for goal: ${goal.name} - Amount: $amount');
    } else {
      _logger.info('💰 Creating general savings transaction - Amount: $amount');
    }

    // Convert amount to minor units for the transaction
    final amountMinor = (amount * 100).toInt();

    // Create the savings transaction
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileId: profileId,
      amount: (amountMinor/100.0), // Store as major units
      type: 'savings', // ✅ Use string 'savings' instead of Type.savings
      isExpense: false,
      category: category ?? 'savings',
      description: description ?? (goalId != null 
          ? 'Savings contribution' 
          : 'General savings'),
      date: date ?? DateTime.now(),
      goalId: goalId, // ✅ Can be null for general savings
      currency: 'KES',
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save transaction
    await _offlineService.saveTransaction(transaction);
    
    // Emit event - this will update goal if goalId is provided
    final eventService = TransactionEventService.instance;
    await eventService.onTransactionCreated(transaction);
    
    _logger.info('✅ Savings transaction saved - Event system will update goal if linked');
    
    return transaction;
  }

  /// Links a transaction to a goal and updates goal progress
  Future<void> linkTransactionToGoal(Transaction transaction, String goalId) async {
    // Check if transaction is income or savings type
    if (transaction.type != 'income' && transaction.type != 'savings') {
      return;
    }

    final goal = await _offlineService.getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }

    final updatedTransaction = transaction.copyWith(
      goalId: goalId,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    
    await _offlineService.saveTransaction(updatedTransaction);
    
    final eventService = TransactionEventService.instance;
    await eventService.onTransactionUpdated(updatedTransaction);
    
    _logger.info('✅ Transaction linked to goal: ${goal.name}');
  }

  /// Unlinks a transaction from a goal
  Future<void> unlinkTransactionFromGoal(String transactionId, String profileId) async {
    final transaction = await _offlineService.getTransaction(transactionId);
    if (transaction == null || transaction.goalId == null) return;

    _logger.info('Unlinking transaction from goal: ${transaction.goalId}');

    final updatedTransaction = transaction.copyWith(
      goalId: null,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    
    await _offlineService.updateTransaction(updatedTransaction);
    
    final eventService = TransactionEventService.instance;
    await eventService.onTransactionUpdated(updatedTransaction);
    
    _logger.info('✅ Transaction unlinked - Event system will recalculate goal');
  }

  /// Gets all transactions linked to a specific goal
  Future<List<Transaction>> getTransactionsForGoal(String profileId, String goalId) async {
    final all = await _offlineService.getAllTransactions(profileId);
    return all.where((transaction) => transaction.goalId == goalId).toList();
  }

  /// ✅ NEW: Gets all general savings (not linked to any goal)
  Future<List<Transaction>> getGeneralSavings(String profileId) async {
    final all = await _offlineService.getAllTransactions(profileId);
    return all.where((transaction) => 
      transaction.type == 'savings' && 
      transaction.goalId == null
    ).toList();
  }

  /// ✅ NEW: Calculate total general savings
  Future<double> getTotalGeneralSavings(String profileId) async {
    final generalSavings = await getGeneralSavings(profileId);
    double total = 0.0;
    for (final tx in generalSavings) {
      total += tx.amountMinor / 100.0; // Convert minor units to major units
    }
    return total;
  }

  /// Gets suggested goals for a transaction
  Future<List<Goal>> getSuggestedGoalsForTransaction(Transaction transaction) async {
    // Only suggest goals for income or savings transactions
    if (transaction.type != 'income' && transaction.type != 'savings') {
      return [];
    }

    final allGoals = await _offlineService.getAllGoals(transaction.profileId);
    final activeGoals = allGoals.where((goal) => goal.status == GoalStatus.active).toList();

    // Convert amount to major units for comparison
    final amountMajor = transaction.amountMinor / 100.0;

    return activeGoals.where((goal) {
      final bool isRelevant =
          (goal.goalType == GoalType.savings && amountMajor >= 100) ||
          (goal.goalType == GoalType.investment && amountMajor >= 500) ||
          (goal.goalType == GoalType.emergencyFund && amountMajor >= 200) ||
          ((goal.targetAmount - goal.currentAmount) >= amountMajor * 0.8);

      return isRelevant;
    }).toList();
  }

  /// Transfers funds from one goal to another
  Future<void> transferBetweenGoals({
    required String fromGoalId,
    required String toGoalId,
    required double amount,
    String? description,
  }) async {
    if (amount <= 0) {
      throw Exception('Transfer amount must be positive');
    }

    final fromGoal = await _offlineService.getGoal(fromGoalId);
    final toGoal = await _offlineService.getGoal(toGoalId);

    if (fromGoal == null || toGoal == null) {
      throw Exception('One or both goals not found');
    }

    if (fromGoal.currentAmount < amount) {
      throw Exception('Insufficient funds in source goal');
    }

    _logger.info('Transferring $amount from ${fromGoal.name} to ${toGoal.name}');

    // Convert amount to minor units
    final amountMinor = (amount * 100).toInt();

    // Withdrawal from source goal (as expense)
    final withdrawalTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileId: fromGoal.profileId,
      amount: (amountMinor / 100.0), // Store as major units
      type: 'expense', // ✅ Use string 'expense'
      isExpense: true,
      category: 'goal_transfer',
      description: description ?? 'Transfer to ${toGoal.name}',
      date: DateTime.now(),
      goalId: fromGoalId,
      currency: 'KES',
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Deposit to target goal (as savings)
    final depositTransaction = Transaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_deposit',
      profileId: toGoal.profileId,
      amount: (amountMinor / 100.0), // Store as major units
      type: 'savings', // ✅ Use string 'savings'
      isExpense: false,
      category: 'goal_transfer',
      description: description ?? 'Transfer from ${fromGoal.name}',
      date: DateTime.now(),
      goalId: toGoalId,
      currency: 'KES',
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final eventService = TransactionEventService.instance;
    
    await _offlineService.saveTransaction(withdrawalTransaction);
    await eventService.onTransactionCreated(withdrawalTransaction);
    
    await _offlineService.saveTransaction(depositTransaction);
    await eventService.onTransactionCreated(depositTransaction);
    
    _logger.info('✅ Transfer complete - Event system will update both goals');
  }

  /// Gets the total amount contributed to a goal
  Future<double> getTotalContributions(String profileId, String goalId) async {
    final goalTransactions = await getTransactionsForGoal(profileId, goalId);
    double total = 0.0;
    for (final transaction in goalTransactions) {
      final amountMajor = transaction.amountMinor / 100.0;
      if (transaction.type == 'savings') {
        total += amountMajor;
      } else if (transaction.type == 'expense') {
        total -= amountMajor;
      }
    }
    return total;
  }

  /// Verify goal amount matches transaction total
  Future<bool> verifyGoalAmount(String goalId, String profileId) async {
    final goal = await _offlineService.getGoal(goalId);
    if (goal == null) return false;

    final calculatedAmount = await getTotalContributions(profileId, goalId);
    final difference = (goal.currentAmount - calculatedAmount).abs();
    
    if (difference > 0.01) {
      _logger.warning(
        'Goal amount mismatch for ${goal.name}: '
        'Stored: ${goal.currentAmount}, Calculated: $calculatedAmount'
      );
      return false;
    }
    
    return true;
  }

  /// Recalculate goal amount from transactions
  Future<void> recalculateGoalAmount(String goalId, String profileId) async {
    final eventService = TransactionEventService.instance;
    await eventService.recalculateAll(profileId);
  }
}
