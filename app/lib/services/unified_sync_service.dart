// lib/services/unified_sync_service.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../utils/logger.dart';
import 'offline_data_service.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Unified sync service for all data types
/// Handles both local persistence and server synchronization
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

  UnifiedSyncService._();

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get currentProfileId => _currentProfileId;

  /// Initialize with dependencies
  Future<void> initialize({
    required OfflineDataService offlineDataService,
    required ApiClient apiClient,
    required AuthService authService,
  }) async {
    _offlineDataService = offlineDataService;
    _apiClient = apiClient;
    _authService = authService;
    
    _isInitialized = true;
    
    // Setup auth listener to automatically handle profile changes
    _setupAuthListener();
    
    _logger.info('UnifiedSyncService initialized');
  }

  /// Setup listener for authentication state changes
  void _setupAuthListener() {
    _authService.addListener(() {
      final currentProfile = _authService.currentProfile;
      if (currentProfile != null) {
        // Automatically set profile when user logs in
        setCurrentProfile(currentProfile.id);
        
        // Trigger initial sync after login
        Future.delayed(const Duration(seconds: 1), () {
          if (_currentProfileId == currentProfile.id) {
            _logger.info('Auto-syncing after login');
            syncAll().catchError((e) {
              _logger.warning('Auto-sync failed: $e');
            });
          }
        });
      } else {
        // User logged out, clear sync cache
        clearCache();
      }
    });
  }

  /// Set current profile for sync operations
  void setCurrentProfile(String profileId) {
    if (_currentProfileId != profileId) {
      _currentProfileId = profileId;
      _logger.info('Current profile set for sync: $profileId');
      notifyListeners();
    }
  }

  /// Sync all data for current profile
  Future<SyncResult> syncAll() async {
    if (!_isInitialized) {
      _logger.warning('Sync service not initialized');
      return SyncResult(
        success: false,
        error: 'Sync service not initialized',
        timestamp: DateTime.now(),
      );
    }

    if (_currentProfileId == null) {
      _logger.warning('No profile set for sync');
      return SyncResult(
        success: false,
        error: 'No active profile',
        timestamp: DateTime.now(),
      );
    }

    return await syncProfile(_currentProfileId!);
  }

  /// Sync all data for a specific profile
  Future<SyncResult> syncProfile(String profileId) async {
    if (!_isInitialized) {
      _logger.warning('Services not initialized');
      return SyncResult(
        success: false,
        error: 'Services not initialized',
        timestamp: DateTime.now(),
      );
    }

    if (_isSyncing) {
      _logger.warning('Sync already in progress');
      return SyncResult(
        success: false,
        error: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }

    _isSyncing = true;
    notifyListeners();

    final result = SyncResult(timestamp: DateTime.now());

    try {
      _logger.info('Starting full sync for profile: $profileId');

      // Check server connectivity
      final isOnline = await _apiClient.checkServerHealth();
      result.serverAvailable = isOnline;
      _logger.info('Server available: $isOnline');

      if (isOnline) {
        // Sync each data type
        result.transactions = await _syncTransactions(profileId);
        result.goals = await _syncGoals(profileId);
        result.budgets = await _syncBudgets(profileId);
        result.loans = await _syncLoans(profileId);
        result.pendingTransactions = await _syncPendingTransactions(profileId);

        result.success = true;
        _lastSyncTime = DateTime.now();
        
        _logger.info('Sync completed successfully. '
            'Downloaded: ${result.totalDownloaded}, '
            'Uploaded: ${result.totalUploaded}, '
            'Total local: ${result.totalLocal}');
      } else {
        _logger.info('Server offline, only local operations performed');
        result.success = true;
        _lastSyncTime = DateTime.now();
        
        // Still update local counts even when offline
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

  /// Sync transactions with server and local database
  Future<EntitySyncResult> _syncTransactions(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      // Get local transactions
      final localTransactions = await _offlineDataService.getAllTransactions(profileId);
      result.localCount = localTransactions.length;
      _logger.info('Found ${localTransactions.length} local transactions');

      if (_apiClient.isAuthenticated) {
        try {
          // ✅ STEP 1: UPLOAD local transactions to server FIRST
          _logger.info('📤 UPLOADING local transactions to server...');
          final unsyncedTransactions = localTransactions.where((t) => t.remoteId == null).toList();
          
          if (unsyncedTransactions.isNotEmpty) {
            _logger.info('Uploading ${unsyncedTransactions.length} transactions to server');
            
            for (final transaction in unsyncedTransactions) {
              try {
                // Prepare transaction data using ApiClient helper
                final payload = ApiClient.prepareTransactionData(
                  profileId: profileId,
                  amountMinor: transaction.amountMinor,
                  transactionType: transaction.transactionType,
                  description: transaction.description ?? '',
                  category: transaction.category,
                  goalId: transaction.goalId,
                  date: transaction.date,
                  isExpense: transaction.isExpense ?? transaction.transactionType == 'expense',
                  currency: transaction.currency ?? 'KES',
                  isSynced: true,
                );
                
                final response = await _apiClient.createTransaction(payload);
                final remoteId = response['id']?.toString();
                
                if (remoteId != null) {
                  // Update local transaction with remoteId
                  final updatedTransaction = transaction.copyWith(
                    remoteId: remoteId,
                    isSynced: true,
                    updatedAt: DateTime.now(),
                  );
                  await _offlineDataService.updateTransaction(updatedTransaction);
                  _logger.info('✅ Transaction uploaded with remote ID: $remoteId');
                  result.uploaded++;
                }
              } catch (e) {
                _logger.warning('Failed to upload transaction: $e');
              }
            }
          }
          
          // ✅ STEP 2: DOWNLOAD transactions from server (after upload)
          _logger.info('📥 DOWNLOADING transactions from server...');
          final remoteTransactions = await _apiClient.getTransactions(profileId: profileId);
          _logger.info('Downloaded ${remoteTransactions.length} transactions from server');
          
          // ✅ STEP 3: Merge ONLY NEW remote transactions (don't overwrite existing)
          for (final remote in remoteTransactions) {
            try {
              final remoteId = remote['id']?.toString();
              if (remoteId == null) continue;
              
              // Check if transaction already exists locally by remoteId
              final existsLocally = localTransactions.any((t) => t.remoteId == remoteId);
              
              if (!existsLocally) {
                // Convert server transaction to local model
                final amountMinor = int.tryParse(remote['amount_minor']?.toString() ?? '0') ?? 0;
                final isExpense = remote['is_expense'] == true;
                final transactionType = remote['transaction_type']?.toString() ?? 
                    (isExpense ? 'expense' : 'income');
                
                final transaction = Transaction(
                  id: _uuid.v4(),
                  remoteId: remoteId,
                  profileId: profileId,
                  amountMinor: amountMinor,
                  transactionType: transactionType,
                  isExpense: isExpense,
                  category: remote['category']?.toString() ?? '',
                  description: remote['description']?.toString() ?? '',
                  date: DateTime.tryParse(remote['date']?.toString() ?? '') ?? DateTime.now(),
                  goalId: remote['goal_id']?.toString(),
                  budgetCategory: remote['budget_category']?.toString(),
                  currency: remote['currency']?.toString() ?? 'KES',
                  isSynced: true,
                  createdAt: DateTime.tryParse(remote['created_at']?.toString() ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.tryParse(remote['updated_at']?.toString() ?? '') ?? DateTime.now(),
                );
                
                await _offlineDataService.saveTransaction(transaction);
                _logger.info('✅ New transaction downloaded: ${transaction.description}');
                result.downloaded++;
              } else {
                _logger.info('⏭️ Transaction already exists locally: ${remote['description']}');
              }
            } catch (e) {
              _logger.warning('Failed to process remote transaction: $e');
            }
          }
          
        } catch (e) {
          _logger.warning('Transaction server sync failed: $e');
          result.error = 'Server sync failed: $e';
        }
      } else {
        _logger.info('User not authenticated, skipping server sync for transactions');
      }

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Transaction sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync goals with currentAmount field
  Future<EntitySyncResult> _syncGoals(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localGoals = await _offlineDataService.getAllGoals(profileId);
      result.localCount = localGoals.length;
      _logger.info('Found ${localGoals.length} local goals');

      if (_apiClient.isAuthenticated) {
        try {
          // ✅ STEP 1: UPLOAD local goals to server FIRST
          _logger.info('📤 UPLOADING local goals to server...');
          for (final localGoal in localGoals) {
            if (localGoal.remoteId == null || localGoal.remoteId!.isEmpty) {
              try {
                // Prepare goal data using ApiClient helper
                final payload = ApiClient.prepareGoalData(
                  profileId: profileId,
                  name: localGoal.name,
                  targetAmount: localGoal.targetAmount,
                  goalType: localGoal.goalType ?? 'savings',
                  status: localGoal.status ?? 'active',
                  description: localGoal.description,
                  dueDate: localGoal.targetDate,
                  currentAmount: localGoal.currentAmount,
                  currency: localGoal.currency ?? 'KES',
                );
                
                final response = await _apiClient.createGoal(payload);
                final remoteId = response['id']?.toString();
                
                if (remoteId != null) {
                  // Update local goal with remoteId
                  final updatedGoal = localGoal.copyWith(
                    remoteId: remoteId,
                    isSynced: true,
                    updatedAt: DateTime.now(),
                  );
                  await _offlineDataService.updateGoal(updatedGoal);
                  _logger.info('✅ Goal uploaded with remote ID: $remoteId');
                  result.uploaded++;
                }
              } catch (e) {
                _logger.warning('Failed to upload goal: $e');
              }
            }
          }
          
          // ✅ STEP 2: DOWNLOAD goals from server (after upload)
          _logger.info('📥 DOWNLOADING goals from server...');
          final remoteGoals = await _apiClient.getGoals(profileId: profileId);
          _logger.info('Downloaded ${remoteGoals.length} goals from server');
          
          // ✅ STEP 3: Merge ONLY NEW remote goals (don't overwrite existing)
          for (final remote in remoteGoals) {
            try {
              final remoteId = remote['id']?.toString();
              if (remoteId == null) continue;
              
              final name = remote['name']?.toString() ?? '';
              final targetAmount = double.tryParse(remote['target_amount']?.toString() ?? '0') ?? 0.0;
              final currentAmount = double.tryParse(remote['current_amount']?.toString() ?? '0') ?? 0.0;
              final dueDate = DateTime.tryParse(remote['due_date']?.toString() ?? '') ?? 
                              DateTime.tryParse(remote['target_date']?.toString() ?? '') ?? 
                              DateTime.now();
              final status = remote['status']?.toString() ?? 'active';
              final goalType = remote['goal_type']?.toString() ?? 'savings';
              final currency = remote['currency']?.toString() ?? 'KES';
              
              // Check if goal exists locally by remoteId
              final existingGoal = localGoals.firstWhere(
                (g) => g.remoteId == remoteId,
                orElse: () => Goal.empty(),
              );
              
              // Only download if NOT already present locally
              if (existingGoal.id!.isEmpty) {
                final goal = Goal(
                  id: _uuid.v4(),
                  remoteId: remoteId,
                  name: name,
                  targetAmount: targetAmount,
                  currentAmount: currentAmount,
                  targetDate: dueDate,
                  profileId: profileId,
                  goalType: goalType,
                  status: status,
                  currency: currency,
                  isSynced: true,
                  createdAt: DateTime.tryParse(remote['created_at']?.toString() ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.tryParse(remote['updated_at']?.toString() ?? '') ?? DateTime.now(),
                );
                
                await _offlineDataService.saveGoal(goal);
                _logger.info('✅ New goal downloaded: ${goal.name}');
                result.downloaded++;
              } else {
                _logger.info('⏭️ Goal already exists locally: ${existingGoal.name}');
              }
            } catch (e) {
              _logger.warning('Failed to process remote goal: $e');
            }
          }
          
        } catch (e) {
          _logger.warning('Goal server sync failed: $e');
          result.error = 'Server sync failed: $e';
        }
      } else {
        _logger.info('User not authenticated, skipping server sync for goals');
      }

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Goal sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync budgets - UPLOAD LOCAL CHANGES FIRST, THEN DOWNLOAD
  Future<EntitySyncResult> _syncBudgets(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localBudgets = await _offlineDataService.getAllBudgets(profileId);
      result.localCount = localBudgets.length;
      _logger.info('Found ${localBudgets.length} local budgets');

      if (_apiClient.isAuthenticated) {
        try {
          // ✅ STEP 1: UPLOAD local budgets to server FIRST
          _logger.info('📤 UPLOADING local budgets to server...');
          for (final localBudget in localBudgets) {
            if (localBudget.remoteId == null || localBudget.remoteId!.isEmpty) {
              try {
                final payload = {
                  'name': localBudget.name,
                  'budget_amount': localBudget.budgetAmount,
                  'spent_amount': localBudget.spentAmount,
                  'category': localBudget.category, // Changed from categoryId to category
                  'start_date': localBudget.startDate.toIso8601String(),
                  'end_date': localBudget.endDate.toIso8601String(),
                  'profile_id': profileId,
                  'currency': localBudget.currency ?? 'KES',
                  'is_active': localBudget.isActive,
                };
                
                final response = await _apiClient.createBudget(payload);
                final remoteId = response['id']?.toString();
                
                if (remoteId != null) {
                  // Update local budget with remoteId
                  final updatedBudget = localBudget.copyWith(
                    remoteId: remoteId,
                    isSynced: true,
                    updatedAt: DateTime.now(),
                  );
                  await _offlineDataService.updateBudget(updatedBudget);
                  _logger.info('✅ Budget uploaded with remote ID: $remoteId');
                  result.uploaded++;
                }
              } catch (e) {
                _logger.warning('Failed to upload budget: $e');
              }
            }
          }
          
          // ✅ STEP 2: DOWNLOAD budgets from server (after upload)
          _logger.info('📥 DOWNLOADING budgets from server...');
          final remoteBudgets = await _apiClient.getBudgets(profileId: profileId);
          _logger.info('Downloaded ${remoteBudgets.length} budgets from server');
          
          // ✅ STEP 3: Merge ONLY NEW remote budgets (don't overwrite existing)
          for (final remote in remoteBudgets) {
            try {
              final remoteId = remote['id']?.toString();
              if (remoteId == null) continue;
              
              // Check if budget already exists locally
              final existingBudget = localBudgets.firstWhere(
                (b) => b.remoteId == remoteId,
                orElse: () => Budget.empty(),
              );
              
              // Only download if NOT already present locally
              if (existingBudget.id.isEmpty) {
                final budget = Budget(
                  id: _uuid.v4(),
                  remoteId: remoteId,
                  name: remote['name']?.toString() ?? '',
                  budgetAmount: double.tryParse(remote['budget_amount']?.toString() ?? '0') ?? 0.0,
                  spentAmount: double.tryParse(remote['spent_amount']?.toString() ?? '0') ?? 0.0,
                  category: remote['category']?.toString() ?? '', // Changed from category_id to category
                  profileId: profileId,
                  startDate: DateTime.tryParse(remote['start_date']?.toString() ?? '') ?? DateTime.now(),
                  endDate: DateTime.tryParse(remote['end_date']?.toString() ?? '') ?? DateTime.now(),
                  currency: remote['currency']?.toString() ?? 'KES',
                  isActive: remote['is_active'] ?? true,
                  isSynced: true,
                  createdAt: DateTime.tryParse(remote['created_at']?.toString() ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.tryParse(remote['updated_at']?.toString() ?? '') ?? DateTime.now(),
                );
                
                await _offlineDataService.saveBudget(budget);
                _logger.info('✅ New budget downloaded: ${budget.name}');
                result.downloaded++;
              } else {
                _logger.info('⏭️ Budget already exists locally: ${existingBudget.name}');
              }
            } catch (e) {
              _logger.warning('Failed to process remote budget: $e');
            }
          }
          
        } catch (e) {
          _logger.warning('Budget server sync failed: $e');
          result.error = 'Server sync failed: $e';
        }
      } else {
        _logger.info('User not authenticated, skipping server sync for budgets');
      }

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Budget sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync loans - UPLOAD LOCAL CHANGES FIRST, THEN DOWNLOAD
  Future<EntitySyncResult> _syncLoans(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localLoans = await _offlineDataService.getAllLoans(profileId);
      result.localCount = localLoans.length;
      _logger.info('Found ${localLoans.length} local loans');

      if (_apiClient.isAuthenticated) {
        try {
          // ✅ STEP 1: UPLOAD local loans to server FIRST
          _logger.info('📤 UPLOADING local loans to server...');
          for (final localLoan in localLoans) {
            try {
              if (localLoan.remoteId == null || localLoan.remoteId!.isEmpty) {
                final payload = {
                  'name': localLoan.name,
                  'principal_minor': localLoan.principalMinor,
                  'currency': localLoan.currency,
                  'interest_rate': localLoan.interestRate,
                  'start_date': localLoan.startDate.toIso8601String(),
                  'end_date': localLoan.endDate.toIso8601String(),
                  'profile_id': localLoan.profileId,
                };

                final created = await _apiClient.createLoan(loan: payload);
                final createdId = created['id']?.toString();
                if (createdId != null) {
                  // Update local loan with remote ID
                  final updatedLoan = localLoan.copyWith(remoteId: createdId);
                  await _offlineDataService.updateLoan(updatedLoan);
                  _logger.info('✅ Loan uploaded with remote ID: $createdId');
                  result.uploaded++;
                }
              }
            } catch (e) {
              _logger.warning('Failed to push local loan to server: $e');
            }
          }
          
          // ✅ STEP 2: DOWNLOAD loans from server (after upload)
          _logger.info('📥 DOWNLOADING loans from server...');
          // Get session token for authentication
          final currentProfile = _authService.currentProfile;
          final sessionToken = currentProfile?.sessionToken;
          
          // Download loans from server
          final remoteLoans = await _apiClient.getLoans(
            profileId: profileId,
            sessionToken: sessionToken,
          );
          
          _logger.info('Downloaded ${remoteLoans.length} loans from server');

          // ✅ STEP 3: Merge ONLY NEW remote loans (don't overwrite existing)
          for (final remote in remoteLoans) {
            try {
              final remoteId = remote['id']?.toString();
              if (remoteId == null) continue;
              
              final name = remote['name']?.toString() ?? '';
              final principalMinor = (remote['principal_minor'] is int)
                  ? (remote['principal_minor'] as int).toDouble()
                  : (remote['principal_minor'] is double)
                      ? remote['principal_minor'] as double
                      : double.tryParse(remote['principal_minor']?.toString() ?? '0') ?? 0.0;
              final interestRate = double.tryParse(remote['interest_rate']?.toString() ?? '0') ?? 0.0;
              final startDate = DateTime.tryParse(remote['start_date']?.toString() ?? '') ?? DateTime.now();
              final endDate = DateTime.tryParse(remote['end_date']?.toString() ?? '') ?? DateTime.now();
              final profileIdRemote = remote['profile_id']?.toString() ?? profileId;
              
              // Check if loan exists locally
              final exists = localLoans.any((loan) => 
                (loan.remoteId == remoteId) ||
                (loan.name == name && loan.startDate == startDate)
              );
              
              // Only download if NOT already present locally
              if (!exists) {
                final loan = Loan(
                  name: name,
                  principalMinor: principalMinor,
                  currency: remote['currency']?.toString() ?? 'KES',
                  interestRate: interestRate,
                  startDate: startDate,
                  endDate: endDate,
                  profileId: profileIdRemote,
                  remoteId: remoteId,
                );

                await _offlineDataService.saveLoan(loan);
                _logger.info('✅ New loan downloaded: ${loan.name}');
                result.downloaded++;
              } else {
                _logger.info('⏭️ Loan already exists locally: $name');
              }
            } catch (e) {
              _logger.warning('Failed to merge remote loan: $e');
            }
          }
          
        } catch (e) {
          _logger.warning('Loan server sync failed: $e');
          result.error = 'Server sync failed: $e';
        }
      } else {
        _logger.info('User not authenticated, skipping server sync for loans');
      }

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Loan sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync pending transactions (SMS candidates)
  Future<EntitySyncResult> _syncPendingTransactions(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final pending = await _offlineDataService.getPendingTransactions(profileId);
      result.localCount = pending.length;
      
      if (pending.isNotEmpty) {
        _logger.info('Found ${pending.length} pending transactions');
        
        // Optionally process pending transactions here
        // For example, try to match them with existing transactions
        // or upload them as new transactions
      }
      
      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Pending transaction sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Quick sync - only syncs unsynced items
  Future<SyncResult> quickSync(String profileId) async {
    _logger.info('Starting quick sync for profile: $profileId');
    
    // For now, quick sync is the same as full sync
    // In future, this can be optimized to only sync changed items
    return await syncProfile(profileId);
  }

  /// Force sync all data (ignoring sync status)
  Future<SyncResult> forceSync(String profileId) async {
    _logger.info('Starting force sync for profile: $profileId');
    
    // Force a complete sync cycle
    return await syncProfile(profileId);
  }

  /// Manual sync trigger (for UI buttons)
  Future<SyncResult> manualSync() async {
    if (_currentProfileId == null) {
      return SyncResult(
        success: false,
        error: 'No profile selected',
        timestamp: DateTime.now(),
      );
    }
    
    _logger.info('Manual sync triggered');
    return await syncProfile(_currentProfileId!);
  }

  /// Check sync status
  Future<SyncStatus> getSyncStatus() async {
    if (_currentProfileId == null) {
      return SyncStatus.noProfile;
    }
    
    if (_isSyncing) {
      return SyncStatus.syncing;
    }
    
    if (_lastSyncTime == null) {
      return SyncStatus.neverSynced;
    }
    
    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
    if (timeSinceLastSync > const Duration(hours: 1)) {
      return SyncStatus.stale;
    }
    
    return SyncStatus.upToDate;
  }

  /// Clear sync cache (call on logout)
  void clearCache() {
    _currentProfileId = null;
    _lastSyncTime = null;
    _isSyncing = false;
    notifyListeners();
    _logger.info('Sync cache cleared');
  }
}

/// Sync result for entire sync operation
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
      transactions.uploaded +
      goals.uploaded +
      budgets.uploaded +
      loans.uploaded;

  int get totalDownloaded =>
      transactions.downloaded +
      goals.downloaded +
      budgets.downloaded +
      loans.downloaded;

  int get totalLocal =>
      transactions.localCount +
      goals.localCount +
      budgets.localCount +
      loans.localCount +
      pendingTransactions.localCount;

  Map<String, dynamic> toJson() => {
    'success': success,
    'error': error,
    'timestamp': timestamp.toIso8601String(),
    'serverAvailable': serverAvailable,
    'transactions': {
      'success': transactions.success,
      'uploaded': transactions.uploaded,
      'downloaded': transactions.downloaded,
      'localCount': transactions.localCount,
    },
    'goals': {
      'success': goals.success,
      'uploaded': goals.uploaded,
      'downloaded': goals.downloaded,
      'localCount': goals.localCount,
    },
    'budgets': {
      'success': budgets.success,
      'uploaded': budgets.uploaded,
      'downloaded': budgets.downloaded,
      'localCount': budgets.localCount,
    },
    'loans': {
      'success': loans.success,
      'uploaded': loans.uploaded,
      'downloaded': loans.downloaded,
      'localCount': loans.localCount,
    },
    'totalUploaded': totalUploaded,
    'totalDownloaded': totalDownloaded,
    'totalLocal': totalLocal,
  };
}

/// Sync result for a specific entity type
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

  Map<String, dynamic> toJson() => {
    'success': success,
    'error': error,
    'uploaded': uploaded,
    'downloaded': downloaded,
    'localCount': localCount,
  };
}

/// Sync status enum for UI display
enum SyncStatus {
  noProfile,
  neverSynced,
  upToDate,
  stale,
  syncing,
  error,
}

/// Extension for SyncStatus
extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.noProfile:
        return 'No Profile Selected';
      case SyncStatus.neverSynced:
        return 'Never Synced';
      case SyncStatus.upToDate:
        return 'Up to Date';
      case SyncStatus.stale:
        return 'Sync Required';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.error:
        return 'Sync Error';
    }
  }

  bool get canSync {
    return this == SyncStatus.noProfile ||
           this == SyncStatus.neverSynced ||
           this == SyncStatus.stale ||
           this == SyncStatus.error;
  }
}
