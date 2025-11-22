import '../models/goal.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import 'offline_data_service.dart';

class GoalTransactionService {
  final OfflineDataService _offlineService;

  GoalTransactionService(this._offlineService);

  /// Links a transaction to a goal and updates goal progress
  /// Only income transactions can contribute to goals
  Future<void> linkTransactionToGoal(Transaction transaction, String goalId) async {
    if (transaction.type != TransactionType.income) {
      return; // Only income transactions can contribute to goals
    }
    
    final goal = _offlineService.getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }

    // Update goal with contribution
    final updatedGoal = goal.addContribution(transaction.amount);
    await _offlineService.saveGoal(updatedGoal);
    
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
    final goal = _offlineService.getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found: $goalId');
    }

    // Create the savings transaction
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: TransactionType.income,
      categoryId: categoryId ?? 'savings',
      date: date ?? DateTime.now(),
      description: description ?? 'Savings contribution for ${goal.name}',
      goalId: goalId,
      profileId: goal.profileId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save transaction
    await _offlineService.saveTransaction(transaction);
    
    // Update goal progress
    final updatedGoal = goal.addContribution(amount);
    await _offlineService.saveGoal(updatedGoal);
    
    return transaction;
  }

  /// Unlinks a transaction from a goal and reverses the contribution
  Future<void> unlinkTransactionFromGoal(String transactionId) async {
    final transaction = _offlineService.getTransaction(transactionId);
    if (transaction == null || transaction.goalId == null) {
      return; // No goal linked or transaction not found
    }

    final goal = _offlineService.getGoal(transaction.goalId!);
    if (goal == null) {
      return; // Goal not found
    }

    // Reverse the contribution (subtract the amount)
    final updatedGoal = goal.addContribution(-transaction.amount);
    await _offlineService.saveGoal(updatedGoal);
    
    // Remove goal reference from transaction
    final updatedTransaction = transaction.copyWith(goalId: null);
    await _offlineService.saveTransaction(updatedTransaction);
  }

  /// Gets all transactions linked to a specific goal
  List<Transaction> getTransactionsForGoal(String goalId) {
    return _offlineService.getAllTransactions()
        .where((transaction) => transaction.goalId == goalId)
        .toList();
  }

  /// Gets suggested goals for a transaction based on transaction type and amount
  List<Goal> getSuggestedGoalsForTransaction(Transaction transaction) {
    if (transaction.type != TransactionType.income) {
      return []; // Only suggest goals for income transactions
    }

    final activeGoals = _offlineService.getAllGoals()
        .where((goal) => goal.isActive && !goal.isCompleted)
        .toList();

    // Filter goals based on relevance to transaction
    return activeGoals.where((goal) {
      // Suggest goals that are not yet completed and match the transaction context
      final bool isRelevant = 
          (goal.goalType == GoalType.savings && transaction.amount >= 100) ||
          (goal.goalType == GoalType.investment && transaction.amount >= 500) ||
          (goal.goalType == GoalType.emergency && transaction.amount >= 200) ||
          (goal.remainingAmount >= transaction.amount * 0.8); // Goal can absorb most of this transaction

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

    final fromGoal = _offlineService.getGoal(fromGoalId);
    final toGoal = _offlineService.getGoal(toGoalId);

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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create deposit transaction to target goal
    final depositTransaction = Transaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_deposit',
      amount: amount,
      type: TransactionType.income,
      categoryId: 'goal_transfer',
      date: DateTime.now(),
      description: description ?? 'Transfer from ${fromGoal.name}',
      goalId: toGoalId,
      profileId: toGoal.profileId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Update goals
    final updatedFromGoal = fromGoal.addContribution(-amount);
    final updatedToGoal = toGoal.addContribution(amount);

    // Save all changes
    await _offlineService.saveTransaction(withdrawalTransaction);
    await _offlineService.saveTransaction(depositTransaction);
    await _offlineService.saveGoal(updatedFromGoal);
    await _offlineService.saveGoal(updatedToGoal);
  }

  /// Gets the total amount contributed to a goal from transactions
  double getTotalContributions(String goalId) {
    final goalTransactions = getTransactionsForGoal(goalId);
    return goalTransactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }
}