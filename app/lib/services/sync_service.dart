// lib/services/sync_service.dart
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import 'api_client.dart';

class SyncService {
  final ApiClient _apiClient;
  final Box<Transaction> _transactionBox;

  SyncService({
    required ApiClient apiClient,
    required Box<Transaction> transactionBox,
  }) : _apiClient = apiClient,
       _transactionBox = transactionBox;

  Future<void> syncTransactions(String profileId) async {
    // Get all unsynced transactions
    final unsyncedTransactions =
        _transactionBox.values
            .where(
              (transaction) =>
                  !transaction.isSynced && transaction.profileId == profileId,
            )
            .toList();

    if (unsyncedTransactions.isEmpty) return;

    try {
      // Send to backend - pass the Transaction objects directly
      await _apiClient.syncTransactions(profileId, unsyncedTransactions);

      // Update sync status in Hive
      final writeBatch = _transactionBox;
      for (final transaction in unsyncedTransactions) {
        transaction.isSynced = true;
        writeBatch.put(transaction.uuid, transaction); // Use uuid instead of id
      }

      // If using Hive 3.x+ with batch support:
      // final batch = _transactionBox.batch();
      // for (final transaction in unsyncedTransactions) {
      //   transaction.isSynced = true;
      //   batch.put(transaction.uuid, transaction);
      // }
      // await batch.commit();
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  Future<int> getPendingSyncCount(String profileId) async {
    return _transactionBox.values
        .where(
          (transaction) =>
              !transaction.isSynced && transaction.profileId == profileId,
        )
        .length;
  }
}
