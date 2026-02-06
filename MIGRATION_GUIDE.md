# Backend Migration Guide

## Changes Made to Transaction Model

### New Fields Added
1. **`is_deleted`** (BooleanField, default=False)
   - Marks transactions as soft-deleted
   - Indexed for query performance
   - Allows data preservation for audit trails

2. **`deleted_at`** (DateTimeField, null=True)
   - Records when transaction was deleted
   - Useful for analytics and audit

### Database Migration Required

```bash
cd backend/
python manage.py makemigrations transactions
python manage.py migrate
```

### SQL Equivalent (if needed)

```sql
ALTER TABLE transactions ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE transactions ADD COLUMN deleted_at TIMESTAMP NULL;
CREATE INDEX idx_transactions_is_deleted ON transactions(is_deleted);
```

## Backend Changes

### TransactionViewSet.get_queryset()
- **Now filters**: `is_deleted=False` by default
- **Effect**: Soft-deleted transactions don't appear in GET requests
- **Safe**: Hard deletes still possible via Django admin

### batch_update() - Refined
- **Filters**: Only updates non-deleted transactions
- **Response**: Returns `failed_ids` for better error handling
- **Updated**: `updated_at` field set explicitly
- **Logging**: Enhanced with detailed debug info

### batch_delete() - Completely Redesigned
- **Type**: Changed from hard delete to soft delete
- **Operation**: Sets `is_deleted=True`, `deleted_at=NOW()`
- **Data Preservation**: All transaction data remains in database
- **Audit Trail**: Timestamps preserved for forensics
- **Support**: Both `ids` and `transaction_ids` parameter names
- **Response**: Clarifies `soft_deleted` count
- **Sync-Ready**: Can be synced back to frontend

### Transaction Serializer
- **Added**: `is_deleted` and `deleted_at` to fields list
- **Effect**: These fields now included in API responses

## Frontend Changes

### Transaction Model
- **Added**: `bool isDeleted` field (default=false)
- **Added**: `DateTime? deletedAt` field
- **Generated**: Run `dart run build_runner build` to regenerate `.g.dart` files

### UnifiedSyncService - STEP 1c Implementation
- **Now**: Fully implements delete sync (was placeholder)
- **Collects**: Transactions where `isDeleted=true` and `remoteId != null`
- **Uploads**: IDs to `/api/transactions/batch_delete/`
- **Cleanup**: Removes from local SQLite after sync success
- **Logging**: Detailed debug output with emoji indicators

## Data Flow - Delete Operation

### User Deletes Transaction (Frontend)

```
1. UI: User deletes transaction
   ↓
2. Frontend: tx.isDeleted = true, tx.isSynced = false
   ↓
3. OfflineDataService: Saves updated transaction to SQLite
   ↓
4. User sees: Transaction marked for deletion (grayed out)
```

### Next Sync Cycle

```
STEP 1c: Upload Deletions
  ├─ Query: WHERE isDeleted=true AND remoteId != null
  ├─ Response: selected transactions
  ├─ POST to /api/transactions/batch_delete/
  └─ Backend: Soft-deletes (is_deleted=true)

Response Processing:
  ├─ Backend confirms: deleted=1
  ├─ Frontend: DELETE from local SQLite
  └─ Result: No trace in frontend, data preserved in backend
```

### Fresh App Install

```
Login → GET /api/transactions/?profile_id=xxx
  ↓
GET QuerySet: Filters is_deleted=false
  ↓
Result: Only non-deleted transactions appear
  ↓
Deleted transaction: Never imported (is_deleted=true)
```

## Testing the Delete Feature

### Test 1: Delete a Synced Transaction
```
1. Create transaction (synced, has remoteId)
2. Delete locally (set isDeleted=true)
3. Check SQLite: Transaction still present with isDeleted=true
4. Trigger sync
5. Check backend logs: Soft-delete operation logged
6. Check backend DB: is_deleted=true, deleted_at set
7. Check frontend SQLite: Transaction deleted (or still present with isDeleted=true)
```

### Test 2: Delete During Offline
```
1. Delete transaction (offline)
2. Come online
3. Sync → Deletes synced to backend
4. Fresh install → Deleted transaction never appears
```

### Test 3: Concurrent Delete
```
1. Delete on Device A (offline)
2. Delete on Device B (offline)
3. Sync both
4. Backend: Both soft-deleted
5. No errors or conflicts
```

## Rollback (if needed)

If you need to hard-delete soft-deleted transactions:

```python
# In Django shell
from transactions.models import Transaction
from django.utils import timezone

# Delete transactions deleted more than 30 days ago
thirty_days_ago = timezone.now() - timedelta(days=30)
old_deleted = Transaction.objects.filter(
    is_deleted=True, 
    deleted_at__lt=thirty_days_ago
)
count = old_deleted.count()
old_deleted.delete()  # Hard delete
print(f"Hard-deleted {count} transactions")
```

## Data Integrity Checks

### Verify Migration Worked
```sql
-- Check columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name='transactions' 
AND column_name IN ('is_deleted', 'deleted_at');

-- Should show 2 rows
-- is_deleted | boolean
-- deleted_at | timestamp with time zone
```

### Verify Soft-Delete Works
```sql
-- Create and soft-delete a test transaction
INSERT INTO transactions (...) VALUES (...);
UPDATE transactions SET is_deleted=true, deleted_at=NOW() WHERE ...;

-- Verify it's hidden from queryset
SELECT COUNT(*) FROM transactions WHERE is_deleted=false;
-- Should NOT include soft-deleted transactions
```

### Check Index Performance
```sql
EXPLAIN ANALYZE
SELECT * FROM transactions 
WHERE profile_id='...' AND is_deleted=false 
ORDER BY date DESC;

-- Should use index_transactions_is_deleted for faster queries
```

## Monitoring

### Soft-Delete Rate
```sql
SELECT 
    DATE_TRUNC('day', deleted_at) as day,
    COUNT(*) as soft_deleted_count
FROM transactions
WHERE is_deleted=true
GROUP BY DATE_TRUNC('day', deleted_at)
ORDER BY day DESC;
```

### Soft vs Hard Deleted
```sql
-- Total transactions
SELECT COUNT(*) FROM transactions;

-- Soft-deleted
SELECT COUNT(*) FROM transactions WHERE is_deleted=true;

-- Active
SELECT COUNT(*) FROM transactions WHERE is_deleted=false;
```

## Questions & Answers

**Q: Why soft delete instead of hard delete?**
A: Soft delete preserves data for audit trails, recovery, and allows syncing the deletion back to frontend. Hard delete can't be synchronized.

**Q: Will soft-deleted data bloat the database?**
A: Minimal - the fields are indexed. For 1M transactions, ~8MB extra per soft-deleted status. Archive strategy can clean old deletes.

**Q: Can users recover deleted transactions?**
A: Not currently - `is_deleted=true` is permanent from frontend perspective. Admin can manually flip the flag in Django admin.

**Q: How does this affect pagination?**
A: Since `is_deleted` is in the WHERE clause, pagination works normally - count only includes active transactions.

---

## Quick Migration Checklist

- [ ] Run `python manage.py makemigrations transactions`
- [ ] Verify migration file created in `transactions/migrations/`
- [ ] Run `python manage.py migrate`
- [ ] Verify columns added to database
- [ ] Test POST /api/transactions/batch_delete/ with real IDs
- [ ] Verify soft-deleted don't appear in GET
- [ ] Update frontend with new `isDeleted` field
- [ ] Run `dart run build_runner build` in app/
- [ ] Test delete sync in fresh build
- [ ] Verify backend logs show soft-delete operations
