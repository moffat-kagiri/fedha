# Fedha Sync System - Testing & Validation Guide

## Quick Summary of Changes
- ✅ Fixed duplicate SMS approval (removed redundant save)
- ✅ Added remoteId tracking with transaction mapping (prevents 4x re-uploads)
- ✅ Added updateTransactions() and deleteTransactions() API methods
- ✅ Added STEP 1b edit sync and STEP 1c delete placeholder

## Fresh Build Testing

### Prerequisites
```bash
# Terminal in app/ directory
flutter clean
flutter pub get
```

### Device Setup
- Ensure backend is running (Django dev server accessible)
- Verify network connectivity to backend (http://your-ip:8000/)
- For local testing: Use CONNECTION_GUIDE to set backend IP

---

## Test 1: Fresh Install - No Duplicates on Sync

### Steps
1. Fresh build: `flutter run -d android`
2. Create account / Login
3. Create ONE transaction:
   - Amount: 50.00 KES
   - Type: Expense
   - Category: Food
   - Description: "Test 1 - fresh install"
4. BEFORE closing app, check SQLite:
   ```sql
   SELECT id, amount, remote_id, is_synced FROM transactions WHERE amount = 5000;
   ```
   - Expected: `id=1, amount=5000, remote_id=NULL, is_synced=false`
5. Open app - should trigger auto-sync
6. Check logs for: `✅ Batch uploaded: 1 created, 0 updated`
7. Check SQLite again:
   ```sql
   SELECT id, amount, remote_id, is_synced FROM transactions WHERE amount = 5000;
   ```
   - Expected: `id=1, amount=5000, remote_id=(UUID), is_synced=true`

### Success Criteria
- [ ] Transaction uploaded once (1 created in response)
- [ ] remoteId populated in SQLite (not NULL)
- [ ] is_synced=true in SQLite
- [ ] Next sync does NOT re-upload (logs show: "No unsynced transactions")

### Failure Indicators
- ❌ remoteId still NULL after sync → CRITICAL (updateTransactionRemoteId not working)
- ❌ Transaction appears 4x in backend → CRITICAL (remoteId not preventing re-upload)
- ❌ is_synced=false after sync → CRITICAL (marking as synced not working)

---

## Test 2: Create Multiple Transactions - No Duplicates

### Steps
1. Create 5 transactions with different amounts:
   - TX1: 100 KES
   - TX2: 200 KES
   - TX3: 150 KES
   - TX4: 75 KES
   - TX5: 50 KES
2. Trigger sync (pull-to-refresh or wait for auto-sync)
3. Check backend logs for: `Successfully created new transaction (server ID: ...)`
   - Should show 5 different UUIDs
4. Check backend database:
   ```sql
   SELECT id, amount, profile_id FROM transactions ORDER BY created_at DESC LIMIT 5;
   ```
   - Expected: 5 unique rows with different amounts and UUIDs
5. Create 5 more identical amounts (test duplicate detection):
   - TX6: 100 KES (same as TX1)
   - TX7: 200 KES (same as TX2)
   - etc.
6. Trigger sync again
7. Check backend database:
   ```sql
   SELECT amount, COUNT(*) as count FROM transactions GROUP BY amount HAVING count > 1;
   ```
   - Expected: No more than 1 of each amount per profile

### Success Criteria
- [ ] 5 unique transactions in backend (no duplicates)
- [ ] Each has different UUID
- [ ] Each marked is_synced=true in frontend
- [ ] 5 new transactions (TX6-10) sync without duplication

### Failure Indicators
- ❌ Duplicate transactions in backend (same amount, multiple UUIDs)
- ❌ 4 copies of same transaction (indicates remoteId not set)

---

## Test 3: Edit Transaction - Sync to Backend

### Steps
1. From Test 1 or 2, identify one synced transaction (has remoteId)
2. Edit it locally:
   - Change amount: 50 → 75 KES
   - Change category: Food → Transport
   - Save locally
3. Check SQLite:
   ```sql
   SELECT id, amount, is_synced FROM transactions WHERE remote_id = '(the-uuid)';
   ```
   - Expected: `amount=7500, is_synced=false` (changed but not synced yet)
4. Trigger sync
5. Check logs for: `📝 Uploading X UPDATED transactions`
6. Check backend database:
   ```sql
   SELECT id, amount, category FROM transactions WHERE id = '(the-uuid)';
   ```
   - Expected: amount=75.00 (or 7500 cents), category='Transport'
7. Check SQLite again:
   ```sql
   SELECT id, amount, is_synced FROM transactions WHERE remote_id = '(the-uuid)';
   ```
   - Expected: `is_synced=true`

### Success Criteria
- [ ] Edit captured locally (is_synced=false after edit)
- [ ] STEP 1b uploads edited transaction via /batch_update/
- [ ] Backend receives and updates transaction
- [ ] Frontend marks is_synced=true after backend confirms
- [ ] Refresh shows updated value

### Failure Indicators
- ❌ Edit not syncing (is_synced stays false forever)
- ❌ Backend doesn't receive update (old value persists)
- ❌ /batch_update/ endpoint 404 (not added to backend)

---

## Test 4: Fresh App Install - No Data Loss

### Steps
1. With synced data in backend (from Tests 1-3), delete app from device
2. Reinstall: `flutter run -d android`
3. Login with same account
4. Check SQLite - should be empty initially
5. Open app - should trigger auto-sync with sync_all=true
6. Check logs for: `📥 Downloaded X transactions from server`
7. Check SQLite:
   ```sql
   SELECT COUNT(*) as tx_count FROM transactions;
   ```
   - Expected: Same number as uploaded in previous tests
8. Verify transactions display in app UI

### Success Criteria
- [ ] GET /transactions/ returns all synced transactions
- [ ] Transactions appear in app without needing new upload
- [ ] No duplicate imports (remoteId matching prevents duplicates)
- [ ] All transaction data (amount, category, date) correct

### Failure Indicators
- ❌ GET returns empty [] (backend filtering issue)
- ❌ Transactions appear twice (remoteId matching not working)
- ❌ Missing transactions (GET filtering broken)

---

## Test 5: Stress Test - 50+ Transactions Batch

### Steps
1. Create 50+ transactions rapidly using test script or UI spam
2. Trigger sync (should batch into 50-item chunks)
3. Monitor backend logs for multiple batch uploads
4. Check backend database: all should have unique UUIDs
5. Verify no 4x duplicates
6. Check frontend SQLite: all should have remoteId + isSynced=true

### Success Criteria
- [ ] Batching works (large uploads split correctly)
- [ ] All 50+ synced without duplication
- [ ] No timeout errors
- [ ] Memory usage reasonable

### Failure Indicators
- ❌ Only 50 uploaded, rest stuck
- ❌ Duplicates appear (remoteId not set on batch items after first 50)
- ❌ Timeout on large batch

---

## Test 6: Delete Transaction (When Implemented)

### Prerequisites
- Transaction model must have `isDeleted` flag
- Currently NOT IMPLEMENTED - skip for now

### Steps (Future)
1. Create and sync a transaction
2. Delete it locally
3. Check SQLite: `isDeleted=true` (if flag exists)
4. Trigger sync
5. Check logs for: `🗑️ Uploading X DELETE operations`
6. Check backend: transaction should be gone (or soft-deleted)
7. Check frontend SQLite: transaction should be removed

---

## Test 7: Network Interruption Recovery

### Steps
1. Create transaction (synced, has remoteId)
2. Edit it
3. Kill network (airplane mode or disconnect WiFi)
4. Try to sync - should fail gracefully
5. Edit another transaction (while offline)
6. Restore network
7. Trigger sync
8. Both edits should queue and sync when network returns

### Success Criteria
- [ ] App doesn't crash on network loss
- [ ] Transactions still marked for sync
- [ ] Both synced once network restored

---

## Debugging Checklist

If tests fail, check these in order:

### For "remoteId not updated" issues
1. Check if backend bulk_sync returns `created_ids` in response:
   ```bash
   # Check backend logs
   grep "created_ids" backend/logs/*.log
   ```
2. Check if frontend receives response:
   ```dart
   // Add logging to unified_sync_service.dart line ~220
   _logger.info('Response from sync: $response');
   _logger.info('Created IDs: ${response['created_ids']}');
   ```
3. Check if updateTransaction() is being called:
   ```dart
   // In OfflineDataService
   _logger.info('Updating transaction with remoteId: $remoteId');
   ```

### For "GET returns empty" issues
1. Check backend filter:
   ```python
   # In transactions/views.py get_queryset()
   logger.info(f"Profile ID from query: {profile_id}")
   logger.info(f"User profile: {user_profile.id}")
   logger.info(f"Queryset count: {queryset.count()}")
   ```
2. Check if profile_id matches:
   ```bash
   # In database
   SELECT id, profile_id, created_at FROM transactions LIMIT 5;
   SELECT id FROM profiles;
   ```

### For "4x duplicate uploads" issues
1. Check if remoteId is set immediately after sync:
   ```sql
   SELECT id, remote_id, is_synced FROM transactions WHERE amount = 5000;
   ```
2. Check if subsequent syncs skip these:
   ```
   # In logs, after 2nd sync:
   "No unsynced transactions to upload"
   # Should appear instead of re-uploading same TX
   ```
3. Check if multiple syncAll() being called:
   ```
   # Search logs for "syncAll" count
   grep -c "syncAll" app_logs.txt
   ```

---

## Backend Health Checks

Before testing, verify backend is healthy:

```bash
# Check migrations
python manage.py showmigrations transactions

# Check data
python manage.py shell
>>> from transactions.models import Transaction
>>> Transaction.objects.count()
>>> from accounts.models import Profile
>>> Profile.objects.count()

# Test endpoints manually
curl -X GET http://localhost:8000/api/transactions/ \
  -H "Authorization: Bearer YOUR_TOKEN"

curl -X POST http://localhost:8000/api/transactions/bulk_sync/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{"profile_id":"UUID", "amount":50, "type":"expense", ...}]'
```

---

## Success Metrics

After all tests pass:
- ✅ No 4x duplicate uploads
- ✅ remoteId populated on all synced transactions
- ✅ Edit/delete sync working (once delete implemented)
- ✅ Fresh install pulls all previous transactions
- ✅ Network recovery works
- ✅ Batch handling correct (50+ items)

---

## Next Steps After Validation

1. **Delete Sync Implementation**
   - Add `isDeleted: bool` to Transaction model
   - Regenerate: `dart run build_runner build`
   - Implement full STEP 1c with delete tracking

2. **Goals Sync Parity**
   - Apply same batch_update/batch_delete pattern
   - Test Goals sync matches Transactions

3. **Performance Optimization**
   - Implement sync debouncing
   - Add indexing on (profile_id, remote_id)
   - Monitor sync performance with large datasets

4. **Production Deployment**
   - Migrate existing data (set remoteId for old transactions)
   - Monitor early sync behavior
   - Add server-side analytics

---

**Ready to begin testing?** Run: `flutter clean && flutter pub get && flutter run`
