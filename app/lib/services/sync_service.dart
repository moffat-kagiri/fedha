// lib/services/sync_service.dart
import 'package:drift/drift.dart';
import '../data/app_database.dart';
import 'api_client.dart';
import 'offline_data_service.dart';
import '../models/sync_result.dart';

/// Enhanced sync service for comprehensive offline-online data synchronization
/// Handles bidirectional sync of all entity types with conflict resolution
class SyncService {
  final ApiClient _apiClient;
  final OfflineDataService _offlineDataService;
  late final AppDatabase _db;

  SyncService({
    required ApiClient apiClient,
    required OfflineDataService offlineDataService,
  }) : _apiClient = apiClient,
       _offlineDataService = offlineDataService {
    _db = _offlineDataService.db;
  }

  /// Synchronize all data for a profile
  Future<SyncResult> syncAllData(int profileId) async {
    final result = SyncResult();

    try {      
      // Sync in order of dependencies
      result.transactions = await syncTransactions(profileId);
      result.categories = await syncCategories(profileId);
      result.success = true;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }

    return result;
  }

  /// Sync transactions with the backend
  Future<EntitySyncResult> syncTransactions(int profileId) async {
    final result = EntitySyncResult();

    try {
      // Get transactions for the profile
      final transactions = await (_db.select(_db.transactions)
        ..where((t) => t.profileId.equals(profileId)))
        .get();

      if (transactions.isNotEmpty) {
        // Send to backend
        await _apiClient.syncTransactions(
          profileId,
          transactions.map((t) => {
            'id': t.id,
            'amount': t.amountMinor,
            'description': t.description,
            'categoryId': t.categoryId,
            'date': t.date.toIso8601String(),
            'isExpense': t.isExpense,
            'profileId': t.profileId,
            'currency': t.currency,
            'rawSms': t.rawSms,
          }).toList(),
        );

        result.uploaded = transactions.length;
      }

      // Fetch updates from backend
      final serverTransactions = await _apiClient.getTransactions(profileId);

      // Update local transactions with server data
      for (final serverTx in serverTransactions) {
        final existingTxs = await (_db.select(_db.transactions)
          ..where((t) => t.categoryId.equals(serverTx.categoryId))
          ..where((t) => t.date.equals(serverTx.date)))
          .get();

        if (existingTxs.isEmpty) {
          // New transaction from server
          await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              amountMinor: serverTx.amountMinor,
              description: serverTx.description,
              categoryId: serverTx.categoryId,
              date: serverTx.date,
              isExpense: serverTx.isExpense,
              profileId: profileId,
              currency: serverTx.currency,
              rawSms: const Value.absent(),
            )
          );
          result.downloaded++;
        } else {
          // Update existing transaction
          await _db.into(_db.transactions).insert(
            TransactionsCompanion(
              id: Value(existingTxs.first.id),
              amountMinor: Value(serverTx.amountMinor),
              description: Value(serverTx.description),
              categoryId: Value(serverTx.categoryId),
              date: Value(serverTx.date),
              isExpense: Value(serverTx.isExpense),
              profileId: Value(profileId),
              currency: Value(serverTx.currency),
              rawSms: Value(existingTxs.first.rawSms),
            ),
            mode: InsertMode.insertOrReplace,
          );
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
  Future<EntitySyncResult> syncCategories(int profileId) async {
    final result = EntitySyncResult();

    try {
      // Get categories for profile
      final categories = await (_db.select(_db.categories)
        ..where((c) => c.profileId.equals(profileId)))
        .get();

      if (categories.isNotEmpty) {
        await _apiClient.syncCategories(
          profileId,
          categories.map((c) => {
            'id': c.id,
            'name': c.name,
            'isExpense': c.isExpense,
            'profileId': c.profileId,
          }).toList(),
        );

        result.uploaded = categories.length;
      }

      // Get updates from server
      final serverCategories = await _apiClient.getCategories(profileId);

      for (final serverCat in serverCategories) {
        final existingCats = await (_db.select(_db.categories)
          ..where((c) => c.name.equals(serverCat.name)))
          .get();

        if (existingCats.isEmpty) {
          await _db.into(_db.categories).insert(
            CategoriesCompanion.insert(
              name: serverCat.name,
              isExpense: serverCat.isExpense,
              profileId: profileId,
            )
          );
          result.downloaded++;
        } else {
          await _db.into(_db.categories).insert(
            CategoriesCompanion(
              id: Value(existingCats.first.id),
              name: Value(serverCat.name),
              isExpense: Value(serverCat.isExpense),
              profileId: Value(profileId),
            ),
            mode: InsertMode.insertOrReplace,
          );
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
  Future<void> autoSync(int profileId) async {
    final canSyncNow = await canSync();
    if (!canSyncNow) return;

    await syncAllData(profileId);
  }
}
