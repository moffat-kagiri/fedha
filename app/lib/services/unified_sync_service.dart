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

  // This method now includes robust validation of transaction data before upload,
  // detailed logging of each step, and improved parsing of remote transactions.
  Future<EntitySyncResult> _syncTransactionsBatch(String profileId) async {
    final result = EntitySyncResult();

    try {
      // ── INITIAL LOCAL SNAPSHOT ──────────────────────────────────────────────
      // Loaded once at the top. Phases 1a/1b/1c operate on this snapshot.
      // Phase 2 (download) re-fetches from DB AFTER all writes have committed.
      final localTransactions =
          await _offlineDataService.getAllTransactions(profileId);
      result.localCount = localTransactions.length;

      if (!_apiClient.isAuthenticated) {
        result.success = true;
        return result;
      }

      // ── GOAL → REMOTE-ID MAP (needed for goal_id field in upload payload) ──
      final allGoals = await _offlineDataService.getAllGoals(profileId);
      final goalIdToRemoteIdMap = <String, String>{};
      for (final goal in allGoals) {
        if (goal.id != null &&
            goal.id!.isNotEmpty &&
            goal.remoteId != null &&
            goal.remoteId!.isNotEmpty) {
          goalIdToRemoteIdMap[goal.id!] = goal.remoteId!;
        }
      }
      _logger.info(
          '📍 Goal remoteId mapping: ${goalIdToRemoteIdMap.length} goals found');

      // ════════════════════════════════════════════════════════════════════════
      // PHASE 1 — UPLOAD  (must fully complete before Phase 2 snapshot)
      // ════════════════════════════════════════════════════════════════════════

      // ── STEP 1a: NEW transactions (no remoteId yet) ─────────────────────────
      final unsyncedTransactions = localTransactions
          .where((t) =>
              !t.isDeleted &&
              (t.remoteId == null || t.remoteId!.isEmpty) &&
              !t.isPending)
          .toList();

      if (unsyncedTransactions.isNotEmpty) {
        _logger.info(
            '📤 Uploading ${unsyncedTransactions.length} NEW transactions');

        final batchData = <Map<String, dynamic>>[];
        // Maps sequential batch index → original Transaction so we can write
        // back the remoteId returned by the server.
        final batchTransactionMap = <int, Transaction>{};

        int batchIndex = 0;
        for (final t in unsyncedTransactions) {
          // Validate required fields
          if (t.amount <= 0) {
            _logger.warning(
                '⚠️ Skipping transaction with invalid amount: ${t.amount}');
            continue;
          }
          if (t.type.isEmpty) {
            _logger.warning('⚠️ Skipping transaction with empty type');
            continue;
          }
          if (!['income', 'expense', 'savings', 'transfer']
              .contains(t.type.toLowerCase())) {
            _logger.warning(
                '⚠️ Skipping transaction with invalid type: ${t.type}');
            continue;
          }

          batchData.add(
              _prepareTransactionForUpload(t, profileId, goalIdToRemoteIdMap));
          batchTransactionMap[batchIndex] = t;
          batchIndex++;
        }

        _logger.info(
            '📤 Prepared ${batchData.length} valid transactions for upload');
        if (batchData.isNotEmpty) {
          _logger.info('📤 Sample transaction data: ${batchData.first}');
        }

        // Process in sub-batches of _batchSize
        for (int i = 0; i < batchData.length; i += _batchSize) {
          final batch = batchData.skip(i).take(_batchSize).toList();
          final batchStartIndex = i;

          _logger.info(
              '📤 Uploading batch ${(i ~/ _batchSize) + 1}/'
              '${(batchData.length / _batchSize).ceil()}');

          final response = await _apiClient.syncTransactions(profileId, batch);
          _logger.info('📥 Sync response: $response');

          if (response['success'] == true) {
            final created = response['created'] as int? ?? 0;
            final updated = response['updated'] as int? ?? 0;
            result.uploaded += created + updated;
            _logger.info('✅ Batch uploaded: $created created, $updated updated');

            // ── CRITICAL: Write remoteIds back BEFORE Phase 2 reads the DB ──
            final createdIds = response['created_ids'] as List? ?? [];
            if (createdIds.isNotEmpty) {
              _logger.info(
                  '📌 Setting remoteIds for ${createdIds.length} transactions');
              for (int j = 0;
                  j < batch.length && j < createdIds.length;
                  j++) {
                final remoteId = createdIds[j]?.toString();
                if (remoteId == null || remoteId.isEmpty) continue;

                final originalTx = batchTransactionMap[batchStartIndex + j];
                if (originalTx == null) continue;

                try {
                  await _offlineDataService.updateTransaction(
                    originalTx.copyWith(remoteId: remoteId, isSynced: true),
                  );
                  _logger.info(
                      '✅ Set remoteId $remoteId for local tx ${originalTx.id}');
                } catch (e) {
                  _logger
                      .warning('Failed to set remoteId for transaction: $e');
                }
              }
              _logger.info('✅ All remoteIds committed to local DB');
            }

            if (response['errors'] != null &&
                (response['errors'] as List).isNotEmpty) {
              _logger.warning('⚠️ Sync errors: ${response['errors']}');
              for (final error in (response['errors'] as List)) {
                _logger.warning('  - $error');
              }
            }
          } else {
            _logger.severe(
                '❌ Batch sync failed: ${response['error'] ?? response['body']}');
          }
        }
      } else {
        _logger.info('No new transactions to upload');
      }

      // ── STEP 1b: UPDATED transactions (have remoteId, isSynced = false) ────
      final updatedTransactions = localTransactions
          .where((t) =>
              !t.isDeleted &&
              t.remoteId != null &&
              t.remoteId!.isNotEmpty &&
              !t.isSynced)
          .toList();

      if (updatedTransactions.isNotEmpty) {
        _logger.info(
            '📝 Uploading ${updatedTransactions.length} UPDATED transactions');

        final updateBatch = updatedTransactions
            .map((t) =>
                _prepareTransactionForUpload(t, profileId, goalIdToRemoteIdMap))
            .toList();

        final response =
            await _apiClient.updateTransactions(profileId, updateBatch);
        if (response['success'] == true) {
          result.uploaded += response['updated'] as int? ?? 0;
          _logger.info(
              '✅ Updated transactions synced: ${response['updated']} updated');

          // Mark as synced locally
          for (final t in updatedTransactions) {
            await _offlineDataService
                .updateTransaction(t.copyWith(isSynced: true));
          }
        } else {
          _logger.warning(
              '⚠️ Update sync failed: ${response['error'] ?? response['body']}');
        }
      } else {
        _logger.info('No updated transactions to upload');
      }

      // ── STEP 1c: DELETED transactions (remoteId exists, isDeleted = true) ──
      final deletedTransactions = localTransactions
          .where((t) =>
              t.isDeleted &&
              t.remoteId != null &&
              t.remoteId!.isNotEmpty)
          .toList();

      if (deletedTransactions.isNotEmpty) {
        _logger.info(
            '🗑️ Uploading ${deletedTransactions.length} DELETED transactions');

        final deleteIds = deletedTransactions
            .map((t) => t.remoteId!)
            .where((id) => id.isNotEmpty)
            .toList();

        if (deleteIds.isNotEmpty) {
          final response =
              await _apiClient.deleteTransactions(profileId, deleteIds);
          if (response['success'] == true) {
            result.uploaded += response['deleted'] as int? ?? 0;
            _logger.info(
                '✅ Deleted transactions synced: ${response['deleted']} soft-deleted');

            // Hard-delete from local DB now that server has acknowledged
            for (final t in deletedTransactions) {
              try {
                if (t.id != null && t.id!.isNotEmpty) {
                  await _offlineDataService.hardDeleteTransaction(t.id!);
                  _logger.info(
                      '✅ Removed soft-deleted transaction from local DB: ${t.id}');
                }
              } catch (e) {
                _logger.warning(
                    'Failed to remove deleted transaction locally: $e');
              }
            }
          } else {
            _logger.warning(
                '⚠️ Delete sync failed: ${response['error'] ?? response['body']}');
          }
        }
      } else {
        _logger.info('No deleted transactions to sync');
      }

      // ════════════════════════════════════════════════════════════════════════
      // PHASE 2 — DOWNLOAD
      //
      // The DB snapshot is taken HERE, after all Phase 1 writes have committed.
      // This guarantees the remoteId map includes every transaction that was
      // just uploaded, so the server's response can never be saved as a duplicate.
      // ════════════════════════════════════════════════════════════════════════
      final freshLocalTransactions =
          await _offlineDataService.getAllTransactions(profileId);

      // Build lookup maps on the fresh snapshot
      final remoteIdMap = <String, Transaction>{};
      for (final tx in freshLocalTransactions) {
        if (tx.remoteId != null && tx.remoteId!.isNotEmpty) {
          remoteIdMap[tx.remoteId!] = tx;
        }
      }

      final fingerprintMap = <String, Transaction>{};
      for (final tx in freshLocalTransactions) {
        fingerprintMap[_txFingerprint(tx.amount, tx.date, tx.type)] = tx;
      }

      _logger.info(
          '📥 Download snapshot: ${remoteIdMap.length} by remoteId, '
          '${fingerprintMap.length} by fingerprint');

      final remoteTransactions =
          await _apiClient.getTransactions(profileId: profileId);
      _logger.info(
          '📥 Downloaded ${remoteTransactions.length} transactions from server');

      int downloaded = 0;
      int skipped = 0;

      for (final txJson in remoteTransactions) {
        try {
          final remoteId = txJson['id']?.toString();

          // Check 1: remoteId already known locally → skip
          if (remoteId != null && remoteIdMap.containsKey(remoteId)) {
            skipped++;
            _logger.info('Skipping duplicate (remoteId): $remoteId');
            continue;
          }

          final transaction = _parseRemoteTransaction(txJson, profileId);
          if (transaction == null) continue;

          final fp = _txFingerprint(
              transaction.amount, transaction.date, transaction.type);

          // Check 2: same fingerprint locally → update remoteId if missing
          if (fingerprintMap.containsKey(fp)) {
            skipped++;
            _logger.info('Skipping duplicate (fingerprint): $fp');

            // Opportunistically patch missing remoteId
            final existingTx = fingerprintMap[fp]!;
            if ((existingTx.remoteId == null || existingTx.remoteId!.isEmpty) &&
                remoteId != null &&
                remoteId.isNotEmpty) {
              _logger.info(
                  'Patching remoteId on existing tx ${existingTx.id} → $remoteId');
              await _offlineDataService.updateTransaction(
                existingTx.copyWith(remoteId: remoteId, isSynced: true),
              );
            }
            continue;
          }

          // Genuinely new — safe to save
          await _offlineDataService.saveTransaction(transaction);
          downloaded++;
          _logger.info('Created new transaction from server: $remoteId');
        } catch (e) {
          _logger.warning('Failed to process remote transaction: $e');
        }
      }

      result.downloaded = downloaded;
      _logger.info(
          '✅ Download complete: $downloaded saved, $skipped skipped');

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('Transaction sync batch failed', e, stackTrace);
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
  Map<String, dynamic> _prepareTransactionForUpload(
    Transaction t,
    String profileId,
    [Map<String, String> goalIdToRemoteIdMap = const {}]  // ✅ Optional goal ID mapping
  ) {
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
      // ✅ FIX: Use goal's remoteId if available for backend attribution
      final goalRemoteId = goalIdToRemoteIdMap[t.goalId];
      if (goalRemoteId != null && goalRemoteId.isNotEmpty) {
        data['goal_id'] = goalRemoteId;  // Send remote ID (backend will update goal's current_amount)
      } else {
        data['goal_id'] = t.goalId;  // Fallback to local ID
      }
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

  /// ✅ FIXED: Batch sync goals with Explicit separation and Name-match safety net
  Future<EntitySyncResult> _syncGoalsBatch(String profileId) async {
    final result = EntitySyncResult();
    try {
      if (!_apiClient.isAuthenticated) return result;

      final localGoals = await _offlineDataService.getAllGoals(profileId);
      result.localCount = localGoals.length;

      // ✅ STEP 1: Upload Unsynced Goals
      final unsyncedGoals = localGoals.where((g) => !g.isSynced).toList();

      if (unsyncedGoals.isNotEmpty) {
        // Separate to ensure mapping logic only targets items expecting a new ID
        final newGoals = unsyncedGoals.where((g) => g.remoteId == null || g.remoteId!.isEmpty).toList();
        final updatedGoals = unsyncedGoals.where((g) => g.remoteId != null && g.remoteId!.isNotEmpty).toList();

        _logger.info('[GOALS] Syncing ${newGoals.length} new and ${updatedGoals.length} updated goals');

        // Payload: New goals first to match the 'created_ids' index mapping
        final goalsData = [
          ...newGoals.map((g) => _prepareGoalForUpload(g, profileId)),
          ...updatedGoals.map((g) => _prepareGoalForUpload(g, profileId)),
        ];

        try {
          final response = await _apiClient.batchSyncGoals(profileId, goalsData);

          if (response['success'] == true) {
            result.uploaded += (response['created'] as int? ?? 0) + (response['updated'] as int? ?? 0);

            // Map Remote IDs to NEW goals by index
            final createdIds = response['created_ids'] as List? ?? [];
            for (int i = 0; i < createdIds.length && i < newGoals.length; i++) {
              final remoteId = createdIds[i]?.toString();
              if (remoteId != null && remoteId.isNotEmpty) {
                await _offlineDataService.updateGoal(newGoals[i].copyWith(
                  remoteId: remoteId, 
                  isSynced: true,
                ));
              }
            }

            // Mark UPDATED goals as synced
            final updatedIds = response['updated_ids'] as List? ?? [];
            for (final id in updatedIds) {
              final remoteIdStr = id.toString();
              final goal = updatedGoals.firstWhere(
                (g) => g.remoteId == remoteIdStr,
                orElse: () => null as Goal,
              );
              if (goal != null) {
                await _offlineDataService.updateGoal(goal.copyWith(isSynced: true));
              }
            }
          }
        } catch (e) {
          _logger.warning('[GOALS] Upload sync failed: $e');
          result.error = 'Goal upload failed: $e';
        }
      }

      // ✅ STEP 2: Download Goals (with Name Fallback Safety)
      final refreshedLocalGoals = await _offlineDataService.getAllGoals(profileId);

      try {
        final remoteGoals = await _apiClient.getGoals(profileId: profileId);

        for (final remote in remoteGoals) {
          final remoteId = remote['id']?.toString();
          final remoteName = remote['name']?.toString();
          if (remoteId == null) continue;

          // ✅ SAFETY NET: Match by remoteId OR (Name + Profile) to prevent duplicates
          final existingLocalGoal = refreshedLocalGoals.firstWhere(
            (g) => g.remoteId == remoteId || 
                  (g.name == remoteName && g.profileId == profileId),
            orElse: () => null as Goal,
          );

          final parsedGoal = _parseRemoteGoal(remote, profileId);
          if (parsedGoal == null) continue;

          if (existingLocalGoal != null) {
            // UPDATE: Found via ID or Name match
            final mergedGoal = parsedGoal.copyWith(
              id: existingLocalGoal.id, // Preserve local primary key
              remoteId: remoteId,       // Ensure remoteId is now set if matched by name
              isSynced: true,
            );
            await _offlineDataService.updateGoal(mergedGoal);
            _logger.info('[GOALS] Synced remote goal $remoteId to local goal ${existingLocalGoal.id}');
          } else {
            // CREATE: Genuinely new
            await _offlineDataService.saveGoal(parsedGoal);
            result.downloaded++;
            _logger.info('[GOALS] Created new goal from server: $remoteId');
          }
        }
      } catch (e) {
        _logger.warning('[GOALS] Download sync failed: $e');
        result.error = 'Goal download failed: $e';
      }

      result.success = true;
    } catch (e, stackTrace) {
      _logger.severe('[GOALS] Goal sync batch failed', e, stackTrace);
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
    final data = <String, dynamic>{
      'profile_id': profileId,
      'name': g.name,
      'target_amount': g.targetAmount,
      'current_amount': g.currentAmount,
      'goal_type': g.goalType.name,
      'status': g.status.name,
      'description': g.description,
      'due_date': g.targetDate.toIso8601String(),
      'currency': g.currency ?? 'KES',
    };

    // ✅ CRITICAL FIX: Send remoteId so backend updates, not creates
    if (g.remoteId != null && g.remoteId!.isNotEmpty) {
      data['id'] = g.remoteId;  // Backend: Goal.objects.get(id=remoteId) → UPDATE
    }
    return data;
  }


  /// ✅ Batch sync budgets with UPDATE support
  Future<EntitySyncResult> _syncBudgetsBatch(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final localBudgets = await _offlineDataService.getAllBudgets(profileId);
      result.localCount = localBudgets.length;

      if (_apiClient.isAuthenticated) {
        // STEP 1a: Upload NEW budgets
        final unsyncedBudgets = localBudgets
            .where((b) => b.remoteId == null || b.remoteId!.isEmpty)
            .toList();
        
        if (unsyncedBudgets.isNotEmpty) {
          _logger.info('📤 Uploading ${unsyncedBudgets.length} NEW budgets');
          
          final budgetsData = unsyncedBudgets.map((b) => _prepareBudgetForUpload(b, profileId)).toList();
          final response = await _apiClient.batchSyncBudgets(profileId, unsyncedBudgets);
          
          if (response['success'] == true) {
            result.uploaded += response['created'] as int? ?? 0;
            
            // ✅ Set remoteId on created budgets
            final createdIds = response['created_ids'] as List? ?? [];
            for (int i = 0; i < createdIds.length && i < unsyncedBudgets.length; i++) {
              final remoteId = createdIds[i]?.toString();
              if (remoteId != null && remoteId.isNotEmpty) {
                final updatedBudget = unsyncedBudgets[i].copyWith(
                  remoteId: remoteId,
                  isSynced: true,
                );
                await _offlineDataService.updateBudget(updatedBudget);
              }
            }
          }
        }

        // STEP 1b: Upload UPDATED budgets
        final updatedBudgets = localBudgets
            .where((b) => b.remoteId != null && b.remoteId!.isNotEmpty && !b.isSynced)
            .toList();
        
        if (updatedBudgets.isNotEmpty) {
          _logger.info('📝 Uploading ${updatedBudgets.length} UPDATED budgets');
          
          final updateBatch = updatedBudgets.map((b) => _prepareBudgetForUpload(b, profileId)).toList();
          final response = await _apiClient.updateBudgets(profileId, updateBatch);
          
          if (response['success'] == true) {
            result.uploaded += response['updated'] as int? ?? 0;
            
            // Mark as synced
            for (final b in updatedBudgets) {
              await _offlineDataService.updateBudget(b.copyWith(isSynced: true));
            }
          }
        }

        // STEP 1c: Upload DELETED budgets
        final deletedBudgets = localBudgets
            .where((b) => b.isDeleted && (b.remoteId != null && b.remoteId!.isNotEmpty))
            .toList();
        
        if (deletedBudgets.isNotEmpty) {
          _logger.info('🗑️ Uploading ${deletedBudgets.length} DELETED budgets');
          
          final deleteIds = deletedBudgets.map((b) => b.remoteId!).toList();
          final response = await _apiClient.batchDeleteBudgets(profileId, deleteIds);
          
          if (response['success'] == true) {
            result.uploaded += response['deleted'] as int? ?? 0;
            
            // Remove from local database
            for (final b in deletedBudgets) {
              if (b.id != null) {
                await _offlineDataService.deleteBudget(b.id!);
              }
            }
          }
        }
        
        // STEP 2: Download from server
        final remoteBudgets = await _apiClient.getBudgets(profileId: profileId);
        
        // STEP 3: Merge
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
  
  /// ✅ NEW: Sync only deleted transactions immediately
  /// Called when user deletes a transaction to ensure it's removed from backend quickly
  Future<void> syncDeletedTransactions() async {
    if (_currentProfileId == null) {
      _logger.warning('No profile selected for deleted transaction sync');
      return;
    }
    
    try {
      final profileId = _currentProfileId!;
      final localTransactions = await _offlineDataService.getAllTransactions(profileId);
      
      // Find transactions marked as deleted with a remoteId
      final deletedTransactions = localTransactions
          .where((t) => t.isDeleted && (t.remoteId != null && t.remoteId!.isNotEmpty))
          .toList();
      
      if (deletedTransactions.isEmpty) {
        _logger.info('No deleted transactions to sync');
        return;
      }
      
      _logger.info('🗑️ Syncing ${deletedTransactions.length} deleted transactions to backend');
      
      // Collect remoteIds to delete
      final deleteIds = deletedTransactions
          .map((t) => t.remoteId!)
          .where((id) => id.isNotEmpty)
          .toList();
      
      if (deleteIds.isNotEmpty) {
        final response = await _apiClient.deleteTransactions(profileId, deleteIds);
        
        if (response['success'] == true) {
          _logger.info('✅ Deleted transactions synced: ${response['deleted']} soft-deleted on backend');
          
          // Remove from local database after successful sync
          for (final t in deletedTransactions) {
            try {
              await _offlineDataService.hardDeleteTransaction(t.id!);
              _logger.info('✅ Removed local deleted transaction: ${t.id}');
            } catch (e) {
              _logger.warning('Failed to remove local deleted transaction: $e');
            }
          }
        } else {
          _logger.severe('Failed to sync deleted transactions: ${response['error'] ?? response['body']}');
        }
      }
    } catch (e) {
      _logger.severe('Error syncing deleted transactions: $e');
    }
  }

  /// ✅ NEW: Sync deleted loans to backend
  Future<void> syncDeletedLoans() async {
    if (_currentProfileId == null) {
      _logger.warning('No profile selected for deleted loans sync');
      return;
    }
    
    try {
      final profileId = _currentProfileId!;
      final localLoans = await _offlineDataService.getAllLoans(profileId);
      
      // Find loans marked as deleted with a remoteId
      final deletedLoans = localLoans
          .where((l) => l.isDeleted && (l.remoteId != null && l.remoteId!.isNotEmpty))
          .toList();
      
      if (deletedLoans.isEmpty) {
        _logger.info('No deleted loans to sync');
        return;
      }
      
      _logger.info('🗑️ Syncing ${deletedLoans.length} deleted loans to backend');
      
      // Collect remoteIds to delete
      final deleteIds = deletedLoans
          .map((l) => l.remoteId!)
          .where((id) => id.isNotEmpty)
          .toList();
      
      if (deleteIds.isNotEmpty) {
        final response = await _apiClient.deleteLoans(profileId, deleteIds);
        
        if (response['success'] == true) {
          _logger.info('✅ Deleted loans synced: ${response['deleted']} soft-deleted on backend');
          
          // Remove from local database after successful sync
          for (final l in deletedLoans) {
            try {
              await _offlineDataService.hardDeleteLoan(l.id!);
              _logger.info('✅ Removed local deleted loan: ${l.id}');
            } catch (e) {
              _logger.warning('Failed to remove local deleted loan: $e');
            }
          }
        } else {
          _logger.severe('Failed to sync deleted loans: ${response['error'] ?? response['body']}');
        }
      }
    } catch (e) {
      _logger.severe('Error syncing deleted loans: $e');
    }
  }
  
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
      
      // ✅ CRITICAL FIX: Load local transactions ONCE before processing
      final localTransactions = await _offlineDataService.getAllTransactions(profileId);
      
      // ✅ Create lookup maps for fast duplicate detection
      // Map 1: By remoteId (most reliable)
      final remoteIdMap = <String, Transaction>{};
      for (final tx in localTransactions) {
        if (tx.remoteId != null && tx.remoteId!.isNotEmpty) {
          remoteIdMap[tx.remoteId!] = tx;
        }
      }
      
      // Map 2: By local ID (for transactions created locally)
      final localIdMap = <String, Transaction>{};
      for (final tx in localTransactions) {
        if (tx.id != null && tx.id!.isNotEmpty) {
          localIdMap[tx.id!] = tx;
        }
      }
      
      // Map 3: By fingerprint (amount + date + type) for extra safety
      final fingerprintMap = <String, Transaction>{};
      for (final tx in localTransactions) {
        final fingerprint = '${tx.amount}_${tx.date.toIso8601String()}_${tx.type}';
        fingerprintMap[fingerprint] = tx;
      }
      
      _logger.info('Local transaction maps created: ${remoteIdMap.length} by remoteId, ${localIdMap.length} by localId, ${fingerprintMap.length} by fingerprint');
      
      // Convert and save each transaction
      int skipped = 0;
      for (final txJson in transactionsJson) {
        try {
          final remoteId = txJson['id']?.toString();
          
          // ✅ FIX 1: Check remoteId map first (most reliable)
          if (remoteId != null && remoteIdMap.containsKey(remoteId)) {
            skipped++;
            _logger.info('Skipping duplicate (remoteId): $remoteId');
            continue;
          }
          
          // ✅ FIX 2: Check local ID map
          if (remoteId != null && localIdMap.containsKey(remoteId)) {
            skipped++;
            _logger.info('Skipping duplicate (localId): $remoteId');
            continue;
          }
          
          // ✅ FIX 3: Parse transaction and check fingerprint
          final transaction = _parseRemoteTransaction(txJson, profileId);
          if (transaction != null) {
            final fingerprint = '${transaction.amount}_${transaction.date.toIso8601String()}_${transaction.type}';
            
            if (fingerprintMap.containsKey(fingerprint)) {
              skipped++;
              _logger.info('Skipping duplicate (fingerprint): $fingerprint');
              
              // ✅ BONUS: Update local transaction with remoteId if missing
              final existingTx = fingerprintMap[fingerprint]!;
              if ((existingTx.remoteId == null || existingTx.remoteId!.isEmpty) && 
                  remoteId != null && remoteId.isNotEmpty) {
                _logger.info('Updating local transaction with remoteId: ${existingTx.id} -> $remoteId');
                await _offlineDataService.updateTransaction(
                  existingTx.copyWith(remoteId: remoteId, isSynced: true)
                );
              }
              continue;
            }
            
            // ✅ Safe to create - no duplicates found
            await _offlineDataService.saveTransaction(transaction);
            result.downloaded++;
            _logger.info('Created new transaction from server: $remoteId');
          }
        } catch (e) {
          _logger.warning('Failed to parse transaction: $e');
        }
      }
      
      result.success = true;
      _logger.info('✅ Saved ${result.downloaded} new transactions, skipped $skipped duplicates');
      
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

  // Sync only the entity that was just created/updated/deleted to minimize delay 
  // and provide instant feedback to user
  Future<void> syncAfterCrud(String profileId, String entityType) async {
    // 1. Guard clauses
    if (!_apiClient.isAuthenticated) return;
    if (_isSyncing) {
      _logger.info('Sync already in progress, skipping CRUD sync');
      return;
    }

    try {
      _isSyncing = true; // 2. Lock the process
      _logger.info('⚡ Post-CRUD sync: $entityType');

      switch (entityType) {
        case 'transaction': await _syncTransactionsBatch(profileId); break;
        case 'goal':        await _syncGoalsBatch(profileId); break;
        case 'budget':      await _syncBudgetsBatch(profileId); break;
        case 'loan':        await _syncLoansBatch(profileId); break;
      }
      
      notifyListeners();
    } catch (e) {
      _logger.severe('Sync failed for $entityType: $e');
    } finally {
      _isSyncing = false; // 3. Always unlock
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER: Normalised transaction fingerprint
  //
  // Normalises amount, date (UTC day precision), and type into a stable string
  // that is immune to:
  //   • timezone suffixes  (Z vs +00:00 vs no suffix)
  //   • sub-second precision differences
  //   • floating-point representation differences (400 vs 400.0 vs 400.00)
  // ---------------------------------------------------------------------------
  String _txFingerprint(double amount, DateTime date, String type) {
    final d = date.toUtc();
    // Zero-pad month/day so '2026-2-5' never collides with '2026-12-5'
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${amount.toStringAsFixed(2)}_${dateStr}_${type.toLowerCase()}';
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
