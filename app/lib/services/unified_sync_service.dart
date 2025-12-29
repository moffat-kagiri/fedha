// lib/services/unified_sync_service.dart
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/enums.dart';
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
  
  OfflineDataService? _offlineDataService;
  ApiClient? _apiClient;
  AuthService? _authService;
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _currentProfileId;

  UnifiedSyncService._();

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize with dependencies
  Future<void> initialize({
    required OfflineDataService offlineDataService,
    required ApiClient apiClient,
    required AuthService authService,
  }) async {
    _offlineDataService = offlineDataService;
    _apiClient = apiClient;
    _authService = authService;
    _logger.info('UnifiedSyncService initialized');
  }

  /// Set current profile for sync operations
  void setCurrentProfile(String profileId) {
    _currentProfileId = profileId;
    _logger.info('Current profile set for sync: $profileId');
  }

  /// Sync all data for current profile
  Future<SyncResult> syncAll() async {
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
    if (_offlineDataService == null || _apiClient == null || _authService == null) {
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
      final isOnline = await _apiClient!.checkServerHealth();
      result.serverAvailable = isOnline;

      // Sync each data type
      result.transactions = await _syncTransactions(profileId, isOnline);
      result.goals = await _syncGoals(profileId, isOnline);
      result.budgets = await _syncBudgets(profileId, isOnline);
      result.loans = await _syncLoans(profileId, isOnline);
      result.pendingTransactions = await _syncPendingTransactions(profileId);

      result.success = true;
      _lastSyncTime = DateTime.now();
      
      _logger.info('Sync completed successfully');
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

  /// Sync transactions
  Future<EntitySyncResult> _syncTransactions(String profileId, bool isOnline) async {
    final result = EntitySyncResult();
    
    try {
      // Always ensure local data is accessible
      final localTransactions = await _offlineDataService!.getAllTransactions(profileId);
      result.localCount = localTransactions.length;

      if (isOnline && _apiClient!.isAuthenticated) {
        try {
          // Upload unsynced transactions
          final unsynced = localTransactions.where((t) => t.remoteId == null).toList();
          if (unsynced.isNotEmpty) {
            _logger.info('Uploading ${unsynced.length} transactions to server');
            
            for (final transaction in unsynced) {
              try {
                final payload = {
                  'amount_minor': (transaction.amount * 100).round(),
                  'currency': 'KES',
                  'description': transaction.description ?? '',
                  'category_id': transaction.categoryId,
                  'date': transaction.date.toIso8601String(),
                  'is_expense': transaction.isExpense,
                  'transaction_type': transaction.type.name,
                  'profile_id': profileId,
                  'goal_id': transaction.goalId,
                };
                
                final response = await _apiClient!.createTransaction(payload);
                final remoteId = response['id']?.toString();
                
                // TODO: Store remoteId mapping locally
                _logger.info('Transaction uploaded with remote ID: $remoteId');
                result.uploaded++;
              } catch (e) {
                _logger.warning('Failed to upload transaction: $e');
              }
            }
          }

          // Download new transactions from server
          final remoteTransactions = await _apiClient!.getTransactions(profileId: profileId);
          _logger.info('Downloaded ${remoteTransactions.length} transactions from server');
          result.downloaded = remoteTransactions.length;
          
          // TODO: Merge remote transactions into local storage
          
        } catch (e) {
          _logger.warning('Transaction server sync failed: $e');
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

  /// Sync goals with currentAmount field ⭐ UPDATED
  Future<EntitySyncResult> _syncGoals(String profileId, bool isOnline) async {
    final result = EntitySyncResult();
    
    try {
      final localGoals = await _offlineDataService!.getAllGoals(profileId);
      result.localCount = localGoals.length;
      _logger.info('Found ${localGoals.length} local goals');

      if (isOnline && _apiClient!.isAuthenticated) {
        try {
          // Download goals from server
          final remoteGoals = await _apiClient!.getGoals(profileId: profileId);
          _logger.info('Downloaded ${remoteGoals.length} goals from server');
          
          // Merge server goals into local
          for (final remote in remoteGoals) {
            try {
              final remoteId = remote['id']?.toString();
              final name = remote['name']?.toString() ?? '';
              final targetAmount = double.tryParse(remote['target_amount']?.toString() ?? '0') ?? 0.0;
              final currentAmount = double.tryParse(remote['current_amount']?.toString() ?? '0') ?? 0.0; // ⭐ NEW FIELD
              final dueDate = DateTime.tryParse(remote['due_date']?.toString() ?? '') ?? DateTime.now();
              final isCompleted = remote['is_completed'] == true;
              
              // Check if goal exists locally
              final existingGoal = localGoals.firstWhere(
                (g) => g.remoteId == remoteId,
                orElse: () => Goal.empty(),
              );
              
              if (existingGoal.id!.isEmpty) {
                // Create new goal locally
                final goal = Goal(
                  name: name,
                  targetAmount: targetAmount,
                  currentAmount: currentAmount, // ⭐ INCLUDED
                  targetDate: dueDate,
                  profileId: profileId,
                  goalType: GoalType.other,
                  status: isCompleted ? GoalStatus.completed : GoalStatus.active,
                  remoteId: remoteId,
                );
                
                await _offlineDataService!.saveGoal(goal);
                result.downloaded++;
              } else {
                // Update existing goal if server has newer data
                // TODO: Implement conflict resolution based on timestamps
              }
            } catch (e) {
              _logger.warning('Failed to process remote goal: $e');
            }
          }

          // Upload local goals to server
          for (final localGoal in localGoals) {
            if (localGoal.remoteId == null || localGoal.remoteId!.isEmpty) {
              try {
                final payload = {
                  'name': localGoal.name,
                  'target_amount': localGoal.targetAmount,
                  'current_amount': localGoal.currentAmount, // ⭐ INCLUDED
                  'due_date': localGoal.targetDate.toIso8601String(),
                  'is_completed': localGoal.status == GoalStatus.completed,
                  'profile_id': profileId,
                };
                
                final response = await _apiClient!.createGoal(payload);
                final remoteId = response['id']?.toString();
                
                // Store remoteId in local goal
                // TODO: Update local goal with remoteId
                _logger.info('Goal uploaded with remote ID: $remoteId');
                result.uploaded++;
              } catch (e) {
                _logger.warning('Failed to upload goal: $e');
              }
            }
          }
          
        } catch (e) {
          _logger.warning('Goal server sync failed: $e');
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

  /// Sync budgets
  Future<EntitySyncResult> _syncBudgets(String profileId, bool isOnline) async {
    final result = EntitySyncResult();
    
    try {
      final localBudgets = await _offlineDataService!.getAllBudgets(profileId);
      result.localCount = localBudgets.length;

      if (isOnline) {
        try {
          // TODO: Implement budget server sync
          _logger.info('${localBudgets.length} budgets in local storage');
        } catch (e) {
          _logger.warning('Budget server sync failed: $e');
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

  /// Sync loans
  Future<EntitySyncResult> _syncLoans(String profileId, bool isOnline) async {
    final result = EntitySyncResult();
    
    try {
      final localLoans = await _offlineDataService!.getAllLoans(profileId);
      result.localCount = localLoans.length;

      if (isOnline && _apiClient!.isAuthenticated) {
        try {
          _logger.info('${localLoans.length} loans in local storage');
          
          // Get the current auth token from AuthService
          final currentProfile = _authService!.currentProfile;
          final sessionToken = currentProfile?.sessionToken;
          
          // Pass the session token to getLoans
          final remoteLoans = await _apiClient!.getLoans(
            profileId: profileId,
            sessionToken: sessionToken,
          );

          // Map remote loans into local storage when not already present
          for (final r in remoteLoans) {
            try {
              final name = r['name']?.toString() ?? '';
              final principalMinor = (r['principal_minor'] is int)
                  ? (r['principal_minor'] as int).toDouble()
                  : (r['principal_minor'] is double)
                      ? r['principal_minor'] as double
                      : double.tryParse(r['principal_minor']?.toString() ?? '0') ?? 0.0;
              final interestRate = double.tryParse(r['interest_rate']?.toString() ?? '0') ?? 0.0;
              final startDate = DateTime.tryParse(r['start_date']?.toString() ?? '') ?? DateTime.now();
              final endDate = DateTime.tryParse(r['end_date']?.toString() ?? '') ?? DateTime.now();
              final profileIdRemote = r['profile_id']?.toString() ?? profileId;
              final remoteId = r['id']?.toString();

              // Simple duplicate detection: match by remote ID or name+start_date
              final exists = localLoans.any((l) => 
                (l.remoteId == remoteId && remoteId != null) ||
                (l.name == name && l.startDate == startDate)
              );
              
              if (!exists) {
                final domainLoan = Loan(
                  name: name,
                  principalMinor: principalMinor,
                  currency: r['currency']?.toString() ?? 'KES',
                  interestRate: interestRate,
                  startDate: startDate,
                  endDate: endDate,
                  profileId: profileIdRemote,
                  remoteId: remoteId,
                );

                final localId = await _offlineDataService!.saveLoan(domainLoan);
                result.downloaded++;
              }
            } catch (e) {
              _logger.warning('Failed to merge remote loan: $e');
            }
          }
          
          // Upload local-only loans to server
          for (final local in localLoans) {
            try {
              if (local.id == null) continue;
              
              if (local.remoteId == null || local.remoteId!.isEmpty) {
                final payload = {
                  'name': local.name,
                  'principal_minor': local.principalMinor,
                  'currency': local.currency,
                  'interest_rate': local.interestRate,
                  'start_date': local.startDate.toIso8601String(),
                  'end_date': local.endDate.toIso8601String(),
                  'profile_id': local.profileId,
                };

                final created = await _apiClient!.createLoan(loan: payload);
                final createdId = created['id']?.toString();
                if (createdId != null) {
                  // Update local loan with remote ID
                  final updatedLoan = local.copyWith(remoteId: createdId);
                  await _offlineDataService!.updateLoan(updatedLoan);
                  result.uploaded++;
                }
              }
            } catch (e) {
              _logger.warning('Failed to push local loan to server: $e');
            }
          }
        } catch (e) {
          _logger.warning('Loan server sync failed: $e');
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

  /// Sync pending transactions (SMS candidates)
  Future<EntitySyncResult> _syncPendingTransactions(String profileId) async {
    final result = EntitySyncResult();
    
    try {
      final pending = await _offlineDataService!.getPendingTransactions(profileId);
      result.localCount = pending.length;
      result.success = true;
      
      _logger.info('${pending.length} pending transactions in local storage');
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
    return await syncProfile(profileId);
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
}
