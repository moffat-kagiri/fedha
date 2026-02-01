# Fedha Sync Architecture - Technical Deep Dive

## Problem Statement

The Fedha offline-first sync system had three interconnected issues causing data corruption:

1. **Duplicate SMS Approvals**: One SMS approval → 2 local transactions
2. **No Sync-Back**: Backend creates transactions with UUIDs, frontend doesn't store them
3. **4x Re-uploads**: Without remoteId tracking, same transactions uploaded 4x per sync
4. **One-Way Sync**: Only new transactions sync; edits/deletes ignored

Root cause: **Transactions not marked with server UUIDs (remoteId) after upload**

---

## Architecture Overview

### Data Model: Transaction (Local)

```dart
class Transaction {
  String id;           // Local UUID (generated client-side)
  String? remoteId;    // Server UUID (set AFTER first sync) ← KEY FIX
  String profileId;    // User UUID
  int amount;          // In cents (amountMinor)
  String type;         // 'income', 'expense', 'savings', 'transfer'
  DateTime date;
  bool isSynced;       // false = pending upload
  // ... other fields
}
```

### Data Model: Transaction (Server)

```python
class Transaction(models.Model):
    id = UUIDField(primary_key=True, default=uuid4)  # Server-side UUID
    profile = ForeignKey(Profile)
    amount = DecimalField()
    type = CharField(choices=['income', 'expense', ...])
    is_synced = BooleanField(default=False)
    # ... other fields
```

### Sync Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ SYNC CYCLE: _syncTransactionsBatch(profileId)                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│ STEP 1: UPLOAD phase                                            │
│ ├─ 1a: NEW transactions (remoteId == null)                      │
│ │   ├─ Filter: localTX where remoteId == null                   │
│ │   ├─ Validate: amount > 0, type valid, etc.                   │
│ │   ├─ Prepare: Convert to backend format                       │
│ │   ├─ Map: Track batch index → original Transaction (NEW!)     │
│ │   ├─ Upload: POST /api/transactions/bulk_sync/                │
│ │   ├─ Response: {created_ids: [uuid1, uuid2, ...]}             │
│ │   └─ Process: Update local TX with remoteId (KEY FIX!)        │
│ │       ├─ localTX.remoteId = uuid                              │
│ │       ├─ localTX.isSynced = true                              │
│ │       └─ Store updated TX in SQLite                           │
│ │                                                                 │
│ ├─ 1b: EDITED transactions (remoteId != null && !isSynced)      │
│ │   ├─ Filter: localTX where remoteId != null && !isSynced      │
│ │   ├─ Upload: POST /api/transactions/batch_update/             │
│ │   ├─ Response: {updated: N}                                   │
│ │   └─ Mark: isSynced = true                                    │
│ │                                                                 │
│ └─ 1c: DELETED transactions (placeholder)                       │
│     └─ TODO: Implement when Transaction.isDeleted added         │
│                                                                   │
│ STEP 2: DOWNLOAD phase                                          │
│ ├─ Fetch: GET /api/transactions/?profile_id=xxx                 │
│ └─ Response: [{id: uuid1, amount: 50, ...}, ...]                │
│                                                                   │
│ STEP 3: MERGE phase                                             │
│ ├─ For each remote TX:                                          │
│ │   ├─ Check: Is remoteId in local DB already?                  │
│ │   ├─ If NO → Create new local TX with remoteId                │
│ │   └─ If YES → Skip (already have this one)                    │
│ └─ Result: remoteId matching prevents duplicate imports         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Fix #1: Batch-to-Transaction Mapping

### Problem
After uploading batch of transactions, backend returns `created_ids`, but we lost track of which ID corresponds to which local transaction.

