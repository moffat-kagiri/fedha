// lib/services/unified_sync_service.dart
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../utils/logger.dart';
import 'offline_data_service.dart';
import 'api_client.dart';

/// Unified sync service for all data types
/// Handles both local persistence and server synchronization
class UnifiedSyncService with ChangeNotifier {
  static UnifiedSyncService? _instance;
  static UnifiedSyncService get instance => _instance ??= UnifiedSyncService._();

  final _logger = AppLogger.getLogger('UnifiedSyncService');
  
  OfflineDataService? _offlineDataService;
  ApiClient? _apiClient;
  
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
  }) async {
    _offlineDataService = offlineDataService;
    _apiClient = apiClient;
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
    if (_offlineDataService == null || _apiClient == null) {
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

      if (isOnline) {
        // Try to sync with server
        try {
          // Upload unsynced transactions
          final unsynced = localTransactions.where((t) => !t.isSynced).toList();
          if (unsynced.isNotEmpty) {
            // TODO: Implement server sync when API is ready
            _logger.info('${unsynced.length} transactions pending server sync');
            result.uploaded = unsynced.length;
          }

          // Download new transactions from server
          // TODO: Implement when API is ready
          result.downloaded = 0;
        } catch (e) {
          _logger.warning('Server sync failed, local data preserved: $e');
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

  /// Sync goals
  Future<EntitySyncResult> _syncGoals(String profileId, bool isOnline) async {
    final result = EntitySyncResult();
    
    try {
      final localGoals = await _offlineDataService!.getAllGoals(profileId);
      result.localCount = localGoals.length;

      if (isOnline) {
        try {
          final unsynced = localGoals.where((g) => !g.isSynced).toList();
          if (unsynced.isNotEmpty) {
            _logger.info('${unsynced.length} goals pending server sync');
            result.uploaded = unsynced.length;
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
          final unsynced = localBudgets.where((b) => !b.isSynced).toList();
          if (unsynced.isNotEmpty) {
            _logger.info('${unsynced.length} budgets pending server sync');
            result.uploaded = unsynced.length;
          }
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

      if (isOnline) {
        try {
          _logger.info('${localLoans.length} loans in local storage');
          // Download remote loans and merge into local DB (simple merge by name+start_date)
          final remoteLoans = await _apiClient!.getLoans(profileId: profileId);
          result.downloaded = remoteLoans.length;

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

              // Simple duplicate detection: match by name and start_date
              final exists = localLoans.any((l) => l.name == name && (l.startDate?.toIso8601String() ?? '') == startDate.toIso8601String());
              if (!exists) {
                final domainLoan = Loan(
                  name: name,
                  principalMinor: principalMinor,
                  currency: r['currency']?.toString() ?? 'KES',
                  interestRate: interestRate,
                  startDate: startDate,
                  endDate: endDate,
                  profileId: profileIdRemote,
                );

                final localId = await _offlineDataService!.saveLoan(domainLoan);
                // store mapping from local -> remote id when available
                final remoteId = r['id']?.toString();
                if (remoteId != null && remoteId.isNotEmpty) {
                  await _offlineDataService!.setRemoteLoanId(localId, remoteId);
                }
                result.uploaded += 1; // count as local inserted
              }
            } catch (e) {
              _logger.warning('Failed to merge remote loan: $e');
            }
          }
          
          // Upload local-only loans to server
          for (final local in localLoans) {
            try {
              if (local.id == null) continue;
              final remoteId = await _offlineDataService!.getRemoteLoanId(local.id!);
              final payload = {
                'name': local.name,
                'principal_minor': local.principalMinor, // Changed from (local.principal * 100).round()
                'currency': local.currency, // Changed from hardcoded 'KES'
                'interest_rate': local.interestRate,
                'start_date': local.startDate.toIso8601String(), // Removed null check
                'end_date': local.endDate.toIso8601String(), // Removed null check
                'profile_id': local.profileId, // Changed from profileId parameter
              };

              if (remoteId == null) {
                final created = await _apiClient!.createLoan(loan: payload);
                final createdId = created['id']?.toString();
                if (createdId != null) {
                  await _offlineDataService!.setRemoteLoanId(local.id!, createdId);
                  result.uploaded += 1;
                }
              } else {
                // Attempt to update server representation
                final idInt = int.tryParse(remoteId);
                if (idInt != null) {
                  await _apiClient!.updateLoan(loanId: idInt, loan: payload);
                  result.uploaded += 1;
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

  /// Force sync all data (ignores sync status)
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