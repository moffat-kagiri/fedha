// Removed Category conflict, no foundation features used
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fedha/data/app_database.dart';
import 'package:fedha/models/transaction.dart' as dom_tx;
import 'package:fedha/models/goal.dart' as dom_goal;
import 'package:fedha/models/loan.dart' as dom_loan;
import 'package:fedha/models/enums.dart' show TransactionType;
import 'package:fedha/models/category.dart' as dom_cat;
import 'package:fedha/models/budget.dart' as dom_budget;
import 'package:fedha/services/settings_service.dart';

class OfflineDataService {
  final SettingsService _settingsService;
  final CategorySeeder _categorySeeder;

  OfflineDataService(this._settingsService) : _categorySeeder = CategorySeeder(_db);

  /// Initialize services
  Future<void> initialize() async {
    await _settingsService.initialize();
  }

  /// Setup a new profile with default data
  Future<void> setupProfile(int profileId) async {
    await _categorySeeder.seedDefaultCategories(profileId);
  }

  bool get onboardingComplete => _settingsService.onboardingComplete;
  set onboardingComplete(bool v) => _settingsService.setOnboardingComplete(v);

  bool get darkMode => _settingsService.theme == 'dark';
  set darkMode(bool v) => _settingsService.setTheme(v ? 'dark' : 'system');

  // Drift DB for relational data
  final AppDatabase _db = AppDatabase();

  // Category Analytics
  Future<Map<String, List<dom_tx.Transaction>>> getTransactionsByCategory(List<dom_tx.Transaction> transactions) async {
    final Map<String, List<dom_tx.Transaction>> groupedTransactions = {};
    
    for (final transaction in transactions) {
      if (transaction.categoryId.isEmpty) continue;
      
      if (!groupedTransactions.containsKey(transaction.categoryId)) {
        groupedTransactions[transaction.categoryId] = [];
      }
      groupedTransactions[transaction.categoryId]!.add(transaction);
    }
    
    return groupedTransactions;
  }

  // Transactions
  Future<void> saveTransaction(dom_tx.Transaction tx) async {
    final companion = TransactionsCompanion.insert(
      amountMinor: tx.amount,
      currency: tx.paymentMethod == null ? 'KES' : tx.paymentMethod.toString(),
      description: tx.description ?? '',
      categoryId: Value(tx.categoryId),
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
        categoryId: r.categoryId,
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
    final companion = BudgetsCompanion.insert(
      name: budget.name,
      limitMinor: budget.limitAmount,
      currency: Value(budget.currency ?? 'KES'),
      categoryId: Value(int.tryParse(budget.categoryId ?? '')),
      startDate: budget.startDate,
      endDate: budget.endDate ?? budget.startDate.add(const Duration(days: 30)),
      isRecurring: Value(budget.isRecurring ?? false),
      profileId: int.tryParse(budget.profileId) ?? 0,
    );
    await _db.saveBudget(companion);
  }
  
  Future<void> addBudget(dom_budget.Budget budget) async {
    await saveBudget(budget);
  }
  
  Future<List<dom_budget.Budget>> getAllBudgets([int? profileId]) async {
    final rows = await _db.getAllBudgets(profileId ?? 0);
    return rows.map((r) => dom_budget.Budget(
      id: r.id.toString(),
      name: r.name,
      limitAmount: r.limitMinor,
      currency: r.currency,
      categoryId: r.categoryId?.toString(),
      startDate: r.startDate,
      endDate: r.endDate,
      isRecurring: r.isRecurring,
      profileId: r.profileId.toString(),
    )).toList();
  }
  
  Future<dom_budget.Budget?> getCurrentBudget(int profileId) async {
    final current = await _db.getCurrentBudget(profileId);
    if (current == null) return null;
    
    return dom_budget.Budget(
      id: current.id.toString(),
      name: current.name,
      limitAmount: current.limitMinor,
      currency: current.currency,
      categoryId: current.categoryId?.toString(),
      startDate: current.startDate,
      endDate: current.endDate,
      isRecurring: current.isRecurring,
      profileId: current.profileId.toString(),
    );
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

  /// Get transactions for a specific period and optionally filtered by category
  Future<List<dom_tx.Transaction>> getTransactionsForPeriod({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
  }) async {
    final rows = await _db.getAllTransactions();
    return rows
      .where((r) => 
        r.profileId == profileId &&
        r.date.isAfter(startDate) &&
        r.date.isBefore(endDate) &&
        (categoryId == null || r.categoryId == categoryId)
      )
      .map((r) => dom_tx.Transaction(
        id: r.id.toString(),
        amount: r.amountMinor,
        type: r.isExpense ? TransactionType.expense : TransactionType.income,
        categoryId: r.categoryId,
        description: r.description,
        date: r.date,
        smsSource: r.rawSms,
        profileId: r.profileId.toString(),
      ))
      .toList();
  }

  /// Returns all categories for a profile.
  Future<List<dom_cat.Category>> getCategories(int profileId) async {
    final rows = await _db.getCategories(profileId);
    return rows.map((r) => dom_cat.Category(
      id: r.id.toString(),
      name: r.name,
      iconKey: r.iconKey,
      colorKey: r.colorKey,
      isExpense: r.isExpense,
      sortOrder: r.sortOrder,
      profileId: r.profileId.toString(),
    )).toList();
  }
  
  /// Saves a new category
  Future<void> saveCategory(dom_cat.Category category) async {
    final companion = CategoriesCompanion.insert(
      name: category.name,
      iconKey: Value(category.iconKey),
      colorKey: Value(category.colorKey),
      isExpense: Value(category.isExpense),
      sortOrder: Value(category.sortOrder ?? 0),
      profileId: int.tryParse(category.profileId) ?? 0,
    );
    await _db.insertCategory(companion);
  }
  
  /// Update an existing budget's period
  Future<void> updateBudgetPeriod(String budgetId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final budget = BudgetsCompanion(
      startDate: Value(startDate),
      endDate: Value(endDate),
    );
    await _db.updateBudget(int.parse(budgetId), budget);
  }

  /// Update an existing budget's category
  Future<void> updateBudgetCategory(String budgetId, String categoryId) async {
    final budget = BudgetsCompanion(
      categoryId: Value(int.parse(categoryId)),
    );
    await _db.updateBudget(int.parse(budgetId), budget);
  }

  /// Delete a budget by ID
  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(int.parse(id));
  }

  /// Get a single category by ID
  Future<dom_cat.Category?> getCategoryById(String id) async {
    final category = await _db.getCategoryById(int.parse(id));
    if (category == null) return null;
    
    return dom_cat.Category(
      id: category.id.toString(),
      name: category.name,
      iconKey: category.iconKey,
      colorKey: category.colorKey,
      isExpense: category.isExpense,
      sortOrder: category.sortOrder,
      profileId: category.profileId.toString(),
    );
  }

  /// Update an existing category
  Future<void> updateCategory(dom_cat.Category category) async {
    final companion = CategoriesCompanion(
      name: Value(category.name),
      iconKey: Value(category.iconKey),
      colorKey: Value(category.colorKey),
      isExpense: Value(category.isExpense),
      sortOrder: Value(category.sortOrder),
    );
    await _db.updateCategory(int.parse(category.id), companion);
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