**Before (BROKEN)**:
```dart
for (int j = 0; j < batch.length && j < createdIds.length; j++) {
  final batchItem = batch[j];  // ← batch item is Map<String, dynamic>
  final remoteId = createdIds[j].toString();
  
  // Try to find original TX by amount (UNRELIABLE!)
  // ❌ If user has multiple 100 KES transactions, picks wrong one
  // ❌ Decimal amount (100.50) vs. cents (10050) mismatch
  // ❌ Date matching fails (timezone issues)
  await _offlineDataService.updateTransactionRemoteId(
    amount: (batchItem['amount'] as num).toInt(), // ← WRONG
    date: batchItem['date'].toString(),            // ← WRONG
    profileId: profileId,
    remoteId: remoteId,
  );
}
```

**After (FIXED)**:
```dart
// ✅ Create mapping BEFORE uploading
final batchTransactionMap = <int, Transaction>{};
int batchIndex = 0;
for (final t in unsyncedTransactions) {
  if (/* validation passes */) {
    batchData.add(_prepareTransactionForUpload(t, profileId));
    batchTransactionMap[batchIndex] = t;  // ← Remember the TX object
    batchIndex++;
  }
}

// ✅ After upload, use original TX object directly
for (int j = 0; j < batch.length && j < createdIds.length; j++) {
  final transactionIndex = batchStartIndex + j;
  final originalTransaction = batchTransactionMap[transactionIndex];  // ← Get original
  
  if (originalTransaction != null) {
    // ✅ Use exact object, no matching needed
    final updatedTransaction = originalTransaction.copyWith(
      remoteId: remoteId,
      isSynced: true,
    );
    await _offlineDataService.updateTransaction(updatedTransaction);  // ✅ Update
  }
}
```

**Why This Works**:
- No matching needed (exact object reference)
- No decimal/int conversion confusion
- No timezone/date parsing issues
- O(1) lookup instead of O(n) search

---

## Key Fix #2: Backend Response Format

### Problem
Backend wasn't returning the UUIDs of created transactions, so frontend couldn't know which remoteId to set.

**Before**:
```python
# bulk_sync() response
return Response({
    'created': 5,
    'updated': 0,
    # ❌ Missing: created transaction IDs
})
```

**After**:
```python
# bulk_sync() response
created_ids = []
for transaction_data in transactions_data:
    # ... validation ...
    instance = serializer.save(profile=user_profile)
    created_ids.append(str(instance.id))  # ← Track ID

return Response({
    'created': len(created_ids),
    'updated': 0,
    'created_ids': created_ids,  # ✅ Return UUIDs
})
```

**Impact**: Frontend can now correlate batch index → remoteId

---

## Key Fix #3: Edit/Delete Sync Infrastructure

### Backend Endpoints Added

```python
# batch_update/ - Update existing transactions
@action(detail=False, methods=['post'])
def batch_update(self, request):
    """
    Request: [
        {'id': uuid, 'amount': 100, 'type': 'expense', ...},
        {'id': uuid2, 'amount': 50, ...},
    ]
    Response: {'success': true, 'updated': 2}
    """
    
# batch_delete/ - Delete transactions
@action(detail=False, methods=['post'])
def batch_delete(self, request):
    """
    Request: {'profile_id': uuid, 'transaction_ids': [uuid1, uuid2, ...]}
    Response: {'success': true, 'deleted': 2}
    """
```

### Frontend Sync Steps Added

```dart
// STEP 1b: Upload UPDATED transactions
final updatedTransactions = localTransactions
    .where((t) => t.remoteId != null && t.remoteId!.isNotEmpty && !t.isSynced)
    .toList();

// ✅ When user edits: isSynced set to false (but remoteId still set)
// ✅ Next sync: Uploads to /batch_update/ endpoint
// ✅ After success: isSynced = true

// STEP 1c: Upload DELETED transactions (placeholder)
// TODO: When Transaction.isDeleted is added:
// - Collect all isDeleted transactions
// - POST IDs to /batch_delete/
// - Remove from local DB on success
```

---

## Sync Flow Examples

### Example 1: Fresh Transaction Create

