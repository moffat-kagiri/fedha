import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../models/profile.dart';
import '../models/transaction.dart';
import '../utils/logger.dart';

/// Enum defining sync level for transactions
enum TransactionSyncLevel {
  /// Basic sync with minimal data
  basic,
  
  /// Full sync with all data
  full,
  
  /// Sync with dependencies (e.g., related entities)
  withDependencies
}

/// A class for managing synchronization between local and remote data
class SyncManager {
  final AuthService _authService;
  final ApiClient _apiClient;
  final logger = AppLogger.getLogger('SyncManager');
  
  /// Whether a sync operation is currently in progress
  bool _isSyncing = false;
  
  /// Get the current syncing state
  bool get isSyncing => _isSyncing;
  
  /// Constructor
  SyncManager({
    required AuthService authService,
    required ApiClient apiClient,
  }) : _authService = authService,
       _apiClient = apiClient;
  
  /// Sync all unsynchronized transactions
  Future<bool> syncTransactions({
    required List<Transaction> unsynced,
    TransactionSyncLevel syncLevel = TransactionSyncLevel.full,
  }) async {
    if (_isSyncing) {
      logger.info('Sync already in progress, skipping');
      return false;
    }
    
    try {
      _isSyncing = true;
      
      final profile = _authService.profile;
      if (profile == null) {
        logger.warning('No profile available for sync');
        return false;
      }
      
      // Skip if there are no transactions to sync
      if (unsynced.isEmpty) {
        logger.info('No transactions to sync');
        return true;
      }
      
      logger.info('Syncing ${unsynced.length} transactions');
      
      final result = await _apiClient.syncOfflineTransactions(
        userId: profile.id,
        sessionToken: profile.authToken ?? '',
        transactions: unsynced,
      );
      
      final success = result['success'] == true;
      if (success) {
        logger.info('Successfully synced ${unsynced.length} transactions');
      } else {
        logger.warning('Failed to sync transactions: ${result['message']}');
      }
      
      return success;
    } catch (e) {
      logger.severe('Error during transaction sync', e);
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync goals with server
  Future<bool> syncGoals() async {
    if (_isSyncing) {
      logger.info('Sync already in progress, skipping');
      return false;
    }
    
    try {
      _isSyncing = true;
      
      final profile = _authService.profile;
      if (profile == null) {
        logger.warning('No profile available for sync');
        return false;
      }
      
      // Fetch goals from server
      final goals = await _apiClient.fetchUserGoals(
        userId: profile.id,
        sessionToken: profile.authToken ?? '',
      );
      
      // Here you would merge with local goals
      // This is a stub - actual implementation would depend on how goals are stored locally
      
      logger.info('Successfully synced ${goals.length} goals');
      return true;
    } catch (e) {
      logger.severe('Error during goal sync', e);
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync budget with server
  Future<bool> syncBudgets() async {
    if (_isSyncing) {
      logger.info('Sync already in progress, skipping');
      return false;
    }
    
    try {
      _isSyncing = true;
      
      final profile = _authService.profile;
      if (profile == null) {
        logger.warning('No profile available for sync');
        return false;
      }
      
      // Get current month and year
      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final year = now.year.toString();
      
      // Fetch budget summary from server
      await _apiClient.fetchBudgetSummary(
        userId: profile.id,
        sessionToken: profile.authToken ?? '',
      );
      
      // Here you would merge with local budgets
      // This is a stub - actual implementation would depend on how budgets are stored locally
      
      logger.info('Successfully synced budget summary for $month/$year');
      return true;
    } catch (e) {
      logger.severe('Error during budget sync', e);
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}
