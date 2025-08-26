import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fedha/data/app_database.dart';
import 'package:fedha/models/transaction.dart' as dom;
import 'package:fedha/models/goal.dart' as dom;
import 'package:fedha/models/loan.dart' as dom;
import 'package:drift/drift.dart' show Value;

class OfflineDataService {
  // SharedPreferences for simple flags/caches
  late final SharedPreferences _prefs;

  OfflineDataService() {
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
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
  Future<void> saveTransaction(dom.Transaction tx) async {
    final companion = TransactionsCompanion.insert(
      amountMinor: Value(tx.amountMinor),
      currency: tx.currency,
      description: tx.description,
      date: tx.date,
      isExpense: Value(tx.isExpense),
      rawSms: Value(tx.smsSource),
      profileId: Value(tx.profileId),
    );
    await _db.insertTransaction(companion);
  }

  Future<List<dom.Transaction>> getAllTransactions(int profileId) async {
    final rows = await _db.getAllTransactions();
    return rows
      .where((r) => r.profileId == profileId)
      .map((r) => dom.Transaction(
        id: r.id,
        amountMinor: r.amountMinor,
        currency: r.currency,
        description: r.description,
        date: r.date,
        isExpense: r.isExpense,
        smsSource: r.rawSms ?? '',
        profileId: r.profileId,
      ))
      .toList();
  }

  // Goals
  Future<void> saveGoal(dom.Goal goal) async {
    final companion = GoalsCompanion.insert(
      title: goal.title,
      targetMinor: Value(goal.targetMinor),
      currency: goal.currency,
      dueDate: goal.dueDate,
      completed: Value(goal.completed),
      profileId: Value(goal.profileId),
    );
    await _db.into(_db.goals).insert(companion);
  }

  Future<List<dom.Goal>> getAllGoals(int profileId) async {
    final rows = await _db.select(_db.goals).get();
    return rows
      .where((r) => r.profileId == profileId)
      .map((r) => dom.Goal(
        id: r.id,
        title: r.title,
        targetMinor: r.targetMinor,
        currency: r.currency,
        dueDate: r.dueDate,
        completed: r.completed,
        profileId: r.profileId,
      ))
      .toList();
  }

  // Loans
  Future<void> saveLoan(dom.Loan loan) async {
    final companion = LoansCompanion.insert(
      name: loan.name,
      principalMinor: Value(loan.principalMinor),
      currency: loan.currency,
      interestRate: loan.interestRate,
      startDate: loan.startDate,
      endDate: loan.endDate,
      profileId: loan.profileId,
    );
    await _db.into(_db.loans).insert(companion);
  }

  Future<List<dom.Loan>> getAllLoans(int profileId) async {
    final rows = await _db.select(_db.loans).get();
    return rows
      .where((r) => r.profileId == profileId)
      .map((r) => dom.Loan(
        id: r.id,
        name: r.name,
        principalMinor: r.principalMinor,
        currency: r.currency,
        interestRate: r.interestRate,
        startDate: r.startDate,
        endDate: r.endDate,
        profileId: r.profileId,
      ))
      .toList();
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
