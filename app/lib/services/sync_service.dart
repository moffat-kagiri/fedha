// app/lib/services/sync_service.dart
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import 'api_client.dart';

class SyncService {
  final ApiClient _apiClient = ApiClient();
  final Box<Transaction> _transactionBox = Hive.box<Transaction>(
    'transactions',
  );

  Future<void> syncTransactions(String profileId) async {
    final unsynced =
        _transactionBox.values
            .where((t) => !t.isSynced)
            .map((t) => t.toJson())
            .toList();

    if (unsynced.isEmpty) return;

    try {
      await _apiClient.syncTransactions(profileId, unsynced);

      // Update local sync status
      final batch = _transactionBox.batch();
      for (var t in unsynced) {
        final transaction = _transactionBox.get(t['id']);
        transaction?.isSynced = true;
        batch.put(transaction!.id, transaction);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }
}
