import '../models/transaction.dart' show Transaction;
import '../services/api_client.dart'; // Adjust the import path based on your project structure
import 'package:hive/hive.dart';

class SyncService {
  final ApiClient _apiClient = ApiClient();
  final Box<Transaction> _transactionBox = Hive.box('transactions');

  Future<void> syncData(String profileId) async {
    // Get unsynced local transactions
    final localTransactions = _transactionBox.values
        .where((t) => !t.isSynced)
        .toList();

    // Send to Django
    final response = await _apiClient.syncTransactions(
      profileId,
      localTransactions,
    );

    // Update local state
    for (var t in response['synced_transactions']) {
      final transaction = _transactionBox.get(t['local_id']);
      if (transaction != null) {
        transaction.isSynced = true;
        await _transactionBox.put(t['local_id'], transaction);
      }
    }
  }

  Future<void> syncTransactions(String profileId) async {
    final localTransactions = Hive.box<Transaction>('transactions')
        .values
        .where((t) => !t.isSynced)
        .toList();

    if (localTransactions.isEmpty) return;

    await _apiClient.syncTransactions(
      profileId,
      localTransactions,
    );

    // Mark as synced
    for (var t in localTransactions) {
      t.isSynced = true;
      await _transactionBox.put(t.id, t);
    }
  }
}