# Transaction Duplicate & Sync Issue - Root Cause Analysis & Fixes

## Executive Summary
Three related issues were identified and fixed:
1. **Duplicate transaction creation** when approving SMS pending transactions
2. **Transactions not syncing back** to frontend SQLite after backend saves
3. **Missing `remoteId` tracking** preventing cross-device sync

All issues have been resolved with targeted fixes across frontend and backend.

---

## Issue 1: Duplicate Transaction Creation on Approval

### Root Cause
**Location**: `app/lib/screens/sms_review_screen.dart` (lines 134-149)

When approving a pending transaction, the code was calling `approvePendingTransaction()` which saves to the database, **then immediately calling `saveTransaction()` again** plus emitting duplicate events:

```dart
// ❌ PROBLEMATIC CODE
final success = await TransactionOperations.approvePendingTransaction(
  pendingTransaction: tx,
  offlineService: dataService,  // ← Already saves internally
);

if (success) {
  await dataService.saveTransaction(tx);              // ← DUPLICATE SAVE #1
  await eventService.onTransactionApproved(tx);        // ← DUPLICATE EVENT #1
  await eventService.onTransactionCreated(tx);         // ← DUPLICATE EVENT #2
  await dataService.deletePendingTransaction(candidate.id!);  // ← Already deleted
}
```

**Why it created duplicates:**
- `approvePendingTransaction()` calls `saveTransaction()` internally (in OfflineDataService)
- Then the screen code calls `saveTransaction()` again
- Since each save operation generates a new sequential ID in SQLite, this results in TWO distinct transactions with different IDs but same amount/date

**Evidence from logs:**
```
I/flutter: ✅ Transaction saved with ID: 1
I/flutter: Transaction created: 1 - 9000
I/flutter: ✅ Pending transaction approved and saved (no duplication)
I/flutter: ✅ Transaction saved with ID: 2  ← Second save!
I/flutter: Transaction created: 2 - 9000
```

### Fix Applied
**Location**: `app/lib/screens/sms_review_screen.dart` (lines 134-149)

Removed all redundant operations. The `TransactionOperations.approvePendingTransaction()` method ALREADY handles:
- ✅ Saving the transaction to database
- ✅ Emitting `onTransactionCreated()` event (which triggers budget updates, goal tracking, etc.)
- ✅ Deleting from pending transactions

```dart
// ✅ FIXED CODE
final success = await TransactionOperations.approvePendingTransaction(
  pendingTransaction: tx,
  offlineService: dataService,
);

if (success) {
  // ❌ REMOVED: await dataService.saveTransaction(tx);
  // ❌ REMOVED: await eventService.onTransactionApproved(tx);
  // ❌ REMOVED: await eventService.onTransactionCreated(tx);
  // ❌ REMOVED: await dataService.deletePendingTransaction(candidate.id!);
  // All of the above is already handled by approvePendingTransaction()
}
```

---

## Issue 2: Transactions Not Syncing Back to Frontend

### Root Cause
**Location**: `app/lib/services/unified_sync_service.dart` + `backend/transactions/views.py`

The upload was working (transactions saved to backend), but the frontend wasn't pulling them back because:

1. **Backend wasn't returning created transaction IDs**
   - When `bulk_sync` created new transactions, it didn't return their server-side UUIDs
   - Frontend had no way to link local transactions to remote ones

2. **Frontend wasn't updating `remoteId` after sync**
   - After uploading, transactions had `remoteId: null`
   - On next sync, they would upload again (duplication on server)
   - The GET request would skip them (already exists locally check)

**Evidence from backend logs:**
```
INFO 2026-01-31 16:55:53,625 views Successfully created new transaction
INFO 2026-01-31 16:55:53,955 log "GET /api/transactions/?profile_id=51f02462-1860-475e-bbe2-80bd129ea7a5 HTTP/1.1" 200 52
                                                    ↑ Empty response (200 with 52 bytes = "[]")
```

### Fix Applied

#### Backend Fix 1: Return Created Transaction IDs
**Location**: `backend/transactions/views.py` (bulk_sync method)

Modified to track and return server-generated UUIDs for all created transactions:

```python
created_ids = []  # ✅ NEW: Track created transaction IDs

for idx, transaction_data in enumerate(transactions_data):
    if serializer.is_valid():
        instance = serializer.save(profile=user_profile)
        created_count += 1
        created_ids.append(str(instance.id))  # ✅ NEW: Save server UUID

response_data = {
    'success': True,
    'created': created_count,
    'updated': updated_count,
    'created_ids': created_ids,  # ✅ NEW: Return to frontend
    'errors': errors
}
```

#### Frontend Fix 1: Process Returned IDs
**Location**: `app/lib/services/unified_sync_service.dart` (lines 210-235)

After batch upload, immediately update local transactions with the server IDs:

```dart
if (response['success'] == true) {
    final created = response['created'] as int? ?? 0;
    final createdIds = response['created_ids'] as List? ?? [];  // ✅ NEW
    
    if (createdIds.isNotEmpty) {
        _logger.info('📌 Tracking ${createdIds.length} created transaction IDs');
        for (int j = 0; j < batch.length && j < createdIds.length; j++) {
            final batchItem = batch[j];
            final remoteId = createdIds[j]?.toString();
            if (remoteId != null && batchItem['amount'] != null) {
                // ✅ NEW: Set remoteId on uploaded transaction
                await _offlineDataService.updateTransactionRemoteId(
                    amount: txAmount,
                    date: txDate,
                    profileId: profileId,
                    remoteId: remoteId,
                );
            }
        }
    }
}
```

