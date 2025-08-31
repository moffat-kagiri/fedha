import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fedha/data/app_database.dart';
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
  Future<Map<String, List<Transaction>>> getTransactionsByCategory(List<Transaction> transactions) async {
    final Map<String, List<Transaction>> groupedTransactions = {};
    
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
  Future<void> saveTransaction(TransactionsCompanion transaction) async {
    await _db.insertTransaction(transaction);
  }

  // Budget Methods
  Future<void> addBudget(BudgetsCompanion budget) async {
    await _db.into(_db.budgets).insert(budget);
  }

  Future<void> updateBudget(int id, BudgetsCompanion budget) async {
    await (_db.update(_db.budgets)..where((t) => t.id.equals(id)))
      .write(budget);
  }

  Future<void> deleteBudget(int id) async {
    await (_db.delete(_db.budgets)..where((t) => t.id.equals(id)))
      .go();
  }

  Stream<List<Budget>> watchBudgets(int profileId) {
    return (_db.select(_db.budgets)
      ..where((t) => t.profileId.equals(profileId))
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.startDate,
          mode: OrderingMode.desc,
        )
      ])
    ).watch();
  }

  Future<List<Budget>> getBudgets(int profileId) async {
    return await (_db.select(_db.budgets)
      ..where((t) => t.profileId.equals(profileId))
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.startDate,
          mode: OrderingMode.desc,
        )
      ])
    ).get();
  }

  // Helper method to create transaction companion
  TransactionsCompanion createTransaction({
    required double amount,
    required String description,
    required DateTime date,
    required bool isExpense,
    String? categoryId,
    String? rawSms,
    required int profileId,
    String currency = 'KES',
  }) {
    return TransactionsCompanion.insert(
      amountMinor: amount,
      currency: currency,
      description: description,
      categoryId: Value(categoryId ?? ''),
      date: date,
      isExpense: Value(isExpense),
      rawSms: Value(rawSms),
      profileId: profileId,
    );
  }

  // Allow calling without profileId
  Future<List<Transaction>> getAllTransactions([int profileId = 0]) async {
    final rows = await _db.getAllTransactions();
    return rows.where((r) => r.profileId == profileId).toList();
  }

  // Goals
  Future<void> saveGoal(GoalsCompanion goal) async {
    await _db.insertGoal(goal);
  }

  // Helper method to create goal companion
  GoalsCompanion createGoal({
    required String title,
    required double targetAmount,
    required String currency,
    required DateTime dueDate,
    required int profileId,
    bool completed = false,
  }) {
    return GoalsCompanion.insert(
      title: title,
      targetMinor: targetAmount,
      currency: currency,
      dueDate: dueDate,
      completed: Value(completed),
      profileId: profileId,
    );
  }

  Future<List<Goal>> getAllGoals([int profileId = 0]) async {
    final rows = await _db.getAllGoals();
    return rows.where((r) => r.profileId == profileId).toList();
  }
  
  Future<Goal?> getGoal(int goalId) async {
    final rows = await _db.getAllGoals();
    return rows.firstWhere((r) => r.id == goalId);
  }

  // Loans
  Future<void> saveLoan(LoansCompanion loan) async {
    await _db.into(_db.loans).insert(loan);
  }

  // Helper method to create loan companion
  LoansCompanion createLoan({
    required String name,
    required int principalMinor,
    required DateTime startDate,
    required DateTime endDate,
    required int profileId,
    String currency = 'KES',
    double interestRate = 0.0,
  }) {
    return LoansCompanion.insert(
      name: name,
      principalMinor: principalMinor,
      currency: Value(currency),
      interestRate: Value(interestRate),
      startDate: startDate,
      endDate: endDate,
      profileId: profileId,
    );
  }

  Future<List<Loan>> getAllLoans(int profileId) async {
    final rows = await _db.select(_db.loans).get();
    return rows.where((r) => r.profileId == profileId).toList();
  }
  
  // Budgets
  Future<void> saveBudget(BudgetsCompanion budget) async {
    await _db.saveBudget(budget);
  }
  
  // Helper method to create budget companion
  BudgetsCompanion createBudget({
    required String name,
    required double limitAmount,
    required DateTime startDate,
    required DateTime? endDate,
    required int profileId,
    int? categoryId,
    String currency = 'KES',
    bool isRecurring = false,
  }) {
    return BudgetsCompanion.insert(
      name: name,
      limitMinor: limitAmount,
      currency: Value(currency),
      categoryId: Value(categoryId),
      startDate: startDate,
      endDate: endDate ?? startDate.add(const Duration(days: 30)),
      isRecurring: Value(isRecurring),
      profileId: profileId,
    );
  }
  
  Future<List<Budget>> getAllBudgets([int? profileId]) async {
    return _db.getAllBudgets(profileId ?? 0);
  }
  
  Future<Budget?> getCurrentBudget(int profileId) async {
    return _db.getCurrentBudget(profileId);
  }

  // SMS-review helpers (pending transactions)
  /// Returns a list of transactions pending review for a given profile.
  Future<List<PendingTransaction>> getPendingTransactions(int profileId) async {
    return _db.getAllPending(profileId);
  }

  /// Approves a pending transaction (adds it to main transactions).
  Future<void> approvePendingTransaction(PendingTransaction pending) async {
    // Convert pending to regular transaction
    final transaction = createTransaction(
      amount: pending.amountMinor,
      description: pending.description ?? '',
      date: pending.date,
      isExpense: pending.isExpense,
      rawSms: pending.rawSms,
      profileId: pending.profileId,
      currency: pending.currency,
    );
    
    // Insert into main transactions, then remove pending
    await saveTransaction(transaction);
    await _db.deletePending(pending.id);
  }

  /// Deletes a pending transaction by ID.
  Future<void> deletePendingTransaction(String id) async {
    await _db.deletePending(id);
  }

  /// Delete transaction from database by ID
  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransactionById(id);
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
  Future<List<Category>> getCategories(int profileId) async {
    return _db.getCategories(profileId);
  }
  
  /// Saves a new category
  Future<void> saveCategory(CategoriesCompanion category) async {
    await _db.insertCategory(category);
  }

  // Helper method to create category companion
  CategoriesCompanion createCategory({
    required String name,
    required int profileId,
    String iconKey = 'default_icon',
    String colorKey = 'default_color',
    bool isExpense = true,
    int sortOrder = 0,
  }) {
    return CategoriesCompanion.insert(
      name: name,
      iconKey: Value(iconKey),
      colorKey: Value(colorKey),
      isExpense: Value(isExpense),
      sortOrder: Value(sortOrder),
      profileId: profileId,
    );
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
