// lib/utils/transaction_operations_helper.dart
import '../models/transaction.dart';
import '../services/offline_data_service.dart';
import '../services/transaction_event_service.dart';
import '../utils/logger.dart';

/// Helper class to perform transaction operations with automatic event emission
class TransactionOperations {
  static final _logger = AppLogger.getLogger('TransactionOperations');

  /// Create a new transaction and emit created event
  static Future<bool> createTransaction({
    required Transaction transaction,
    required OfflineDataService offlineService,
  }) async {
    try {
      // Save transaction to database
      await offlineService.saveTransaction(transaction);
      _logger.info('Transaction saved: ${transaction.id}');
      
      // Emit created event to trigger budget/goal updates
      await TransactionEventService.instance.onTransactionCreated(transaction);
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to create transaction', e, stackTrace);
      return false;
    }
  }

  /// Update an existing transaction and emit updated event
  static Future<bool> updateTransaction({
    required Transaction transaction,
    required OfflineDataService offlineService,
  }) async {
    try {
      // Update transaction in database
      await offlineService.updateTransaction(transaction);
      _logger.info('Transaction updated: ${transaction.id}');
      
      // Emit updated event to trigger recalculation
      await TransactionEventService.instance.onTransactionUpdated(transaction);
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to update transaction', e, stackTrace);
      return false;
    }
  }

  /// Delete a transaction and emit deleted event
  static Future<bool> deleteTransaction({
    required Transaction transaction,
    required OfflineDataService offlineService,
  }) async {
    try {
      // Delete transaction from database
      await offlineService.deleteTransaction(transaction.id!);
      _logger.info('Transaction deleted: ${transaction.id}');
      
      // Emit deleted event to trigger updates
      await TransactionEventService.instance.onTransactionDeleted(transaction);
      
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete transaction', e, stackTrace);
      return false;
    }
  }

  /// Approve a pending transaction (convert to confirmed) and emit approved event
  static Future<bool> approvePendingTransaction({
    required Transaction pendingTransaction,
    required OfflineDataService offlineService,
  }) async {
    try {
      // Create confirmed transaction from pending
      final confirmedTransaction = pendingTransaction.copyWith(
        isPending: false,
      );
      
      // Approve in database (saves as regular transaction, deletes from pending)
      await offlineService.approvePendingTransaction(confirmedTransaction);
      _logger.info('Pending transaction approved: ${confirmedTransaction.id}');
      
      // Emit approved event to trigger budget/goal updates
      await TransactionEventService.instance.onTransactionApproved(confirmedTransaction);
      
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