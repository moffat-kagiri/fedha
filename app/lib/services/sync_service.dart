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
      transaction?.isSynced = true;
      transaction?.save();
    }
  }
}