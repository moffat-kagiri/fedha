import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/profile.dart';
import '../models/enums.dart';

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

  List<Goal> getActiveGoals() {
    return getAllGoals().where((goal) => goal.status == 'active').toList();
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

  void dispose() {
    _transactionBox?.close();
    _categoryBox?.close();
    _goalBox?.close();
    _budgetBox?.close();
    _profileBox?.close();
    super.dispose();
  }
}
