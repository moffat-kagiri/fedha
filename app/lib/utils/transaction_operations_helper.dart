// lib/utils/transaction_operations_helper.dart
import '../models/transaction.dart';
import '../services/offline_data_service.dart';
import '../utils/logger.dart';

/// Helper class to perform transaction operations
/// ✅ FIXED: Removed duplicate event emissions - OfflineDataService handles all events
class TransactionOperations {
  static final _logger = AppLogger.getLogger('TransactionOperations');

  /// Create a new transaction
  /// ✅ Events are emitted by OfflineDataService.saveTransaction()
  static Future<bool> createTransaction({
    required Transaction transaction,
    required OfflineDataService offlineService,
  }) async {
    try {
      // Save transaction - this will emit the created event automatically
      await offlineService.saveTransaction(transaction);
      _logger.info('✅ Transaction created: ${transaction.id}');
      
      // ❌ REMOVED: Duplicate event emission
      // await TransactionEventService();.onTransactionCreated(transaction);
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to create transaction', e, stackTrace);
      return false;
    }
  }

  /// Update an existing transaction
  /// ✅ NEW BEHAVIOR (v2):
  /// 1. Delete old transaction from local storage (hard delete)
  /// 2. Mark old transaction as deleted in sync queue (soft delete for PostgreSQL)
  /// 3. Create new transaction with updated values and new ID
  /// This prevents duplicates and ensures proper sync behavior
  static Future<bool> updateTransaction({
    required Transaction transaction,
    required OfflineDataService offlineService,
    required Transaction oldTransaction,
  }) async {
    try {
      // Step 1: Mark old transaction as deleted locally
      if (oldTransaction.remoteId != null && oldTransaction.remoteId!.isNotEmpty) {
        // Old transaction has been synced to backend - mark it for deletion in next sync
        await offlineService.deleteTransaction(oldTransaction.id!);
        _logger.info('🗑️ Deleted old transaction locally: ${oldTransaction.id}');
      } else {
        // Old transaction never reached backend - just hard delete it
        await offlineService.hardDeleteTransaction(oldTransaction.id!);
        _logger.info('💥 Hard deleted local-only transaction: ${oldTransaction.id}');
      }
      
      // Step 2: Save the updated transaction as a new record
      await offlineService.saveTransaction(transaction);
      _logger.info('✅ Transaction updated (new record): ${transaction.id}');
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to update transaction', e, stackTrace);
      return false;
    }
  }

  /// Delete a transaction
  /// ✅ Events are emitted by OfflineDataService.deleteTransaction()
  static Future<bool> deleteTransaction({
    required Transaction transaction,
    required OfflineDataService offlineService,
  }) async {
    try {
      // Delete transaction - this will emit the deleted event automatically
      await offlineService.deleteTransaction(transaction.id!);
      _logger.info('✅ Transaction deleted: ${transaction.id}');
      
      // ❌ REMOVED: Duplicate event emission
      // await TransactionEventService();.onTransactionDeleted(transaction);
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete transaction', e, stackTrace);
      return false;
    }
  }

  /// Approve a pending transaction (convert to confirmed)
  /// ✅ Events are emitted by OfflineDataService.approvePendingTransaction()
  static Future<bool> approvePendingTransaction({
    required Transaction pendingTransaction,
    required OfflineDataService offlineService,
  }) async {
    try {
      // Create confirmed transaction from pending
      final confirmedTransaction = pendingTransaction.copyWith(
        isPending: false,
      );
      
      // Approve in database - this will emit the approved event automatically
      await offlineService.approvePendingTransaction(confirmedTransaction);
      _logger.info('✅ Pending transaction approved: ${confirmedTransaction.id}');
      
      // ❌ REMOVED: Duplicate event emission
      // await TransactionEventService();.onTransactionApproved(confirmedTransaction);
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to approve pending transaction', e, stackTrace);
      return false;
    }
  }

  /// Batch approve multiple pending transactions
  static Future<int> batchApprovePendingTransactions({
    required List<Transaction> pendingTransactions,
    required OfflineDataService offlineService,
  }) async {
    int successCount = 0;
    
    for (final pending in pendingTransactions) {
      final success = await approvePendingTransaction(
        pendingTransaction: pending,
        offlineService: offlineService,
      );
      
      if (success) {
        successCount++;
      }
    }
    
    _logger.info('Batch approved $successCount/${pendingTransactions.length} transactions');
    return successCount;
  }
}