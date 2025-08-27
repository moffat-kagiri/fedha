// Removed Category conflict, no foundation features used
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:fedha/data/app_database.dart';
import 'package:fedha/models/transaction.dart' as dom_tx;
import 'package:fedha/models/goal.dart' as dom_goal;
import 'package:fedha/models/loan.dart' as dom_loan;
import 'package:fedha/models/enums.dart' show TransactionType;
import 'package:fedha/models/category.dart' as dom_cat;
import 'package:fedha/models/budget.dart' as dom_budget;

class OfflineDataService {
  // SharedPreferences for simple flags/caches
  late final SharedPreferences _prefs;

  OfflineDataService();

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

  // Drift DB for relational data
  final AppDatabase _db = AppDatabase();

  // Transactions
  Future<void> saveTransaction(dom_tx.Transaction tx) async {
    final companion = TransactionsCompanion.insert(
      amountMinor: tx.amount,
      currency: tx.paymentMethod == null ? 'KES' : tx.paymentMethod.toString(),
      description: tx.description ?? '',
      date: tx.date,
      isExpense: Value(tx.isExpense),
      rawSms: Value(tx.smsSource),
      profileId: int.tryParse(tx.profileId) ?? 0,
    );
    await _db.insertTransaction(companion);
  }

  // Allow calling without profileId
  Future<List<dom_tx.Transaction>> getAllTransactions([int profileId = 0]) async {
    final rows = await _db.getAllTransactions();
    return rows
      .where((r) => r.profileId == profileId)
      .map((r) => dom_tx.Transaction(
        amount: r.amountMinor,
        type: r.isExpense ? TransactionType.expense : TransactionType.income,
        categoryId: '',
        description: r.description,
        date: r.date,
        smsSource: r.rawSms ?? '',
        profileId: r.profileId.toString(),
      ))
      .toList();
  }

  // Goals
  Future<void> saveGoal(dom_goal.Goal goal) async {
    final companion = GoalsCompanion.insert(
      title: goal.name,
      targetMinor: goal.targetAmount,
      currency: goal.currency,
      dueDate: goal.targetDate,
      completed: Value(goal.status == 'completed'),
      profileId: int.tryParse(goal.profileId ?? '') ?? 0,
    );
    await _db.insertGoal(companion);
  }
  
  // Add missing method
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
        currency: r.currency,
        profileId: r.profileId.toString(),
        status: r.completed ? 'completed' : 'active',
        isActive: !r.completed,
      ))
      .toList();
  }
  
  Future<dom_goal.Goal?> getGoal(String goalId) async {
    final rows = await _db.getAllGoals();
    final matches = rows.where((r) => r.id.toString() == goalId).toList();
    if (matches.isEmpty) return null;
    
    final r = matches.first;
    return dom_goal.Goal(
      id: r.id.toString(),
      name: r.title,
      targetAmount: r.targetMinor,
      targetDate: r.dueDate,
      currency: r.currency,
      profileId: r.profileId.toString(),
      status: r.completed ? 'completed' : 'active',
      isActive: !r.completed,
    );
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
    // TODO: Implement budget saving when Budgets table is added to the database
    print('Budget saving not implemented yet: ${budget.name}');
  }
  
  Future<void> addBudget(dom_budget.Budget budget) async {
    await saveBudget(budget);
  }
  
  Future<List<dom_budget.Budget>> getAllBudgets([int? profileId]) async {
    // TODO: Implement when Budgets table is added
    return [];
  }
  
  Future<dom_budget.Budget?> getCurrentBudget(int profileId) async {
    // TODO: Implement when Budgets table is added
    return null;
  }

  // SMS-review helpers (pending transactions)
  /// Returns a list of transactions pending review for a given profile.
  Future<List<dom_tx.Transaction>> getPendingTransactions(int profileId) async {
    final rows = await _db.getAllPending(profileId);
  return rows.map((r) => dom_tx.Transaction(
      id: r.id,
      amount: r.amountMinor,
      type: r.isExpense ? TransactionType.expense : TransactionType.income,
      categoryId: '',
      description: r.description ?? '',
      date: r.date,
      smsSource: r.rawSms ?? '',
      profileId: r.profileId.toString(),
      isPending: true,
      isExpense: r.isExpense,
    )).toList();
  }

  /// Approves a pending transaction (adds it to main transactions).
  Future<void> approvePendingTransaction(dom_tx.Transaction tx) async {
    // Insert into main transactions, then remove pending
    await saveTransaction(tx);
    await _db.deletePending(tx.id);
  }

  /// Deletes a pending transaction by ID.
  Future<void> deletePendingTransaction(String id) async {
    await _db.deletePending(id);
  }

  /// Delete transaction from database by ID
  Future<void> deleteTransaction(String id) async {
    // Convert String ID to int if needed
    int? numericId = int.tryParse(id);
    if (numericId != null) {
      await _db.deleteTransactionById(numericId);
    } else {
      // Handle legacy string IDs or provide fallback
      // This might be needed during migration
      throw Exception('Invalid transaction ID format');
    }
  }

  /// Returns all categories for a profile.
  Future<List<dom_cat.Category>> getCategories(int profileId) async {
    // TODO: fetch categories from DB
    return [];
  }
  
  /// Save a pending transaction to be reviewed
  Future<void> savePendingTransaction(dom_tx.Transaction tx) async {
    final companion = PendingTransactionsCompanion.insert(
      id: tx.id,
      amountMinor: tx.amount,
      currency: Value(tx.paymentMethod?.toString() ?? 'KES'),
      description: Value(tx.description ?? ''),
      date: tx.date,
      isExpense: Value(tx.isExpense),
      rawSms: Value(tx.smsSource ?? ''),
      profileId: int.tryParse(tx.profileId) ?? 0,
    );
    await _db.insertPending(companion);
  }
}

extension EmergencyFundX on OfflineDataService {
  /// Returns the average monthly expense over the last [months] months,
  /// or null if there isn’t at least one transaction in that window.
  Future<double?> getAverageMonthlySpending(int profileId, {int months = 3}) async {
    final since = DateTime.now().subtract(Duration(days: months * 30));
    final all = await getAllTransactions(profileId);
    final recentExpenses = all
        .where((tx) =>
            tx.type == TransactionType.expense && tx.date.isAfter(since))
        .toList();
    if (recentExpenses.isEmpty) return null;
    final total = recentExpenses.fold<double>(
        0, (sum, tx) => sum + tx.amount);
    return total / months;
  }
}
