// lib/services/unified_sync_service.dart - IMPROVED VERSION
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/enums.dart';
import '../utils/logger.dart';
import 'offline_data_service.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Unified sync service with batch operations and improved efficiency
class UnifiedSyncService with ChangeNotifier {
  static UnifiedSyncService? _instance;
  static UnifiedSyncService get instance => _instance ??= UnifiedSyncService._();

  final _logger = AppLogger.getLogger('UnifiedSyncService');
  final _uuid = Uuid();
  
  late OfflineDataService _offlineDataService;
  late ApiClient _apiClient;
  late AuthService _authService;
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _currentProfileId;
  bool _isInitialized = false;

  // Batch size for sync operations
  static const int _batchSize = 50;

  UnifiedSyncService._();

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get currentProfileId => _currentProfileId;

  Future<void> initialize({
    required OfflineDataService offlineDataService,
    required ApiClient apiClient,
    required AuthService authService,
  }) async {
    _offlineDataService = offlineDataService;
    _apiClient = apiClient;
    _authService = authService;
    _isInitialized = true;
    _setupAuthListener();
    _logger.info('UnifiedSyncService initialized');
  }

  void _setupAuthListener() {
    _authService.addListener(() {
      final currentProfile = _authService.currentProfile;
      if (currentProfile != null) {
        setCurrentProfile(currentProfile.id);
        Future.delayed(const Duration(seconds: 1), () {
          if (_currentProfileId == currentProfile.id) {
            syncAll().catchError((e) => _logger.warning('Auto-sync failed: $e'));
          }
        });
      } else {
        clearCache();
      }
    });
  }

  void setCurrentProfile(String profileId) {
    if (_currentProfileId != profileId) {
      _currentProfileId = profileId;
      _logger.info('Current profile set for sync: $profileId');
      notifyListeners();
    }
  }

  Future<SyncResult> syncAll() async {
    if (!_isInitialized || _currentProfileId == null) {
      return SyncResult(
        success: false,
        error: _isInitialized ? 'No active profile' : 'Sync service not initialized',
        timestamp: DateTime.now(),
      );
    }
    return await syncProfile(_currentProfileId!);
  }

