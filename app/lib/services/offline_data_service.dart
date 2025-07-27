import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/profile.dart';
import '../models/enums.dart';
import '../models/client.dart';
import '../models/invoice.dart';

class OfflineDataService extends ChangeNotifier {
  static OfflineDataService? _instance;
  static OfflineDataService get instance => _instance ??= OfflineDataService._();
  
  OfflineDataService._();
  
  // Constructor for dependency injection
  OfflineDataService() : this._();

  Box<Transaction>? _transactionBox;
  Box<models.Category>? _categoryBox;
  Box<Goal>? _goalBox;
  Box<Budget>? _budgetBox;
  Box<Profile>? _profileBox;
  Box<Client>? _clientBox;
  Box<Invoice>? _invoiceBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _transactionBox = await Hive.openBox<Transaction>('transactions');
      _categoryBox = await Hive.openBox<models.Category>('categories');
      _goalBox = await Hive.openBox<Goal>('goals');
      _budgetBox = await Hive.openBox<Budget>('budgets');
      _profileBox = await Hive.openBox<Profile>('profiles');
      _clientBox = await Hive.openBox<Client>('clients');
      _invoiceBox = await Hive.openBox<Invoice>('invoices');
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing OfflineDataService: $e');
    }
  }

  // Transaction methods
  Future<void> saveTransaction(Transaction transaction) async {
    await _transactionBox?.put(transaction.id, transaction);
    notifyListeners();
  }
  
  List<Transaction> getAllTransactions() {
    return _transactionBox?.values.toList() ?? [];
  }

  Transaction? getTransaction(String id) {
    return _transactionBox?.get(id);
  }
  
  Future<List<Transaction>> fetchUnsyncedTransactions(String profileId) async {
    final allTransactions = getAllTransactions();
    return allTransactions
        .where((t) => t.profileId == profileId && !t.isSynced)
        .toList();
  }
  
  // Alias for fetchUnsyncedTransactions to maintain compatibility with existing code
  Future<List<Transaction>> getUnsyncedTransactions(String profileId) async {
    return fetchUnsyncedTransactions(profileId);
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionBox?.delete(id);
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionBox?.put(transaction.id, transaction);
    notifyListeners();
  }

  // Category methods
  Future<void> saveCategory(models.Category category) async {
    await _categoryBox?.put(category.id, category);
    notifyListeners();
  }

  List<models.Category> getAllCategories() {
    return _categoryBox?.values.toList() ?? [];
  }
  
  // Overloaded method with profileId parameter
  List<models.Category> getCategoriesForProfile(String profileId) {
    return _categoryBox?.values.where((cat) => true).toList() ?? [];
  }

  models.Category? getCategory(String id) {
    return _categoryBox?.get(id);
  }

  // Goal methods
  Future<void> saveGoal(Goal goal) async {
    await _goalBox?.put(goal.id, goal);
    notifyListeners();
  }

  Future<void> addGoal(Goal goal) async {
    await saveGoal(goal);
  }

  List<Goal> getAllGoals() {
    return _goalBox?.values.toList() ?? [];
  }
  
  // Overloaded method with profileId parameter
  List<Goal> getGoalsForProfile(String profileId) {
    return _goalBox?.values.where((goal) => goal.profileId == profileId).toList() ?? [];
  }

  List<Goal> getActiveGoals([String? profileId]) {
    final goals = getAllGoals().where((goal) => goal.status == 'active');
    if (profileId != null) {
      return goals.where((goal) => goal.profileId == profileId).toList();
    }
    return goals.toList();
  }

  Goal? getGoal(String id) {
    return _goalBox?.get(id);
  }

  Future<void> deleteGoal(String id) async {
    await _goalBox?.delete(id);
    notifyListeners();
  }

  // Budget methods
  Future<void> saveBudget(Budget budget) async {
    await _budgetBox?.put(budget.id, budget);
    notifyListeners();
  }

  Future<void> addBudget(Budget budget) async {
    await saveBudget(budget);
  }

  List<Budget> getAllBudgets() {
    return _budgetBox?.values.toList() ?? [];
  }
  
  // Overloaded method with profileId parameter
  List<Budget> getBudgetsForProfile(String profileId) {
    return _budgetBox?.values.toList() ?? [];
  }

  Budget? getBudget(String id) {
    return _budgetBox?.get(id);
  }

  Budget? getCurrentBudget() {
    final budgets = getAllBudgets();
    if (budgets.isEmpty) return null;
    
    final now = DateTime.now();
    return budgets.where((b) => 
      b.isActive && 
      b.startDate.isBefore(now) && 
      b.endDate.isAfter(now)
    ).firstOrNull;
  }

  // Profile methods
  Future<void> saveProfile(Profile profile) async {
    await _profileBox?.put(profile.id, profile);
    notifyListeners();
  }

  List<Profile> getAllProfiles() {
    return _profileBox?.values.toList() ?? [];
  }

  Profile? getProfile(String id) {
    return _profileBox?.get(id);
  }

  // Statistics methods
  double getTotalExpenses() {
    final transactions = getAllTransactions();
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalIncome() {
    final transactions = getAllTransactions();
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getExpensesByCategory() {
    final transactions = getAllTransactions();
    final expenses = transactions.where((t) => t.type == TransactionType.expense);
    
    final Map<String, double> categoryTotals = {};
    for (final transaction in expenses) {
      categoryTotals[transaction.categoryId] = 
          (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount;
    }
    return categoryTotals;
  }

  // Client methods
  Future<void> saveClient(Client client) async {
    await _clientBox?.put(client.id, client);
    notifyListeners();
  }

  List<Client> getAllClients() {
    return _clientBox?.values.toList() ?? [];
  }
  
  // Overloaded method with profileId parameter
  List<Client> getClientsForProfile(String profileId) {
    return _clientBox?.values.toList() ?? [];
  }

  Client? getClient(String id) {
    return _clientBox?.get(id);
  }
  
  // Invoice methods
  Future<void> saveInvoice(Invoice invoice) async {
    await _invoiceBox?.put(invoice.id, invoice);
    notifyListeners();
  }

  List<Invoice> getAllInvoices() {
    return _invoiceBox?.values.toList() ?? [];
  }
  
  // Overloaded method with profileId parameter
  List<Invoice> getInvoicesForProfile(String profileId) {
    return _invoiceBox?.values.toList() ?? [];
  }

  Invoice? getInvoice(String id) {
    return _invoiceBox?.get(id);
  }

  @override
  void dispose() {
    _transactionBox?.close();
    _categoryBox?.close();
    _goalBox?.close();
    _budgetBox?.close();
    _profileBox?.close();
    _clientBox?.close();
    _invoiceBox?.close();
    super.dispose();
  }
}
