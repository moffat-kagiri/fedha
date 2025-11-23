import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:fedha/data/app_database.dart';
import 'package:fedha/models/transaction.dart' as dom_tx;
import 'package:fedha/models/goal.dart' as dom_goal;
import 'package:fedha/models/loan.dart' as dom_loan;
import 'package:fedha/models/enums.dart';
import 'package:fedha/models/category.dart' as dom_cat;
import 'package:fedha/models/budget.dart' as dom_budget;

class OfflineDataService {
  late final SharedPreferences _prefs;
  final AppDatabase _db;

  OfflineDataService({AppDatabase? db}) : _db = db ?? AppDatabase();

  /// Initialize SharedPreferences instance
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get onboardingComplete =>
    _prefs.getBool('onboarding_complete') ?? false;
  set onboardingComplete(bool v) =>
    _prefs.setBool('onboarding_complete', v);

  bool get darkMode =>
    _prefs.getBool('dark_mode') ?? false;
  set darkMode(bool v) =>
    _prefs.setBool('dark_mode', v);

  // Transactions
  Future<void> saveTransaction(dom_tx.Transaction tx) async {
    final companion = TransactionsCompanion.insert(
      amountMinor: tx.amount,
      currency: 'KES',
      description: tx.description ?? '',
      categoryId: Value(tx.categoryId),
      date: tx.date,
      isExpense: Value(tx.isExpense),
      rawSms: Value(tx.smsSource),
      profileId: int.tryParse(tx.profileId) ?? 0,
    );
    await _db.insertTransaction(companion);
  }

  Future<List<dom_tx.Transaction>> getAllTransactions([int profileId = 0]) async {
    final rows = await _db.getAllTransactions();
    return rows
      .where((r) => r.profileId == profileId)
      .map((r) => dom_tx.Transaction(
        amount: r.amountMinor,
        type: r.isExpense ? TransactionType.expense : TransactionType.income,
        categoryId: r.categoryId ?? '',
        category: _getTransactionCategoryFromId(r.categoryId),
        description: r.description,
        date: r.date,
        smsSource: r.rawSms ?? '',
        profileId: r.profileId.toString(),
        isExpense: r.isExpense,
      ))
      .toList();
  }

