// lib/services/budget_service.dart
import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../utils/logger.dart';
import 'offline_data_service.dart';

/// Comprehensive budget management service
class BudgetService with ChangeNotifier {
  static BudgetService? _instance;
  static BudgetService get instance => _instance ??= BudgetService._();

  final _logger = AppLogger.getLogger('BudgetService');
  OfflineDataService? _offlineDataService;
  
  // Cache for active profile's budgets
  List<Budget> _cachedBudgets = [];
  String? _currentProfileId;
  bool _isInitialized = false;

  BudgetService._();

  /// Initialize with dependency injection
  Future<void> initialize(OfflineDataService offlineDataService) async {
    if (_isInitialized) {
      _logger.warning('BudgetService already initialized');
      return;
    }

    _offlineDataService = offlineDataService;
    _isInitialized = true;
    _logger.info('BudgetService initialized');
  }

  /// Load budgets for a specific profile
  Future<void> loadBudgetsForProfile(String profileId) async {
    if (_offlineDataService == null) {
      _logger.warning('OfflineDataService not available');
      return;
    }

    try {
      _currentProfileId = profileId;
      _cachedBudgets = await _offlineDataService!.getAllBudgets(profileId);
      notifyListeners();
      _logger.info('Loaded ${_cachedBudgets.length} budgets for profile: $profileId');
    } catch (e, stackTrace) {
      _logger.severe('Failed to load budgets', e, stackTrace);
      _cachedBudgets = [];
      notifyListeners();
    }
  }

  /// Get all budgets for current profile
  List<Budget> get budgets => List.unmodifiable(_cachedBudgets);

  /// Get active budgets only
  List<Budget> get activeBudgets => 
      _cachedBudgets.where((b) => b.isActive).toList();

  /// Get current budget (most recent active budget)
  Budget? get currentBudget {
    final active = activeBudgets;
    if (active.isEmpty) return null;
    
    // Sort by start date descending
    active.sort((a, b) => b.startDate.compareTo(a.startDate));
    return active.first;
  }

  /// Create a new budget
  Future<bool> createBudget(Budget budget) async {
    if (_offlineDataService == null) {
      _logger.warning('Cannot create budget: OfflineDataService not available');
      return false;
    }

    if (!_validateBudget(budget)) {
      _logger.warning('Cannot create budget: Validation failed');
      return false;
    }

    if (_currentProfileId == null || _currentProfileId!.isEmpty) {
      _logger.warning('Cannot create budget: No current profile loaded');
      return false;
    }

    try {
      // Create budget with current profileId
      final budgetWithProfile = budget.copyWith(
        profileId: _currentProfileId!, // ✅ Use _currentProfileId
        isSynced: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _offlineDataService!.saveBudget(budgetWithProfile);
      
      // Update cache
      _cachedBudgets.add(budgetWithProfile);
      notifyListeners();
      
      _logger.info('Budget created: ${budget.name} for profile: $_currentProfileId');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to create budget', e, stackTrace);
      return false;
    }
  }

  /// Update an existing budget
  Future<bool> updateBudget(Budget budget) async {
    if (_offlineDataService == null) {
      _logger.warning('Cannot update budget: OfflineDataService not available');
      return false;
    }

    if (!_validateBudget(budget)) {
      _logger.warning('Cannot update budget: Validation failed');
      return false;
    }

    if (_currentProfileId == null || _currentProfileId!.isEmpty) {
      _logger.warning('Cannot update budget: No current profile loaded');
      return false;
    }

    if (budget.id.isEmpty) {
      _logger.warning('Cannot update budget: Budget ID is empty');
      return false;
    }

    try {
      // Ensure budget has the correct profileId (from current profile)
      final updatedBudget = budget.copyWith(
        profileId: _currentProfileId!, // ✅ Use _currentProfileId
        isSynced: false,
        updatedAt: DateTime.now(),
      );
      
      // Update in database
      await _offlineDataService!.updateBudget(updatedBudget);
      
      // Update cache
      final index = _cachedBudgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _cachedBudgets[index] = updatedBudget;
        notifyListeners();
      }
      
      _logger.info('Budget updated: ${budget.name} for profile: $_currentProfileId');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to update budget', e, stackTrace);
      return false;
    }
  }

  /// Validate budget data
  bool _validateBudget(Budget budget) {
    if (budget.budgetAmount <= 0) {
      _logger.warning('Budget amount must be positive');
      return false;
    }
    
    if (budget.endDate.isBefore(budget.startDate)) {
      _logger.warning('End date must be after start date');
      return false;
    }
    
    if (budget.spentAmount < 0) {
      _logger.warning('Spent amount cannot be negative');
      return false;
    }
    
    return true;
  }

  /// Delete a budget
  Future<bool> deleteBudget(String budgetId) async {
    if (_offlineDataService == null) {
      _logger.warning('Cannot delete budget: OfflineDataService not available');
      return false;
    }

    if (_currentProfileId == null) {
      _logger.warning('Cannot delete budget: No current profile loaded');
      return false;
    }

    try {
      await _offlineDataService!.deleteBudget(budgetId);
      
      // Remove from cache
      _cachedBudgets.removeWhere((b) => b.id == budgetId);
      notifyListeners();
      
      _logger.info('Budget deleted: $budgetId for profile: $_currentProfileId');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete budget', e, stackTrace);
      return false;
    }
  }

  /// Record spending against a budget
  Future<bool> recordSpending({
    required String budgetId,
    required double amount,
    String? category,
  }) async {
    if (_offlineDataService == null) {
      _logger.warning('Cannot record spending: service not initialized');
      return false;
    }

    if (_currentProfileId == null) {
      _logger.warning('Cannot record spending: No current profile loaded');
      return false;
    }

    try {
      final budget = getBudgetById(budgetId);
      if (budget == null) {
        _logger.warning('Budget not found: $budgetId');
        return false;
      }
      
      final updatedBudget = budget.copyWith(
        spentAmount: budget.spentAmount + amount,
        isSynced: false,
        updatedAt: DateTime.now(),
      );

      return await updateBudget(updatedBudget);
    } catch (e, stackTrace) {
      _logger.severe('Failed to record spending', e, stackTrace);
      return false;
    }
  }

  /// Get budget by ID
  Budget? getBudgetById(String budgetId) {
    try {
      return _cachedBudgets.firstWhere((b) => b.id == budgetId);
    } catch (e) {
      return null;
    }
  }

  /// Get budgets by category
  List<Budget> getBudgetsByCategory(String category) {
    return _cachedBudgets.where((b) => b.category == category).toList();
  }

  /// Check if over budget
  bool isOverBudget(String budgetId) {
    final budget = getBudgetById(budgetId);
    return budget?.isOverBudget ?? false;
  }

  /// Get total budget amount across all active budgets
  double get totalBudgetAmount {
    return activeBudgets.fold(0.0, (sum, b) => sum + b.budgetAmount);
  }

  /// Get total spent across all active budgets
  double get totalSpent {
    return activeBudgets.fold(0.0, (sum, b) => sum + b.spentAmount);
  }

  /// Get overall budget health (0-1, where 1 is healthy)
  double get budgetHealth {
    if (totalBudgetAmount == 0) return 1.0;
    final spentRatio = totalSpent / totalBudgetAmount;
    return (1.0 - spentRatio).clamp(0.0, 1.0);
  }

  /// Clear cache (call on logout)
  void clearCache() {
    _cachedBudgets = [];
    _currentProfileId = null;
    notifyListeners();
    _logger.info('Budget cache cleared');
  }
}