```
TIME 1: User creates TX
  ├─ Local: id=uuid1, remoteId=NULL, isSynced=false, amount=50
  └─ SQLite: Saved

TIME 2: Auto-sync triggers (STEP 1a)
  ├─ Prepare: {profile_id=uuid, amount=50, type='expense', ...}
  ├─ Map: batchTransactionMap[0] = original TX object
  ├─ Upload: POST /api/transactions/bulk_sync/
  └─ Response: {created_ids: ['server-uuid-123']}

TIME 3: Process response (KEY FIX)
  ├─ Get: originalTX = batchTransactionMap[0]
  ├─ Update: originalTX.copyWith(remoteId='server-uuid-123', isSynced=true)
  └─ SQLite: TX now has remoteId='server-uuid-123', isSynced=true

TIME 4: Next sync (STEP 2)
  ├─ Query local: WHERE remoteId IS NULL OR isSynced=false
  ├─ Result: NO MATCH (this TX now has remoteId & isSynced=true)
  └─ Decision: SKIP this TX (don't re-upload) ✅

TIME 5: Fresh install login (STEP 2)
  ├─ Download: GET /api/transactions/?profile_id=xxx
  ├─ Response: [{id: 'server-uuid-123', amount: 50, ...}]
  └─ STEP 3: Check remoteId matching
      ├─ Local remoteId present? YES (from TIME 3)
      ├─ Skip import? YES (already have) ✅
      └─ Result: No duplicate
```

### Example 2: Edit Transaction

```
TIME 1: After sync, TX has remoteId & isSynced=true
  ├─ SQLite: id=uuid1, remoteId='server-uuid-123', isSynced=true, amount=50

TIME 2: User edits TX amount: 50 → 75
  ├─ Local: id=uuid1, remoteId='server-uuid-123', isSynced=false, amount=75
  └─ SQLite: Updated, isSynced=false

TIME 3: Auto-sync triggers (STEP 1b)
  ├─ Filter: WHERE remoteId IS NOT NULL AND isSynced=false
  ├─ Result: Finds the edited TX
  ├─ Prepare: {id: 'server-uuid-123', amount: 75, type: 'expense', ...}
  ├─ Upload: POST /api/transactions/batch_update/
  └─ Response: {updated: 1}

TIME 4: Process response
  ├─ Mark: isSynced=true
  └─ SQLite: Updated, isSynced=true

TIME 5: Backend state
  ├─ DB: Transaction with id='server-uuid-123' now has amount=75 ✅
```

### Example 3: 4x Upload Problem (BEFORE FIX)

```
SYNC CYCLE 1:
  ├─ Create TX: amount=50, remoteId=NULL, isSynced=false
  ├─ Upload: POST /bulk_sync/ → backend creates UUID='abc123'
  ├─ ❌ Problem: Frontend doesn't set remoteId
  └─ TX still: remoteId=NULL, isSynced=false

SYNC CYCLE 2 (auto-sync on profile change):
  ├─ Query: WHERE remoteId IS NULL
  ├─ Finds: Same TX (remoteId STILL NULL)
  ├─ Re-uploads: POST /bulk_sync/ again
  └─ Backend: Creates ANOTHER UUID='def456' for same TX

SYNC CYCLE 3 (auto-sync on next screen):
  ├─ Same as CYCLE 2...
  └─ Backend: Creates THIRD UUID='ghi789'

SYNC CYCLE 4 (auto-sync on timer):
  ├─ Same as CYCLE 2...
  └─ Backend: Creates FOURTH UUID='jkl012'

RESULT:
  ├─ Frontend SQLite: 1 TX with remoteId=NULL (never synced)
  ├─ Backend DB: 4 rows with same amount=50, different UUIDs ❌
  └─ Frontend GET: Imports all 4, creating 4 duplicates ❌
```

### Example 4: 4x Upload Problem (AFTER FIX)

```
SYNC CYCLE 1:
  ├─ Create TX: amount=50, remoteId=NULL, isSynced=false
  ├─ Upload: POST /bulk_sync/ → backend creates UUID='abc123'
  ├─ ✅ Process response: Set remoteId='abc123', isSynced=true
  └─ TX now: remoteId='abc123', isSynced=true

SYNC CYCLE 2 (auto-sync on profile change):
  ├─ Query: WHERE remoteId IS NULL
  ├─ Result: Empty (TX has remoteId='abc123')
  └─ Decision: Nothing to upload ✅

SYNC CYCLE 3, 4: Same as CYCLE 2

RESULT:
  ├─ Frontend SQLite: 1 TX with remoteId='abc123', isSynced=true ✅
  ├─ Backend DB: 1 row with UUID='abc123', amount=50 ✅
  └─ No duplicates ✅
```

