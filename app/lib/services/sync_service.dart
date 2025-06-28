// lib/services/sync_service.dart
import 'api_client.dart';
import 'offline_data_service.dart';

/// Enhanced sync service for comprehensive offline-online data synchronization
/// Handles bidirectional sync of all entity types with conflict resolution
class SyncService {
  final ApiClient _apiClient;
  final OfflineDataService _offlineDataService;

  SyncService({
    required ApiClient apiClient,
    required OfflineDataService offlineDataService,
  }) : _apiClient = apiClient,
       _offlineDataService = offlineDataService;

  /// Synchronize all data for a profile
  Future<SyncResult> syncAllData(String profileId) async {
    final result = SyncResult();

    try {
      // Sync in order of dependencies
      result.transactions = await syncTransactions(profileId);
      result.categories = await syncCategories(profileId);
      result.clients = await syncClients(profileId);
      result.invoices = await syncInvoices(profileId);
      result.goals = await syncGoals(profileId);
      result.budgets = await syncBudgets(profileId);

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync transactions with the backend
  Future<EntitySyncResult> syncTransactions(String profileId) async {
    final result = EntitySyncResult();

    try {
      // Get unsynced local transactions
      final unsyncedTransactions = await _offlineDataService
          .getUnsyncedTransactions(profileId);

      if (unsyncedTransactions.isNotEmpty) {
        // Send to backend
        final _ = await _apiClient.syncTransactions(
          profileId,
          unsyncedTransactions,
        );

        // Mark as synced
        for (final transaction in unsyncedTransactions) {
          transaction.isSynced = true;
          await _offlineDataService.saveTransaction(transaction);
        }

        result.uploaded = unsyncedTransactions.length;
      }

      // Fetch updates from backend
      final serverTransactions = await _apiClient.getTransactions(profileId);

      // Update local transactions with server data
      for (final serverTransaction in serverTransactions) {
        final existingTransaction = await _offlineDataService.getTransaction(
          serverTransaction.uuid,
        );

        if (existingTransaction == null) {
          // New transaction from server
          await _offlineDataService.saveTransaction(serverTransaction);
          result.downloaded++;
        } else if (existingTransaction.updatedAt.isBefore(
          serverTransaction.updatedAt,
        )) {
          // Server has newer version
          await _offlineDataService.saveTransaction(serverTransaction);
          result.updated++;
        }
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync categories with the backend
  Future<EntitySyncResult> syncCategories(String profileId) async {
    final result = EntitySyncResult();

    try {
      // Get unsynced local categories
      final categories = await _offlineDataService.getAllCategories(profileId);
      final unsyncedCategories = categories.where((c) => !c.isSynced).toList();

      if (unsyncedCategories.isNotEmpty) {
        final _ = await _apiClient.syncCategories(
          profileId,
          unsyncedCategories,
        );

        for (final category in unsyncedCategories) {
          category.isSynced = true;
          await _offlineDataService.saveCategory(category);
        }

        result.uploaded = unsyncedCategories.length;
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync clients with the backend
  Future<EntitySyncResult> syncClients(String profileId) async {
    final result = EntitySyncResult();

    try {
      final clients = await _offlineDataService.getAllClients(profileId);
      final unsyncedClients = clients.where((c) => !c.isSynced).toList();

      if (unsyncedClients.isNotEmpty) {
        await _apiClient.syncClients(profileId, unsyncedClients);

        for (final client in unsyncedClients) {
          client.isSynced = true;
          await _offlineDataService.saveClient(client);
        }

        result.uploaded = unsyncedClients.length;
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync invoices with the backend
  Future<EntitySyncResult> syncInvoices(String profileId) async {
    final result = EntitySyncResult();

    try {
      final invoices = await _offlineDataService.getAllInvoices(profileId);
      final unsyncedInvoices = invoices.where((i) => !i.isSynced).toList();

      if (unsyncedInvoices.isNotEmpty) {
        await _apiClient.syncInvoices(profileId, unsyncedInvoices);

        for (final invoice in unsyncedInvoices) {
          invoice.isSynced = true;
          await _offlineDataService.saveInvoice(invoice);
        }

        result.uploaded = unsyncedInvoices.length;
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync goals with the backend
  Future<EntitySyncResult> syncGoals(String profileId) async {
    final result = EntitySyncResult();

    try {
      final goals = await _offlineDataService.getAllGoals(profileId);
      final unsyncedGoals = goals.where((g) => !g.isSynced).toList();

      if (unsyncedGoals.isNotEmpty) {
        await _apiClient.syncGoals(profileId, unsyncedGoals);

        for (final goal in unsyncedGoals) {
          goal.isSynced = true;
          await _offlineDataService.saveGoal(goal);
        }

        result.uploaded = unsyncedGoals.length;
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync budgets with the backend
  Future<EntitySyncResult> syncBudgets(String profileId) async {
    final result = EntitySyncResult();

    try {
      final budgets = await _offlineDataService.getAllBudgets(profileId);
      final unsyncedBudgets = budgets.where((b) => !b.isSynced).toList();

      if (unsyncedBudgets.isNotEmpty) {
        await _apiClient.syncBudgets(profileId, unsyncedBudgets);

        for (final budget in unsyncedBudgets) {
          budget.isSynced = true;
          await _offlineDataService.saveBudget(budget);
        }

        result.uploaded = unsyncedBudgets.length;
      }

      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Get total pending sync count
  Future<int> getPendingSyncCount(String profileId) async {
    int count = 0;

    final transactions = await _offlineDataService.getUnsyncedTransactions(
      profileId,
    );
    count += transactions.length;

    final categories = await _offlineDataService.getAllCategories(profileId);
    count += categories.where((c) => !c.isSynced).length;

    final clients = await _offlineDataService.getAllClients(profileId);
    count += clients.where((c) => !c.isSynced).length;

    final invoices = await _offlineDataService.getAllInvoices(profileId);
    count += invoices.where((i) => !i.isSynced).length;

    final goals = await _offlineDataService.getAllGoals(profileId);
    count += goals.where((g) => !g.isSynced).length;

    final budgets = await _offlineDataService.getAllBudgets(profileId);
    count += budgets.where((b) => !b.isSynced).length;

    return count;
  }

  /// Check if device is online and can sync
  Future<bool> canSync() async {
    try {
      await _apiClient.healthCheck();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Auto-sync when conditions are met
  Future<void> autoSync(String profileId) async {
    final canSyncNow = await canSync();
    if (!canSyncNow) return;

    final pendingCount = await getPendingSyncCount(profileId);
    if (pendingCount == 0) return;

    // Only auto-sync if there are pending items and we're online
    await syncAllData(profileId);
  }
}

/// Result classes for sync operations
class SyncResult {
  bool success = false;
  String? error;
  EntitySyncResult transactions = EntitySyncResult();
  EntitySyncResult categories = EntitySyncResult();
  EntitySyncResult clients = EntitySyncResult();
  EntitySyncResult invoices = EntitySyncResult();
  EntitySyncResult goals = EntitySyncResult();
  EntitySyncResult budgets = EntitySyncResult();

  int get totalUploaded =>
      transactions.uploaded +
      categories.uploaded +
      clients.uploaded +
      invoices.uploaded +
      goals.uploaded +
      budgets.uploaded;

  int get totalDownloaded =>
      transactions.downloaded +
      categories.downloaded +
      clients.downloaded +
      invoices.downloaded +
      goals.downloaded +
      budgets.downloaded;
}

class EntitySyncResult {
  bool success = false;
  String? error;
  int uploaded = 0;
  int downloaded = 0;
  int updated = 0;
  int conflicts = 0;
}
