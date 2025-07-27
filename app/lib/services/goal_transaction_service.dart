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

    final updatedGoal = Goal(
      id: goal.id,
      name: goal.name,
      description: goal.description,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount + amount,
      targetDate: goal.targetDate,
      priority: goal.priority,
      status: goal.status,
      isActive: goal.isActive,
      goalType: goal.goalType,
      currency: goal.currency,
      profileId: goal.profileId,
      createdAt: goal.createdAt,
      updatedAt: DateTime.now(),
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

    final updatedGoal = Goal(
      id: goal.id,
      name: goal.name,
      description: goal.description,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      targetDate: goal.targetDate,
      priority: goal.priority,
      status: 'completed',
      isActive: goal.isActive,
      goalType: goal.goalType,
      currency: goal.currency,
      profileId: goal.profileId,
      createdAt: goal.createdAt,
      updatedAt: DateTime.now(),
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
    final transaction = Transaction(
      amount: amount,
      type: TransactionType.income,
      categoryId: categoryId ?? 'savings',
      date: DateTime.now(),
      description: description ?? 'Savings for ${goal?.name ?? "goal"}',
      goalId: goalId,
      profileId: 'default',
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
