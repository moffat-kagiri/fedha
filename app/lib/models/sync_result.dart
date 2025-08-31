// lib/models/sync_result.dart

/// Result of a sync operation for a single entity type
class EntitySyncResult {
  bool success = false;
  int uploaded = 0;
  int downloaded = 0;
  int updated = 0;
  String? error;
}

/// Result of a full sync operation across all entity types
class SyncResult {
  bool success = false;
  EntitySyncResult? transactions;
  EntitySyncResult? categories;
  EntitySyncResult? clients;
  EntitySyncResult? invoices;
  EntitySyncResult? goals;
  EntitySyncResult? budgets;
  String? error;
}
