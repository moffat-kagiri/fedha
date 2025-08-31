import 'package:drift/drift.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import 'offline_data_service.dart';

class GoalTransactionService {
  final OfflineDataService _offlineService;

  GoalTransactionService(this._offlineService);

  Future<void> updateGoalProgress(String goalId, double amount) async {
    final goal = _offlineService.getGoal(goalId);
    if (goal == null) return;

    final updatedGoal = GoalsCompanion(
      id: Value(goal.id),
      name: Value(goal.name),
      description: Value(goal.description),
      targetAmount: Value(goal.targetAmount),
      currentAmount: Value(goal.currentAmount + amount),
      targetDate: Value(goal.targetDate),
      priority: Value(goal.priority),
      status: Value(goal.status),
      isActive: Value(goal.isActive),
      goalType: Value(goal.goalType),
      currency: Value(goal.currency),
      profileId: Value(goal.profileId),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(DateTime.now()),
    );

    await _offlineService.saveGoal(updatedGoal);
  }

  Future<void> linkTransactionToGoal(Transaction transaction, String goalId) async {
    if (transaction.type == TransactionType.expense) return;
    
    await updateGoalProgress(goalId, transaction.amount);
  }

  List<Goal> getActiveGoals() {
    return _offlineService.getAllGoals()
        .where((goal) => goal.isActive && goal.status == 'active')
        .toList();
  }

  double calculateGoalProgress(Goal goal) {
    if (goal.targetAmount <= 0) return 0.0;
    return (goal.currentAmount / goal.targetAmount * 100).clamp(0.0, 100.0);
  }

  List<Goal> getCompletedGoals() {
    return _offlineService.getAllGoals()
        .where((goal) => goal.status == 'completed' || goal.currentAmount >= goal.targetAmount)
        .toList();
  }

  Future<void> markGoalAsCompleted(String goalId) async {
    final goal = _offlineService.getGoal(goalId);
    if (goal == null) return;

    final updatedGoal = GoalsCompanion(
      id: Value(goal.id),
      name: Value(goal.name),
      description: Value(goal.description),
      targetAmount: Value(goal.targetAmount),
      currentAmount: Value(goal.currentAmount),
      targetDate: Value(goal.targetDate),
      priority: Value(goal.priority),
      status: const Value('completed'),
      isActive: Value(goal.isActive),
      goalType: Value(goal.goalType),
      currency: Value(goal.currency),
      profileId: Value(goal.profileId),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(DateTime.now()),
    );

    await _offlineService.saveGoal(updatedGoal);
  }

  List<Goal> getSuggestedGoals(Transaction transaction) {
    // Return goals that might be relevant to this transaction
    return getActiveGoals().where((goal) {
      // Suggest goals for income transactions or expense reduction goals for expenses
      if (transaction.type == TransactionType.income) {
        return goal.goalType.toString().contains('savings') || 
               goal.goalType.toString().contains('investment');
      } else {
        return goal.goalType.toString().contains('expenseReduction') ||
               goal.goalType.toString().contains('debtReduction');
      }
    }).toList();
  }

  Future<Transaction> createSavingsTransaction({
    required double amount,
    required String goalId,
    String? description,
    String? categoryId,
  }) async {
    final goal = _offlineService.getGoal(goalId);
    final transaction = TransactionsCompanion(
      amount: Value(amount),
      type: Value(TransactionType.income),
      categoryId: Value(categoryId ?? 'savings'),
      date: Value(DateTime.now()),
      description: Value(description ?? 'Savings for ${goal?.name ?? "goal"}'),
      goalId: Value(goalId),
      profileId: const Value('default'),
    );
    
    await _offlineService.saveTransaction(transaction);
    await updateGoalProgress(goalId, amount);
    
    return transaction;
  }

  Map<String, dynamic> getGoalProgressSummary(String goalId) {
    final goal = _offlineService.getGoal(goalId);
    if (goal == null) {
      return {
        'progress': 0.0,
        'currentAmount': 0.0,
        'targetAmount': 0.0,
        'remainingAmount': 0.0,
      };
    }

    final progress = calculateGoalProgress(goal);
    final remainingAmount = goal.targetAmount - goal.currentAmount;

    return {
      'progress': progress,
      'currentAmount': goal.currentAmount,
      'targetAmount': goal.targetAmount,
      'remainingAmount': remainingAmount.clamp(0.0, double.infinity),
    };
  }
}