  // Helper method to convert categoryId to TransactionCategory
  TransactionCategory? _getTransactionCategoryFromId(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return TransactionCategory.values.firstWhere(
        (category) => category.name == categoryId.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Goals
  Future<void> saveGoal(dom_goal.Goal goal) async {
    final companion = GoalsCompanion.insert(
      title: goal.name,
      targetMinor: goal.targetAmount,
      currency: 'KES',
      dueDate: goal.targetDate,
      completed: Value(goal.status == GoalStatus.completed),
      profileId: int.tryParse(goal.profileId) ?? 0,
    );
    await _db.insertGoal(companion);
  }
  
  Future<void> addGoal(dom_goal.Goal goal) async {
    await saveGoal(goal);
  }

  Future<List<dom_goal.Goal>> getAllGoals([int profileId = 0]) async {
    final rows = await _db.getAllGoals();
    return rows
      .where((r) => r.profileId == profileId)
      .map((r) => dom_goal.Goal(
        id: r.id.toString(),
        name: r.title,
        targetAmount: r.targetMinor,
        targetDate: r.dueDate,
        profileId: r.profileId.toString(),
        goalType: GoalType.other,
        status: r.completed ? GoalStatus.completed : GoalStatus.active,
      ))
      .toList();
  }

  // Loans
  Future<void> saveLoan(dom_loan.Loan loan) async {
    final companion = LoansCompanion.insert(
      name: loan.name,
      principalMinor: loan.principalMinor.toInt(),
      currency: Value(loan.currency),
      interestRate: Value(loan.interestRate),
      startDate: loan.startDate,
      endDate: loan.endDate,
      profileId: loan.profileId,
    );
    await _db.into(_db.loans).insert(companion);
  }

  Future<List<dom_loan.Loan>> getAllLoans(int profileId) async {
    final rows = await _db.select(_db.loans).get();
    return rows
      .where((r) => r.profileId == profileId)
      .map((r) => dom_loan.Loan(
        id: r.id,
        name: r.name,
        principalMinor: r.principalMinor.toDouble(),
        currency: r.currency,
        interestRate: r.interestRate,
        startDate: r.startDate,
        endDate: r.endDate,
        profileId: r.profileId,
      ))
      .toList();
  }

  // Budgets
  Future<void> saveBudget(dom_budget.Budget budget) async {
    if (kDebugMode) {
      print('Budget saving not implemented yet: ${budget.name}');
    }
  }
  
  Future<void> addBudget(dom_budget.Budget budget) async {
    await saveBudget(budget);
  }
  
  Future<List<dom_budget.Budget>> getAllBudgets([int? profileId]) async {
    return [];
  }
  
  Future<dom_budget.Budget?> getCurrentBudget(int profileId) async {
    return null;
  }

  // SMS-review helpers (pending transactions)
  Future<void> savePendingTransaction(dom_tx.Transaction tx) async {
    final companion = PendingTransactionsCompanion.insert(
      id: tx.id ?? const Uuid().v4(),
      amountMinor: tx.amount,
      currency: const Value('KES'),
      description: Value(tx.description),
      date: tx.date,
      isExpense: Value(tx.isExpense),
      rawSms: Value(tx.smsSource),
      profileId: int.tryParse(tx.profileId) ?? 0,
    );
    await _db.insertPending(companion);
  }

  Future<List<dom_tx.Transaction>> getPendingTransactions(int profileId) async {
    final rows = await _db.getAllPending(profileId);
    return rows.map((r) => dom_tx.Transaction(
      id: r.id,
      amount: r.amountMinor,
      type: r.isExpense ? TransactionType.expense : TransactionType.income,
      categoryId: '', // Fixed: Pending transactions don't have categoryId in database
      category: null, // Fixed: Pending transactions don't have category initially
      description: r.description ?? '',
      date: r.date,
      smsSource: r.rawSms ?? '',
      profileId: r.profileId.toString(),
      isPending: true,
      isExpense: r.isExpense,
    )).toList();
  }

  Future<void> approvePendingTransaction(dom_tx.Transaction tx) async {
    // Create a new transaction without the pending flag for the main transactions table
    final mainTransaction = dom_tx.Transaction(
      id: tx.id,
      amount: tx.amount,
      type: tx.type,
      categoryId: tx.categoryId,
      category: tx.category,
      date: tx.date,
      description: tx.description,
      smsSource: tx.smsSource,
      profileId: tx.profileId,
      isExpense: tx.isExpense,
    );
    
    await saveTransaction(mainTransaction);
    await _db.deletePending(tx.id ?? '');
  }

  Future<void> deletePendingTransaction(String id) async {
    await _db.deletePending(id);
  }

  Future<void> deleteTransaction(String id) async {
    int? numericId = int.tryParse(id);
    if (numericId != null) {
      await _db.deleteTransactionById(numericId);
    } else {
      throw Exception('Invalid transaction ID format: $id');
    }
  }

  Future<List<dom_cat.Category>> getCategories(int profileId) async {
    return [];
  }

  Future<dom_goal.Goal?> getGoal(String goalId) async {
    try {
      final rows = await _db.getAllGoals();
      final goal = rows.firstWhere(
        (r) => r.id.toString() == goalId,
      );
      return dom_goal.Goal(
        id: goal.id.toString(),
        name: goal.title,
        targetAmount: goal.targetMinor,
        targetDate: goal.dueDate,
        profileId: goal.profileId.toString(),
        goalType: GoalType.other,
        status: goal.completed ? GoalStatus.completed : GoalStatus.active,
      );
    } catch (e) {
      return null;
    }
  }

  Future<int> getPendingTransactionCount(int profileId) async {
    final pending = await getPendingTransactions(profileId);
    return pending.length;
  }

  Future<double> getAverageMonthlySpending(String profileId) async {
    final numericProfileId = int.tryParse(profileId) ?? 0;
    final transactions = await getAllTransactions(numericProfileId);
    
    if (transactions.isEmpty) return 0;

    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    final expenses = transactions
      .where((tx) => tx.type == TransactionType.expense && tx.date.isAfter(threeMonthsAgo))
      .map((tx) => tx.amount)
      .toList();

    if (expenses.isEmpty) return 0;

    final total = expenses.reduce((a, b) => a + b);
    return total / 3;
  }

  // Fixed: Implement updateGoal using Drift's update statement
  Future<void> updateGoal(dom_goal.Goal goal) async {
    final goalId = int.tryParse(goal.id);
    if (goalId == null) {
      throw Exception('Invalid goal ID format: ${goal.id}');
    }

    // Use Drift's update statement to update the goal
    await _db.update(_db.goals)
      .replace(GoalsCompanion(
        id: Value(goalId),
        title: Value(goal.name),
        targetMinor: Value(goal.targetAmount),
        currency: const Value('KES'),
        dueDate: Value(goal.targetDate),
        completed: Value(goal.status == GoalStatus.completed),
        profileId: Value(int.tryParse(goal.profileId) ?? 0),
      ));
  }
}