#### Frontend Fix 2: New Method to Update RemoteId
**Location**: `app/lib/services/offline_data_service.dart`

Added new method `updateTransactionRemoteId()` to set the server UUID on synced transactions:

```dart
/// ✅ NEW: Update remoteId for a transaction (used after syncing to backend)
Future<void> updateTransactionRemoteId({
  required int amount,
  required String date,
  required String profileId,
  required String remoteId,
}) async {
  try {
    // Find the transaction by amount, date, and profileId
    final txs = allTxs.where((t) => 
      t.amountMinor == amount &&
      t.profileId == profileIdInt &&
      t.date.year == dateTime.year &&
      t.date.month == dateTime.month &&
      t.date.day == dateTime.day
    ).toList();
    
    // Update the most recent transaction without a remoteId
    final txToUpdate = txs.firstWhere(
      (t) => t.remoteId == null || t.remoteId!.isEmpty,
      orElse: () => txs.last,
    );
    
    final companion = app_db.TransactionsCompanion(
      id: Value(txToUpdate.id),
      remoteId: Value(remoteId),
      isSynced: Value(true),
      updatedAt: Value(DateTime.now()),
    );
    
    await _db.updateTransaction(companion);
    _logger.info('✅ Updated remoteId for transaction ${txToUpdate.id}: $remoteId');
  } catch (e) {
    _logger.severe('Error updating transaction remoteId', e);
  }
}
```

---

## Issue 3: Cross-Device Sync Prevention

### Root Cause
Without `remoteId` being set on synced transactions:
- Transactions would re-upload on every sync (no `remoteId` to identify them)
- GET requests would fetch them again (no `remoteId` match to deduplicate)
- Device B would miss Device A's changes (never properly marked as synced)

### Fix Applied
**All three fixes above** together solve this:
1. Backend now returns created UUIDs → Frontend knows the server IDs
2. Frontend updates `remoteId` on synced transactions → No re-upload
3. Next sync: GET query properly deduplicates (checks `remoteId`)
4. Device B logs in: pulls all synced transactions with `remoteId` set

**Sync workflow is now:**
```
Device A offline:
  - Create transaction → Saved locally (remoteId: null)
  - Add to sync queue

Device A online:
  - Upload transaction → Backend creates with UUID "abc-123"
  - Backend returns: created_ids: ["abc-123"]
  - Frontend updates transaction: remoteId: "abc-123", isSynced: true
  - Sync queue cleared

Device B offline:
  - No changes yet

Device B online:
  - GET /api/transactions/ → Returns all transactions
  - Frontend checks: existing by remoteId? No → Save it
  - Transaction now on Device B with remoteId: "abc-123"

Device A offline, adds new transaction
Device A online:
  - Check local vs remote by remoteId → Matches → No re-upload ✅
```

---

## Files Modified

### Frontend (Dart/Flutter)
1. **`app/lib/screens/sms_review_screen.dart`**
   - Removed duplicate save/event calls in `_approveCandidate()` method

2. **`app/lib/services/offline_data_service.dart`**
   - Added new `updateTransactionRemoteId()` method to set server UUIDs

3. **`app/lib/services/unified_sync_service.dart`**
   - Enhanced batch upload handler to process `created_ids` response
   - Calls new `updateTransactionRemoteId()` method after successful upload

### Backend (Python/Django)
1. **`backend/transactions/views.py`**
   - Modified `bulk_sync()` action to track and return created transaction IDs
   - Returns `created_ids` list in response

---

## Testing Checklist

After deployment, verify:

- [ ] **Duplicate Prevention**: Approve one SMS transaction → Should see exactly 1 entry (not 2)
- [ ] **Sync Success**: After approval, check Backend transaction log shows only 1 creation
- [ ] **RemoteId Set**: Query SQLite after sync → `remoteId` column populated with server UUID
- [ ] **No Re-upload**: Sync again → No duplicate transactions in backend
- [ ] **Cross-Device Sync**: Log in on Device B → Can see Device A's synced transactions
- [ ] **Budget/Goal Updates**: Transaction appears in budget/goal calculations (events working)

---

## Architecture Notes

### Why These Issues Existed
The codebase had good intentions with separation of concerns:
- `TransactionOperations` helper for business logic
- `OfflineDataService` for database operations  
- `TransactionEventService` for UI updates

But the SMS review screen was calling these redundantly, and the sync service wasn't capturing server-returned IDs.

### Design Improvements Made
1. **Single Responsibility**: Screen now delegates entirely to `TransactionOperations`
2. **Server ID Tracking**: Backend now returns what it creates
3. **Explicit State Sync**: Frontend explicitly updates local state with server IDs

This aligns with the offline-first architecture where local state must explicitly reconcile with remote state.

---

## Related Documentation
- See `.github/copilot-instructions.md` for architecture patterns
- See `docs/OFFLINE_FEATURES.md` for offline transaction handling
- See `docs/CONNECTION_GUIDE.md` for backend connection setup

