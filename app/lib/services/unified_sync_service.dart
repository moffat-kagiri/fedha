// lib/services/unified_sync_service.dart 
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

  /// ✅ FIXED: Batch sync with better validation and error logging
  Future<EntitySyncResult> _syncTransactionsBatch(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localTransactions = await _offlineDataService.getAllTransactions(profileId);
      result.localCount = localTransactions.length;

      if (_apiClient.isAuthenticated) {
        // STEP 1: Upload unsynced transactions in batches
        final unsyncedTransactions = localTransactions
            .where((t) => t.remoteId == null || t.remoteId!.isEmpty)
            .toList();
        
        if (unsyncedTransactions.isNotEmpty) {
          _logger.info('📤 Uploading ${unsyncedTransactions.length} transactions');
          
          // ✅ FIXED: Validate and prepare data with profile_id
          final batchData = <Map<String, dynamic>>[];
          
          for (final t in unsyncedTransactions) {
            // ✅ Validate required fields before upload
            if (t.amount <= 0) {
              _logger.warning('⚠️ Skipping transaction with invalid amount: ${t.amount}');
              continue;
            }
            
            if (t.type.isEmpty) {
              _logger.warning('⚠️ Skipping transaction with empty type');
              continue;
            }
            
            // Validate type is one of the allowed values
            if (!['income', 'expense', 'savings', 'transfer'].contains(t.type.toLowerCase())) {
              _logger.warning('⚠️ Skipping transaction with invalid type: ${t.type}');
              continue;
            }
            
            // ✅ Use the fixed helper method
            final txData = _prepareTransactionForUpload(t, profileId);
            batchData.add(txData);
          }
          
          _logger.info('📤 Prepared ${batchData.length} valid transactions for upload');
          
          // ✅ Log first transaction for debugging
          if (batchData.isNotEmpty) {
            _logger.info('📤 Sample transaction data: ${batchData.first}');
          }
          
          if (batchData.isNotEmpty) {
            // Process in batches for better performance
            for (int i = 0; i < batchData.length; i += _batchSize) {
              final batch = batchData.skip(i).take(_batchSize).toList();
              
              _logger.info('📤 Uploading batch ${(i ~/ _batchSize) + 1}/${(batchData.length / _batchSize).ceil()}');
              
              final response = await _apiClient.syncTransactions(profileId, batch);
              
              _logger.info('📥 Sync response: $response');
              
              if (response['success'] == true) {
                final created = response['created'] as int? ?? 0;
                final updated = response['updated'] as int? ?? 0;
                result.uploaded += created + updated;
                
                _logger.info('✅ Batch uploaded: $created created, $updated updated');
                
                // ✅ NEW: Set remoteId on uploaded transactions
                final createdIds = response['created_ids'] as List? ?? [];
                if (createdIds.isNotEmpty) {
                  _logger.info('📌 Tracking ${createdIds.length} created transaction IDs');
                  for (int j = 0; j < batch.length && j < createdIds.length; j++) {
                    final batchItem = batch[j];
                    final remoteId = createdIds[j]?.toString();
                    if (remoteId != null && batchItem['amount'] != null) {
                      // Find local transaction by amount and date to set remoteId
                      final txDate = batchItem['date'];
                      final txAmount = (batchItem['amount'] as num?)?.toInt();
                      if (txDate != null && txAmount != null) {
                        await _offlineDataService.updateTransactionRemoteId(
                          amount: txAmount,
                          date: txDate,
                          profileId: profileId,
                          remoteId: remoteId,
                        );
                      }
                    }
                  }
                }
                
                // ✅ Log any errors
                if (response['errors'] != null && (response['errors'] as List).isNotEmpty) {
                  _logger.warning('⚠️ Sync errors: ${response['errors']}');
                  
                  // Log each error in detail
                  for (final error in (response['errors'] as List)) {
                    _logger.warning('  - $error');
                  }
                }
              } else {
                _logger.severe('❌ Batch sync failed: ${response['error'] ?? response['body']}');
              }
            }
          }
        } else {
          _logger.info('No unsynced transactions to upload');
        }

        // STEP 2: Download from server
        final remoteTransactions = await _apiClient.getTransactions(profileId: profileId);
        _logger.info('📥 Downloaded ${remoteTransactions.length} transactions from server');

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

  /// ✅ FIXED: Prepare transaction for upload with correct field names and profile_id
  Map<String, dynamic> _prepareTransactionForUpload(Transaction t, String profileId) {
    final data = <String, dynamic>{
      // ✅ CRITICAL FIX: Must include profile_id for backend validation
      'profile_id': profileId,
      
      // Core transaction fields (REQUIRED by backend)
      'amount': t.amount,  // Backend expects major units (e.g., 100.50)
      'type': t.type,      // Must be: 'income', 'expense', 'savings', 'transfer'
      'description': t.description ?? '',  // Default to empty string
      'date': t.date.toIso8601String(),
      
      // Required fields with defaults
      'is_expense': t.isExpense ?? (t.type == 'expense'),
      'currency': t.currency ?? 'KES',
      'status': t.status ?? 'completed',
      'is_synced': true,  // Mark as synced after upload
      'is_recurring': t.isRecurring ?? false,
      'is_pending': t.isPending ?? false,
    };
    
    // ✅ CRITICAL FIX: Only add optional fields if they have non-null, non-empty values
    // This prevents "field may not be null" errors from Django backend
    
    if (t.category != null && t.category!.isNotEmpty) {
      data['category'] = t.category;
    }
    
    if (t.goalId != null && t.goalId!.isNotEmpty) {
      data['goal_id'] = t.goalId;
    }
    
    if (t.budgetCategory != null && t.budgetCategory!.isNotEmpty) {
      data['budget_category'] = t.budgetCategory;
    }
    
    if (t.paymentMethod != null && t.paymentMethod!.isNotEmpty) {
      data['payment_method'] = t.paymentMethod;
    }
    
    if (t.merchantName != null && t.merchantName!.isNotEmpty) {
      data['merchant_name'] = t.merchantName;
    }
    
    if (t.merchantCategory != null && t.merchantCategory!.isNotEmpty) {
      data['merchant_category'] = t.merchantCategory;
    }
    
    if (t.tags != null && t.tags!.isNotEmpty) {
      data['tags'] = t.tags;
    }
    
    if (t.reference != null && t.reference!.isNotEmpty) {
      data['reference'] = t.reference;
    }
    
    if (t.recipient != null && t.recipient!.isNotEmpty) {
      data['recipient'] = t.recipient;
    }
    
    if (t.smsSource != null && t.smsSource!.isNotEmpty) {
      data['sms_source'] = t.smsSource;
    }
    
    if (t.notes != null && t.notes!.isNotEmpty) {
      data['notes'] = t.notes;
    }
    
    if (t.location != null && t.location!.isNotEmpty) {
      data['location'] = t.location;
    }
    
    // ✅ Add remote_id if it exists (for updates)
    if (t.remoteId != null && t.remoteId!.isNotEmpty) {
      data['remote_id'] = t.remoteId;
    }
    
    return data;
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

  Map<String, dynamic> _prepareGoalForUpload(Goal g, String profileId) {
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
        
        // ✅ NEW: Use bulk_sync instead of individual POSTs
        if (unsyncedLoans.isNotEmpty) {
          final loansData = unsyncedLoans.map((l) => _prepareLoanForUpload(l)).toList();
          final response = await _apiClient.syncLoans(profileId, loansData);
          
          if (response['success'] == true) {
            result.uploaded += response['created'] as int? ?? 0;
          }
        }
        
        // Download from server
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

  /// ✅ NEW: Perform initial sync after login/signup
  /// Downloads all user data from server and saves to local database
  Future<SyncResult> performInitialSync(String profileId, String authToken) async {
    if (_isSyncing) {
      _logger.warning('Sync already in progress, skipping initial sync');
      return SyncResult(
        success: false,
        error: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }

    _isSyncing = true;
    _currentProfileId = profileId;
    notifyListeners();

    final result = SyncResult(timestamp: DateTime.now());

    try {
      _logger.info('📥 Starting initial sync for profile: $profileId');

      final isOnline = await _apiClient.checkServerHealth();
      result.serverAvailable = isOnline;

      if (!isOnline) {
        _logger.warning('Server unavailable - cannot perform initial sync');
        result.success = false;
        result.error = 'Server unavailable';
        return result;
      }

      // ==================== DOWNLOAD ALL DATA FROM SERVER ====================
      
      // 1. Fetch and save transactions
      result.transactions = await _downloadAndSaveTransactions(profileId, authToken);
      
      // 2. Fetch and save goals
      result.goals = await _downloadAndSaveGoals(profileId, authToken);
      
      // 3. Fetch and save budgets
      result.budgets = await _downloadAndSaveBudgets(profileId, authToken);
      
      // 4. Fetch and save loans
      result.loans = await _downloadAndSaveLoans(profileId, authToken);
      
      result.success = true;
      _lastSyncTime = DateTime.now();
      
      _logger.info('✅ Initial sync complete. Downloaded: ${result.totalDownloaded} items');
      
    } catch (e, stackTrace) {
      _logger.severe('Initial sync failed', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return result;
  }

  /// ✅ NEW: Download and save transactions
  Future<EntitySyncResult> _downloadAndSaveTransactions(String profileId, String authToken) async {
    final result = EntitySyncResult();
    
    try {
      _logger.info('📥 Downloading transactions...');
      
      final transactionsJson = await _apiClient.getTransactions(
        profileId: profileId,
        sessionToken: authToken,
      );
      
      _logger.info('Received ${transactionsJson.length} transactions from server');
      
      // Convert and save each transaction
      for (final txJson in transactionsJson) {
        try {
          final transaction = _parseRemoteTransaction(txJson, profileId);
          
          if (transaction != null) {
            // Check if already exists locally
            final localTransactions = await _offlineDataService.getAllTransactions(profileId);
            final remoteId = txJson['id']?.toString();
            
            final existsLocally = localTransactions.any((t) => 
              t.remoteId == remoteId || t.id == remoteId
            );
            
            if (!existsLocally) {
              await _offlineDataService.saveTransaction(transaction);
              result.downloaded++;
            } else {
              _logger.info('Transaction already exists locally: $remoteId');
            }
          }
        } catch (e) {
          _logger.warning('Failed to parse transaction: $e');
        }
      }
      
      result.success = true;
      _logger.info('✅ Saved ${result.downloaded} new transactions');
      
    } catch (e, stackTrace) {
      _logger.severe('Failed to download transactions', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }
    
    return result;
  }

  /// ✅ NEW: Download and save goals
  Future<EntitySyncResult> _downloadAndSaveGoals(String profileId, String authToken) async {
    final result = EntitySyncResult();
    
    try {
      _logger.info('📥 Downloading goals...');
      
      final goalsJson = await _apiClient.getGoals(
        profileId: profileId,
        sessionToken: authToken,
      );
      
      _logger.info('Received ${goalsJson.length} goals from server');
      
      // Convert and save each goal
      for (final goalJson in goalsJson) {
        try {
          final goal = _parseRemoteGoal(goalJson, profileId);
          
          if (goal != null) {
            // Check if already exists locally
            final localGoals = await _offlineDataService.getAllGoals(profileId);
            final remoteId = goalJson['id']?.toString();
            
            final existsLocally = localGoals.any((g) => 
              g.remoteId == remoteId || g.id == remoteId
            );
            
            if (!existsLocally) {
              await _offlineDataService.saveGoal(goal);
              result.downloaded++;
            } else {
              _logger.info('Goal already exists locally: $remoteId');
            }
          }
        } catch (e) {
          _logger.warning('Failed to parse goal: $e');
        }
      }
      
      result.success = true;
      _logger.info('✅ Saved ${result.downloaded} new goals');
      
    } catch (e, stackTrace) {
      _logger.severe('Failed to download goals', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }
    
    return result;
  }

  /// ✅ NEW: Download and save budgets
  Future<EntitySyncResult> _downloadAndSaveBudgets(String profileId, String authToken) async {
    final result = EntitySyncResult();
    
    try {
      _logger.info('📥 Downloading budgets...');
      
      final budgetsJson = await _apiClient.getBudgets(
        profileId: profileId,
        sessionToken: authToken,
      );
      
      _logger.info('Received ${budgetsJson.length} budgets from server');
      
      // Convert and save each budget
      for (final budgetJson in budgetsJson) {
        try {
          final budget = _parseRemoteBudget(budgetJson, profileId);
          
          if (budget != null) {
            // Check if already exists locally
            final localBudgets = await _offlineDataService.getAllBudgets(profileId);
            final remoteId = budgetJson['id']?.toString();
            
            final existsLocally = localBudgets.any((b) => 
              b.remoteId == remoteId || b.id == remoteId
            );
            
            if (!existsLocally) {
              await _offlineDataService.saveBudget(budget);
              result.downloaded++;
            } else {
              _logger.info('Budget already exists locally: $remoteId');
            }
          }
        } catch (e) {
          _logger.warning('Failed to parse budget: $e');
        }
      }
      
      result.success = true;
      _logger.info('✅ Saved ${result.downloaded} new budgets');
      
    } catch (e, stackTrace) {
      _logger.severe('Failed to download budgets', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }
    
    return result;
  }

  /// ✅ NEW: Download and save loans
  Future<EntitySyncResult> _downloadAndSaveLoans(String profileId, String authToken) async {
    final result = EntitySyncResult();
    
    try {
      _logger.info('📥 Downloading loans...');
      
      final loansJson = await _apiClient.getLoans(
        profileId: profileId,
        sessionToken: authToken,
      );
      
      _logger.info('Received ${loansJson.length} loans from server');
      
      // Convert and save each loan
      for (final loanJson in loansJson) {
        try {
          final loan = _parseRemoteLoan(loanJson, profileId);
          
          if (loan != null) {
            // Check if already exists locally
            final localLoans = await _offlineDataService.getAllLoans(profileId);
            final remoteId = loanJson['id']?.toString();
            
            final existsLocally = localLoans.any((l) => 
              l.remoteId == remoteId || l.id == remoteId
            );
            
            if (!existsLocally) {
              await _offlineDataService.saveLoan(loan);
              result.downloaded++;
            } else {
              _logger.info('Loan already exists locally: $remoteId');
            }
          }
        } catch (e) {
          _logger.warning('Failed to parse loan: $e');
        }
      }
      
      result.success = true;
      _logger.info('✅ Saved ${result.downloaded} new loans');
      
    } catch (e, stackTrace) {
      _logger.severe('Failed to download loans', e, stackTrace);
      result.success = false;
      result.error = e.toString();
    }
    
    return result;
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