  Future<SyncResult> syncProfile(String profileId) async {
    if (!_isInitialized || _isSyncing) {
      return SyncResult(
        success: false,
        error: _isSyncing ? 'Sync already in progress' : 'Services not initialized',
        timestamp: DateTime.now(),
      );
    }

    _isSyncing = true;
    notifyListeners();

    final result = SyncResult(timestamp: DateTime.now());

    try {
      _logger.info('Starting full sync for profile: $profileId');

      final isOnline = await _apiClient.checkServerHealth();
      result.serverAvailable = isOnline;

      if (isOnline) {
        // Sync in parallel for better performance
        final results = await Future.wait([
          _syncTransactionsBatch(profileId),
          _syncGoalsBatch(profileId),
          _syncBudgetsBatch(profileId),
          _syncLoansBatch(profileId),
          _syncPendingTransactions(profileId),
        ]);

        result.transactions = results[0] as EntitySyncResult;
        result.goals = results[1] as EntitySyncResult;
        result.budgets = results[2] as EntitySyncResult;
        result.loans = results[3] as EntitySyncResult;
        result.pendingTransactions = results[4] as EntitySyncResult;

        result.success = true;
        _lastSyncTime = DateTime.now();
        
        _logger.info('Sync completed. Downloaded: ${result.totalDownloaded}, '
            'Uploaded: ${result.totalUploaded}');
      } else {
        // Offline mode - just count local data
        await _updateLocalCounts(result, profileId);
        result.success = true;
        _lastSyncTime = DateTime.now();
      }
    } catch (e, stackTrace) {
      _logger.severe('Sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return result;
  }

  /// ✅ UPDATED: Use the new prepareTransactionData from ApiClient
  Future<EntitySyncResult> _syncTransactionsBatch(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localTransactions = await _offlineDataService.getAllTransactions(profileId);
      result.localCount = localTransactions.length;

      if (_apiClient.isAuthenticated) {
        // STEP 1: Upload unsynced transactions in batches
        final unsyncedTransactions = localTransactions
            .where((t) => t.remoteId == null)
            .toList();
        
        if (unsyncedTransactions.isNotEmpty) {
          _logger.info('Uploading ${unsyncedTransactions.length} transactions');
          
          // Use the new prepareTransactionData method
          for (int i = 0; i < unsyncedTransactions.length; i += _batchSize) {
            final batch = unsyncedTransactions.skip(i).take(_batchSize).toList();
            final batchData = batch.map((t) {
              return ApiClient.prepareTransactionData(
                profileId: profileId,
                amount: t.amount,  // Use major units
                type: t.type,
                description: t.description ?? '',
                category: t.category,
                goalId: t.goalId,
                date: t.date,
                isExpense: t.isExpense ?? (t.type == 'expense'),
                currency: t.currency ?? 'KES',
                status: t.status ?? 'completed',
                paymentMethod: t.paymentMethod,
                merchantName: t.merchantName,
                merchantCategory: t.merchantCategory,
                tags: t.tags,
                isRecurring: t.isRecurring,
              );
            }).toList();
            
            final response = await _apiClient.syncTransactions(profileId, batchData);
            
            if (response['success'] == true) {
              result.uploaded += response['created'] as int? ?? 0;
              result.uploaded += response['updated'] as int? ?? 0;
            }
          }
        }

        // STEP 2: Download from server
        final remoteTransactions = await _apiClient.getTransactions(profileId: profileId);
        _logger.info('Downloaded ${remoteTransactions.length} transactions');

        // STEP 3: Merge only new transactions
        for (final remote in remoteTransactions) {
          final remoteId = remote['id']?.toString();
          if (remoteId == null) continue;
          
          final existsLocally = localTransactions.any((t) => t.remoteId == remoteId);
          
          if (!existsLocally) {
            final transaction = _parseRemoteTransaction(remote, profileId);
            if (transaction != null) {
              await _offlineDataService.saveTransaction(transaction);
              result.downloaded++;
            }
          }
        }
      }
      
      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Transaction sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// ✅ FIXED: Parse remote transaction with correct field mapping
  Transaction? _parseRemoteTransaction(Map<String, dynamic> remote, String profileId) {
    try {
      final remoteId = remote['id']?.toString();
      // CHANGED: Use 'amount' not 'amount_minor'
      final amount = _parseAmount(remote['amount'] ?? remote['amount_minor']);  
      final isExpense = remote['is_expense'] == true;
      
      // Field name is 'type' in backend
      String type = remote['type']?.toString() ?? (isExpense ? 'expense' : 'income');
      
      // Ensure valid transaction type
      if (!['income', 'expense', 'savings', 'transfer'].contains(type)) {
        type = isExpense ? 'expense' : 'income';
      }
      
      return Transaction(
        id: _uuid.v4(),
        remoteId: remoteId,
        profileId: profileId,
        amount: amount,
        type: type,
        isExpense: isExpense,
        category: remote['category']?.toString() ?? '',
        description: remote['description']?.toString() ?? '',
        date: _parseDate(remote['date']) ?? DateTime.now(),
        goalId: remote['goal_id']?.toString(),
        budgetCategory: remote['budget_category']?.toString(),
        currency: remote['currency']?.toString() ?? 'KES',
        status: remote['status']?.toString() ?? 'completed',
        isSynced: true,
        createdAt: _parseDate(remote['created_at']) ?? DateTime.now(),
        updatedAt: _parseDate(remote['updated_at']) ?? DateTime.now(),
        paymentMethod: remote['payment_method']?.toString(),
        merchantName: remote['merchant_name']?.toString(),
        merchantCategory: remote['merchant_category']?.toString(),
        tags: remote['tags']?.toString(),
        reference: remote['reference']?.toString(),
        recipient: remote['recipient']?.toString(),
        // Add other optional fields
        isRecurring: remote['is_recurring'] ?? false,
        location: remote['location']?.toString(),
      );
    } catch (e) {
      _logger.warning('Failed to parse remote transaction: $e');
      return null;
    }
  }

  /// ✅ FIXED: Prepare transaction for upload with correct field names
  Map<String, dynamic> _prepareTransactionForUpload(Transaction t, String profileId) {
    return {
      'profile_id': profileId,
      'amount': t.amount,  // CHANGED: Major units, not minor
      'type': t.type,      // CHANGED: Field name fixed (should match backend)
      'description': t.description ?? '',
      'category': t.category,
      'goal_id': t.goalId,
      'date': t.date.toIso8601String(),
      'is_expense': t.isExpense ?? (t.type == 'expense'),
      'currency': t.currency ?? 'KES',
      'is_synced': true,
      'status': t.status ?? 'completed',
      'budget_category': t.budgetCategory,
      'payment_method': t.paymentMethod,
      'merchant_name': t.merchantName,
      'merchant_category': t.merchantCategory,
      'tags': t.tags,
      'reference': t.reference,
      'recipient': t.recipient,
      // Optional: Add other fields that exist in backend
      'is_recurring': t.isRecurring,
      'payment_method': t.paymentMethod,
    };
  }

  /// ✅ NEW: Batch sync goals
  Future<EntitySyncResult> _syncGoalsBatch(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localGoals = await _offlineDataService.getAllGoals(profileId);
      result.localCount = localGoals.length;

      if (_apiClient.isAuthenticated) {
        // Upload unsynced goals
        final unsyncedGoals = localGoals.where((g) => g.remoteId == null).toList();
        
        if (unsyncedGoals.isNotEmpty) {
          final goalsData = unsyncedGoals.map((g) => _prepareGoalForUpload(g, profileId)).toList();
          final response = await _apiClient.syncGoals(profileId, goalsData);
          
          if (response['success'] == true) {
            result.uploaded += response['created'] as int? ?? 0;
          }
        }
        
        // Download from server
        final remoteGoals = await _apiClient.getGoals(profileId: profileId);
        
        for (final remote in remoteGoals) {
          final remoteId = remote['id']?.toString();
          if (remoteId == null) continue;
          
          final existsLocally = localGoals.any((g) => g.remoteId == remoteId);
          
          if (!existsLocally) {
            final goal = _parseRemoteGoal(remote, profileId);
            if (goal != null) {
              await _offlineDataService.saveGoal(goal);
              result.downloaded++;
            }
          }
        }
      }

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Goal sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// ✅ IMPROVED: Parse remote goal with progress update
  Goal? _parseRemoteGoal(Map<String, dynamic> remote, String profileId) {
    try {
      final targetAmount = _parseAmount(remote['target_amount']);
      final currentAmount = _parseAmount(remote['current_amount']);
      
      return Goal(
        id: _uuid.v4(),
        remoteId: remote['id']?.toString(),
        name: remote['name']?.toString() ?? '',
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _parseDate(remote['due_date'] ?? remote['target_date']) ?? DateTime.now(),
        profileId: profileId,
        goalType: GoalTypeExtension.fromString(remote['goal_type']?.toString() ?? 'savings'),
        status: GoalStatusExtension.fromString(remote['status']?.toString() ?? 'active'),
        currency: remote['currency']?.toString() ?? 'KES',
        description: remote['description']?.toString(),
        isSynced: true,
        createdAt: _parseDate(remote['created_at']) ?? DateTime.now(),
        updatedAt: _parseDate(remote['updated_at']) ?? DateTime.now(),
      );
    } catch (e) {
      _logger.warning('Failed to parse remote goal: $e');
      return null;
    }
  }

  Map<String, dynamic> _prepareGoalForUpload(dom.Goal g, String profileId) {
    return {
      'profile_id': profileId,
      'name': g.name,
      'target_amount': g.targetAmount,
      'current_amount': g.currentAmount,
      'goal_type': g.goalType.name,  // Use .name to get string value
      'status': g.status.name,  // Use .name to get string value
      'description': g.description,
      'due_date': g.targetDate.toIso8601String(),
      'currency': g.currency ?? 'KES',
    };
  }

  /// ✅ NEW: Batch sync budgets
  Future<EntitySyncResult> _syncBudgetsBatch(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localBudgets = await _offlineDataService.getAllBudgets(profileId);
      result.localCount = localBudgets.length;

      if (_apiClient.isAuthenticated) {
        final unsyncedBudgets = localBudgets.where((b) => b.remoteId == null).toList();
        
        if (unsyncedBudgets.isNotEmpty) {
          final budgetsData = unsyncedBudgets.map((b) => _prepareBudgetForUpload(b, profileId)).toList();
          final response = await _apiClient.syncBudgets(profileId, budgetsData);
          
          if (response['success'] == true) {
            result.uploaded += response['created'] as int? ?? 0;
          }
        }
        
        final remoteBudgets = await _apiClient.getBudgets(profileId: profileId);
        
        for (final remote in remoteBudgets) {
          final remoteId = remote['id']?.toString();
          if (remoteId == null) continue;
          
          final existsLocally = localBudgets.any((b) => b.remoteId == remoteId);
          
          if (!existsLocally) {
            final budget = _parseRemoteBudget(remote, profileId);
            if (budget != null) {
              await _offlineDataService.saveBudget(budget);
              result.downloaded++;
            }
          }
        }
      }

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Budget sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  Budget? _parseRemoteBudget(Map<String, dynamic> remote, String profileId) {
    try {
      return Budget(
        id: _uuid.v4(),
        remoteId: remote['id']?.toString(),
        name: remote['name']?.toString() ?? '',
        budgetAmount: _parseAmount(remote['budget_amount']),
        spentAmount: _parseAmount(remote['spent_amount']),
        category: remote['category']?.toString() ?? '',
        profileId: profileId,
        startDate: _parseDate(remote['start_date']) ?? DateTime.now(),
        endDate: _parseDate(remote['end_date']) ?? DateTime.now(),
        currency: remote['currency']?.toString() ?? 'KES',
        isActive: remote['is_active'] ?? true,
        isSynced: true,
        createdAt: _parseDate(remote['created_at']) ?? DateTime.now(),
        updatedAt: _parseDate(remote['updated_at']) ?? DateTime.now(),
      );
    } catch (e) {
      _logger.warning('Failed to parse remote budget: $e');
      return null;
    }
  }

  Map<String, dynamic> _prepareBudgetForUpload(Budget b, String profileId) {
    return {
      'name': b.name,
      'budget_amount': b.budgetAmount,
      'spent_amount': b.spentAmount,
      'category': b.category,
      'start_date': b.startDate.toIso8601String(),
      'end_date': b.endDate.toIso8601String(),
      'profile_id': profileId,
      'currency': b.currency ?? 'KES',
      'is_active': b.isActive,
    };
  }

  /// ✅ UPDATED: Batch sync loans with proper data processing
  Future<EntitySyncResult> _syncLoansBatch(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localLoans = await _offlineDataService.getAllLoans(profileId);
      result.localCount = localLoans.length;

      if (_apiClient.isAuthenticated) {
        final unsyncedLoans = localLoans.where((l) => l.remoteId == null).toList();
        
        // Use the new prepareLoanData method from ApiClient
        for (final loan in unsyncedLoans) {
          try {
            final payload = ApiClient.prepareLoanData(
              profileId: loan.profileId,
              name: loan.name,
              principalAmount: loan.principalAmount,
              interestRate: loan.interestRate,
              interestModel: 'simple',  // Default
              startDate: loan.startDate,
              endDate: loan.endDate,
              currency: loan.currency,
              description: loan.description,
            );
            
            final created = await _apiClient.createLoan(loan: payload);
            
            if (created['id'] != null) {
              final updatedLoan = loan.copyWith(remoteId: created['id'].toString());
              await _offlineDataService.updateLoan(updatedLoan);
              result.uploaded++;
            }
          } catch (e) {
            _logger.warning('Failed to upload loan: $e');
          }
        }
        
        final currentProfile = _authService.currentProfile;
        final sessionToken = currentProfile?.sessionToken;
        
        final remoteLoans = await _apiClient.getLoans(
          profileId: profileId,
          sessionToken: sessionToken,
        );
        
        for (final remote in remoteLoans) {
          final remoteId = remote['id']?.toString();
          if (remoteId == null) continue;
          
          final existsLocally = localLoans.any((l) => l.remoteId == remoteId);
          
          if (!existsLocally) {
            final loan = _parseRemoteLoan(remote, profileId);
            if (loan != null) {
              await _offlineDataService.saveLoan(loan);
              result.downloaded++;
            }
          }
        }
      }

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Loan sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// ✅ FIXED: Parse remote loan with correct field mapping
  Loan? _parseRemoteLoan(Map<String, dynamic> remote, String profileId) {
    try {
      return Loan(
        id: remote['id']?.toString(),
        remoteId: remote['id']?.toString(),
        name: remote['name']?.toString() ?? '',
        principalAmount: remote['principal_amount'] != null ? _parseAmount(remote['principal_amount']) : 0,
        currency: remote['currency']?.toString() ?? 'KES',
        interestRate: remote['interest_rate'] != null ? _parseAmount(remote['interest_rate']) : 0,
        interestModel: remote['interest_model']?.toString() ?? 'simple',
        startDate: _parseDate(remote['start_date']) ?? DateTime.now(),
        endDate: _parseDate(remote['end_date']) ?? DateTime.now(),
        profileId: profileId,
        description: remote['description']?.toString(),
        isSynced: remote['is_synced'] ?? false,
        createdAt: _parseDate(remote['created_at']),
        updatedAt: _parseDate(remote['updated_at']),
      );
    } catch (e) {
      _logger.warning('Failed to parse remote loan: $e');
      return null;
    }
  }

  /// ✅ FIXED: Prepare loan for upload with correct field names
  Map<String, dynamic> _prepareLoanForUpload(Loan l) {
    // First, process the loan to match backend schema
    final processedData = ApiClient.prepareLoanData(
      profileId: l.profileId,
      name: l.name,
      principalAmount: l.principalAmount,  // Use helper method
      interestRate: l.interestRate,
      interestModel: 'reducingBalance',  // Default value
      startDate: l.startDate,
      endDate: l.endDate,
      currency: l.currency,
      description: l.description,
    );
    
    return processedData;
  }

  Future<EntitySyncResult> _syncPendingTransactions(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final pending = await _offlineDataService.getPendingTransactions(profileId);
      result.localCount = pending.length;
      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// ✅ NEW: Helper to update local counts in offline mode
  Future<void> _updateLocalCounts(SyncResult result, String profileId) async {
    final localTransactions = await _offlineDataService.getAllTransactions(profileId);
    final localGoals = await _offlineDataService.getAllGoals(profileId);
    final localBudgets = await _offlineDataService.getAllBudgets(profileId);
    final localLoans = await _offlineDataService.getAllLoans(profileId);
    final pendingTransactions = await _offlineDataService.getPendingTransactions(profileId);
    
    result.transactions.localCount = localTransactions.length;
    result.goals.localCount = localGoals.length;
    result.budgets.localCount = localBudgets.length;
    result.loans.localCount = localLoans.length;
    result.pendingTransactions.localCount = pendingTransactions.length;
  }

  /// ✅ NEW: Helper to parse amounts safely
  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// ✅ NEW: Helper to parse dates safely
  DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<SyncResult> quickSync(String profileId) => syncProfile(profileId);
  Future<SyncResult> forceSync(String profileId) => syncProfile(profileId);
  Future<SyncResult> manualSync() async {
    if (_currentProfileId == null) {
      return SyncResult(
        success: false,
        error: 'No profile selected',
        timestamp: DateTime.now(),
      );
    }
    return await syncProfile(_currentProfileId!);
  }

  Future<SyncStatus> getSyncStatus() async {
    if (_currentProfileId == null) return SyncStatus.noProfile;
    if (_isSyncing) return SyncStatus.syncing;
    if (_lastSyncTime == null) return SyncStatus.neverSynced;
    
    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
    if (timeSinceLastSync > const Duration(hours: 1)) return SyncStatus.stale;
    
    return SyncStatus.upToDate;
  }

  void clearCache() {
    _currentProfileId = null;
    _lastSyncTime = null;
    _isSyncing = false;
    notifyListeners();
    _logger.info('Sync cache cleared');
  }
}

// [SyncResult, EntitySyncResult, SyncStatus classes remain the same]
class SyncResult {
  bool success;
  String? error;
  DateTime timestamp;
  bool serverAvailable;
  
  EntitySyncResult transactions;
  EntitySyncResult goals;
  EntitySyncResult budgets;
  EntitySyncResult loans;
  EntitySyncResult pendingTransactions;

  SyncResult({
    this.success = false,
    this.error,
    required this.timestamp,
    this.serverAvailable = false,
    EntitySyncResult? transactions,
    EntitySyncResult? goals,
    EntitySyncResult? budgets,
    EntitySyncResult? loans,
    EntitySyncResult? pendingTransactions,
  })  : transactions = transactions ?? EntitySyncResult(),
        goals = goals ?? EntitySyncResult(),
        budgets = budgets ?? EntitySyncResult(),
        loans = loans ?? EntitySyncResult(),
        pendingTransactions = pendingTransactions ?? EntitySyncResult();

  int get totalUploaded =>
      transactions.uploaded + goals.uploaded + budgets.uploaded + loans.uploaded;

  int get totalDownloaded =>
      transactions.downloaded + goals.downloaded + budgets.downloaded + loans.downloaded;

  int get totalLocal =>
      transactions.localCount + goals.localCount + budgets.localCount + 
      loans.localCount + pendingTransactions.localCount;
}

class EntitySyncResult {
  bool success;
  String? error;
  int uploaded;
  int downloaded;
  int localCount;

  EntitySyncResult({
    this.success = false,
    this.error,
    this.uploaded = 0,
    this.downloaded = 0,
    this.localCount = 0,
  });
}

enum SyncStatus {
  noProfile,
  neverSynced,
  upToDate,
  stale,
  syncing,
  error,
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.noProfile: return 'No Profile Selected';
      case SyncStatus.neverSynced: return 'Never Synced';
      case SyncStatus.upToDate: return 'Up to Date';
      case SyncStatus.stale: return 'Sync Required';
      case SyncStatus.syncing: return 'Syncing...';
      case SyncStatus.error: return 'Sync Error';
    }
  }

  bool get canSync {
    return this == SyncStatus.noProfile ||
           this == SyncStatus.neverSynced ||
           this == SyncStatus.stale ||
           this == SyncStatus.error;
  }
}