---

## Deduplication Strategy

### Frontend Deduplication (STEP 3)
```dart
// When downloading transactions from server
for (final remote in remoteTransactions) {
  final remoteId = remote['id'].toString();
  
  // Check if we already have this transaction locally
  final existsLocally = localTransactions.any((t) => t.remoteId == remoteId);
  
  if (!existsLocally) {
    // Only import if NOT already have it
    await _offlineDataService.saveTransaction(parsedTx);
  }
  // else: Skip (already have it)
}
```

**Why It Works**:
- Every server TX has a unique `id` (UUID)
- Frontend tracks `remoteId` (matches server `id`)
- On download: Match by remoteId, not by amount/date
- No duplicate imports from server

---

## Failure Recovery

### Scenario: Sync Partially Fails

```
Upload 5 transactions:
- TX1: ✅ Synced
- TX2: ✅ Synced
- TX3: ❌ Network error
- TX4: (not attempted)
- TX5: (not attempted)

Result:
- TX1, TX2: Have remoteId (won't re-upload)
- TX3, TX4, TX5: No remoteId (will re-upload on next sync)

Next sync:
- Uploads only TX3, TX4, TX5 (batch of 3)
- Gets new UUIDs
- Continues until all synced ✅
```

**No Data Corruption**: Even partial sync is idempotent due to remoteId tracking

---

## Performance Characteristics

| Operation | Before | After |
|-----------|--------|-------|
| Matching TX for update | O(n) search | O(1) direct reference |
| Preventing re-uploads | ❌ Failed | ✅ remoteId check |
| Deduplicating on download | ❌ No matching | ✅ remoteId matching |
| Handling batch failures | ❌ Duplicates | ✅ Idempotent retry |
| Memory during sync | O(n) | O(n) (same) |
| Storage overhead | 0 bytes | 36 bytes (UUID) per TX |

---

## Security Implications

1. **remoteId as Primary Key for Dedup**
   - UUIDs are not guessable
   - Prevents accidental sync of other users' transactions
   - Profile filtering enforced at backend

2. **No API Changes to Authentication**
   - All endpoints still require JWT token
   - Profile scoping maintained
   - User can only sync their own profile

3. **New Endpoints Security**
   - `/batch_update/`: Requires auth, user owns profile
   - `/batch_delete/`: Requires auth, user owns profile
   - No bypass of authorization

---

## Future Enhancements

### 1. Delete Sync Implementation
```dart
// When Transaction.isDeleted flag added:
final deletedTransactions = localTransactions.where((t) => t.isDeleted).toList();
final deleteIds = deletedTransactions.map((t) => t.remoteId).toList();
await _apiClient.deleteTransactions(profileId, deleteIds);
```

### 2. Conflict Resolution
Currently: Server-wins (server value overwrites client)
Future: Could implement:
- Client-wins (unlikely, data loss risk)
- Merge (complex, need timestamps)
- User prompt (UX heavy)

### 3. Optimistic Updates
```dart
// Show change immediately to user
await _offlineDataService.updateTransaction(editedTX);
notifyListeners(); // Update UI immediately

// Sync in background
// If fails: Revert locally (implement rollback)
```

### 4. Sync Queue Persistence
Track in Drift database:
- What's pending
- Retry attempts
- Error history
- Enable debugging and analytics

---

## Testing the Fixes

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for comprehensive test cases covering:
- Fresh install (no duplicates)
- Multiple transactions (no duplication)
- Edit sync
- Fresh app install (sync-back)
- Network recovery
- Batch handling
- Delete operations (when implemented)

---

**Architecture Complete** ✅

Ready for implementation testing. See TESTING_GUIDE.md for validation steps.
