import '../models/goal.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import 'offline_data_service.dart';

class GoalTransactionService {
  final OfflineDataService _offlineService;

  GoalTransactionService(this._offlineService);

  /// Links a transaction to a goal and updates goal progress
  /// Accepts income or savings transactions as contributions
  Future<void> linkTransactionToGoal(Transaction transaction, String goalId) async {
    if (transaction.type != TransactionType.income && transaction.type != TransactionType.savings) {
      return; // Only income/savings transactions can contribute to goals
    }

    final goal = await _offlineService.getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }

    // Update goal with contribution
    final updatedGoal = goal.addContribution(transaction.amount);
    await _offlineService.updateGoal(updatedGoal);

    // Update transaction with goal reference
    final updatedTransaction = transaction.copyWith(goalId: goalId);
    await _offlineService.saveTransaction(updatedTransaction);
  }

  /// Creates a savings transaction specifically for a goal
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

    // Save transaction
    await _offlineService.saveTransaction(transaction);

    // Update goal progress
    final updatedGoal = goal.addContribution(amount);
    await _offlineService.updateGoal(updatedGoal);

    return transaction;
  }

  /// Unlinks a transaction from a goal and reverses the contribution
  /// Requires the profileId to locate the transaction in the local store
  Future<void> unlinkTransactionFromGoal(String transactionId, String profileId) async {
    final transactions = await _offlineService.getAllTransactions(profileId);
    final matches = transactions.where((t) => t.id == transactionId).toList();
    if (matches.isEmpty) return; // No transaction found

    final transaction = matches.first;
    if (transaction.goalId == null) return; // No goal linked

    final goal = await _offlineService.getGoal(transaction.goalId!);
    if (goal == null) return; // Goal not found

    // Reverse the contribution (subtract the amount)
    final updatedGoal = goal.addContribution(-transaction.amount);
    await _offlineService.updateGoal(updatedGoal);

    // Remove goal reference from transaction
    final updatedTransaction = transaction.copyWith(goalId: null);
    await _offlineService.saveTransaction(updatedTransaction);
  }

  /// Gets all transactions linked to a specific goal for a profile
  Future<List<Transaction>> getTransactionsForGoal(String profileId, String goalId) async {
    final all = await _offlineService.getAllTransactions(profileId);
    return all.where((transaction) => transaction.goalId == goalId).toList();
  }

  /// Gets suggested goals for a transaction based on transaction type and amount
  Future<List<Goal>> getSuggestedGoalsForTransaction(Transaction transaction) async {
    if (transaction.type != TransactionType.income && transaction.type != TransactionType.savings) {
      return []; // Only suggest goals for income/savings transactions
    }

    final allGoals = await _offlineService.getAllGoals(transaction.profileId);
    final activeGoals = allGoals.where((goal) => goal.status == GoalStatus.active && !goal.isCompleted).toList();

    // Filter goals based on relevance to transaction
    return activeGoals.where((goal) {
      final bool isRelevant =
          (goal.goalType == GoalType.savings && transaction.amount >= 100) ||
          (goal.goalType == GoalType.investment && transaction.amount >= 500) ||
          (goal.goalType == GoalType.emergencyFund && transaction.amount >= 200) ||
          (goal.amountNeeded >= transaction.amount * 0.8); // Goal can absorb most of this transaction

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

    // Update goals
    final updatedFromGoal = fromGoal.addContribution(-amount);
    final updatedToGoal = toGoal.addContribution(amount);

    // Save all changes
    await _offlineService.saveTransaction(withdrawalTransaction);
    await _offlineService.saveTransaction(depositTransaction);
    await _offlineService.updateGoal(updatedFromGoal);
    await _offlineService.updateGoal(updatedToGoal);
  }

  /// Gets the total amount contributed to a goal from transactions
  Future<double> getTotalContributions(String profileId, String goalId) async {
    final goalTransactions = await getTransactionsForGoal(profileId, goalId);
    double total = 0.0;
    for (final transaction in goalTransactions) {
      total += transaction.amount;
    }
    return total;
  }
}