// lib/services/goal_transaction_service.dart

import '../models/goal.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import 'offline_data_service.dart';
import 'transaction_event_service.dart';
import '../utils/logger.dart';

/// Service for linking transactions to goals and managing goal contributions
/// ✅ This is a HIGH-LEVEL service that EMITS EVENTS after storage operations
class GoalTransactionService {
  final OfflineDataService _offlineService;
  final _logger = AppLogger.getLogger('GoalTransactionService');

  GoalTransactionService(this._offlineService);

  /// Links a transaction to a goal and updates goal progress
  /// Accepts income or savings transactions as contributions
  /// ✅ EMITS EVENT after storage
  Future<void> linkTransactionToGoal(Transaction transaction, String goalId) async {
    if (transaction.type != TransactionType.income && transaction.type != TransactionType.savings) {
      return; // Only income/savings transactions can contribute to goals
    }

    final goal = await _offlineService.getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }

    // Update transaction with goal reference
    final updatedTransaction = transaction.copyWith(goalId: goalId);
    
    // Save to database (no event emitted by saveTransaction)
    await _offlineService.saveTransaction(updatedTransaction);
    
    // ✅ EMIT EVENT - This is the high-level operation
    final eventService = TransactionEventService.instance;
    await eventService.onTransactionCreated(updatedTransaction);
    
    _logger.info('✅ Transaction linked to goal: ${goal.name}');
  }

  /// Creates a savings transaction specifically for a goal
  /// ✅ EMITS EVENT after storage (NO manual goal update)
  Future<Transaction> createSavingsTransaction({
    required double amount,
    required String goalId,
    String? description,
    String? categoryId,
    DateTime? date,
  }) async {
    final goal = await _offlineService.getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }

    _logger.info('💰 Creating savings transaction for goal: ${goal.name} - Amount: $amount');

    // Create the savings transaction
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: TransactionType.savings,
      categoryId: categoryId ?? 'savings',
      date: date ?? DateTime.now(),
      description: description ?? 'Savings contribution for ${goal.name}',
      goalId: goalId,
      profileId: goal.profileId,
    );

    // Save transaction (no event emitted by saveTransaction)
    await _offlineService.saveTransaction(transaction);
    
    // ✅ EMIT EVENT - This triggers the event service to update the goal
    final eventService = TransactionEventService.instance;
    await eventService.onTransactionCreated(transaction);
    
    _logger.info('✅ Savings transaction saved - Event system will update goal progress');
    
    return transaction;
  }

  /// Unlinks a transaction from a goal and reverses the contribution
  /// ✅ EMITS EVENT after storage
  Future<void> unlinkTransactionFromGoal(String transactionId, String profileId) async {
    final transactions = await _offlineService.getAllTransactions(profileId);
    final matches = transactions.where((t) => t.id == transactionId).toList();
    if (matches.isEmpty) return;

    final transaction = matches.first;
    if (transaction.goalId == null) return;

    _logger.info('Unlinking transaction from goal: ${transaction.goalId}');

    // Remove goal reference from transaction
    final updatedTransaction = transaction.copyWith(goalId: null);
    
    // Save to database (no event)
    await _offlineService.updateTransaction(updatedTransaction);
    
    // ✅ EMIT EVENT - This triggers recalculation
    final eventService = TransactionEventService.instance;
    await eventService.onTransactionUpdated(updatedTransaction);
    
    _logger.info('✅ Transaction unlinked - Event system will recalculate goal');
  }

  /// Gets all transactions linked to a specific goal for a profile
  Future<List<Transaction>> getTransactionsForGoal(String profileId, String goalId) async {
    final all = await _offlineService.getAllTransactions(profileId);
    return all.where((transaction) => transaction.goalId == goalId).toList();
  }

  /// Gets suggested goals for a transaction based on transaction type and amount
  Future<List<Goal>> getSuggestedGoalsForTransaction(Transaction transaction) async {
    if (transaction.type != TransactionType.income && transaction.type != TransactionType.savings) {
      return [];
    }

    final allGoals = await _offlineService.getAllGoals(transaction.profileId);
    final activeGoals = allGoals.where((goal) => goal.status == GoalStatus.active && !goal.isCompleted).toList();

    // Filter goals based on relevance to transaction
    return activeGoals.where((goal) {
      final bool isRelevant =
          (goal.goalType == GoalType.savings && transaction.amount >= 100) ||
          (goal.goalType == GoalType.investment && transaction.amount >= 500) ||
          (goal.goalType == GoalType.emergencyFund && transaction.amount >= 200) ||
          (goal.amountNeeded >= transaction.amount * 0.8);

      return isRelevant;
    }).toList();
  }

  /// Transfers funds from one goal to another
  /// ✅ EMITS EVENTS for both transactions
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

    // Create withdrawal transaction from source goal
    final withdrawalTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: TransactionType.expense,
      categoryId: 'goal_transfer',
      date: DateTime.now(),
      description: description ?? 'Transfer to ${toGoal.name}',
      goalId: fromGoalId,
      profileId: fromGoal.profileId,
    );

    // Create deposit transaction to target goal
    final depositTransaction = Transaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_deposit',
      amount: amount,
      type: TransactionType.savings,
      categoryId: 'goal_transfer',
      date: DateTime.now(),
      description: description ?? 'Transfer from ${fromGoal.name}',
      goalId: toGoalId,
      profileId: toGoal.profileId,
    );

    final eventService = TransactionEventService.instance;
    
    // Save both transactions and emit events
    await _offlineService.saveTransaction(withdrawalTransaction);
    await eventService.onTransactionCreated(withdrawalTransaction);
    
    await _offlineService.saveTransaction(depositTransaction);
    await eventService.onTransactionCreated(depositTransaction);
    
    _logger.info('✅ Transfer complete - Event system will update both goals');
  }

  /// Gets the total amount contributed to a goal from transactions
  Future<double> getTotalContributions(String profileId, String goalId) async {
    final goalTransactions = await getTransactionsForGoal(profileId, goalId);
    double total = 0.0;
    for (final transaction in goalTransactions) {
      if (transaction.type == TransactionType.savings) {
        total += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        total -= transaction.amount;
      }
    }
    return total;
  }

  /// Verify goal amount matches transaction total
  /// Useful for debugging and data integrity checks
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

  /// Recalculate goal amount from transactions (for fixing data issues)
  /// ⚠️ Use TransactionEventService.recalculateAll() instead for production
  Future<void> recalculateGoalAmount(String goalId, String profileId) async {
    final eventService = TransactionEventService.instance;
    await eventService.recalculateAll(profileId);
  }
}
