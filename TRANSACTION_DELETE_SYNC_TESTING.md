# Quick Testing Guide - Transaction Delete & Sync

## Pre-Test Setup

```bash
# 1. Clear all existing transactions
cd C:\GitHub\fedha\backend
python manage.py clear_transactions --all --force

# 2. Rebuild Flutter app
cd C:\GitHub\fedha\app
flutter clean
flutter pub get
flutter run
```

---

## Test Case 1: Delete Single Transaction (Immediate)

**Scenario**: Delete transaction → should disappear immediately from app

```
1. ✅ Open Transactions screen
2. ✅ See some transactions listed
3. ✅ Swipe left on one transaction → Delete button appears
4. ✅ Tap Delete → Confirm dialog
5. ✅ Confirm → Transaction disappears immediately
6. ✅ No error messages shown
```

**Expected Result**: ✅ Transaction gone from UI instantly

---

## Test Case 2: Delete Transaction (Backend Verification)

**Scenario**: Delete transaction → backend gets updated

```
1. ✅ Delete a transaction in the app
2. ✅ App shows it's deleted
3. ✅ Check backend logs for DELETE sync:
   
   Look for: "🗑️ Syncing X deleted transactions to backend"
   And: "✅ Deleted transactions synced: X soft-deleted on backend"
   
4. ✅ Verify backend database:
   psql -U postgres -d fedha_db
   SELECT id, is_deleted FROM transactions_transaction LIMIT 5;
   (Should show is_deleted=True for deleted transactions)
```

**Expected Result**: ✅ Backend logs show delete sync, DB shows is_deleted=True

---

## Test Case 3: Delete Transaction (Persistence)

**Scenario**: Delete → refresh app → transaction should NOT reappear

```
1. ✅ Delete a transaction (see Test Case 1)
2. ✅ Close and reopen the app (or force refresh)
3. ✅ Go back to Transactions screen
4. ✅ Scroll through all transactions
5. ❌ Deleted transaction should NOT be in the list
```

**Expected Result**: ✅ Deleted transaction stays deleted after refresh

---

## Test Case 4: Offline Delete (Advanced)

**Scenario**: Delete while offline → should sync when online

```
1. ✅ Turn off WiFi/Mobile data
2. ✅ Delete a transaction in the app
3. ✅ Transaction disappears from UI
4. ✅ Turn WiFi back on
5. ✅ Check logs: should see "Syncing X deleted transactions to backend"
6. ✅ Refresh transactions → still deleted
```

**Expected Result**: ✅ Offline deletion syncs automatically when online

---

## Test Case 5: Edit Transaction (Already Working ✅)

**Scenario**: Edit transaction → refresh app → changes persist

```
1. ✅ Open a transaction → Edit
2. ✅ Change amount, category, description
3. ✅ Save → "Transaction updated successfully" message
4. ✅ Close and reopen the app
5. ✅ Go back to Transactions screen
6. ✅ Open the transaction again
7. ✅ Verify new values are shown
```

**Expected Result**: ✅ Edits persist after refresh

---

## Test Case 6: Bulk Clear Database

**Scenario**: Clear entire database for next round of testing

```bash
# Option 1: Clear all transactions
python manage.py clear_transactions --all --force

# Option 2: Clear specific profile's transactions
python manage.py clear_transactions --profile-id 550e8400-e29b-41d4-a716-446655440000 --force

# Option 3: List all profiles (interactive)
python manage.py clear_transactions
```

**Expected Result**: ✅ Database cleared, ready for fresh test

---

## Debug Commands

### Check App Logs for Delete Sync
```
# Look for these patterns in Flutter logs:
"🗑️ Syncing X deleted transactions to backend"
"✅ Deleted transactions synced: X soft-deleted on backend"
"✅ Transaction hard deleted from database: <id>"
```

### Check Backend API Calls
```
# Django logs should show:
"POST /api/transactions/batch_delete/"
"Deleted X transactions"
```

### Verify Database State
```bash
# Login to PostgreSQL
psql -U postgres -d fedha_db

# Check transactions table
SELECT id, is_deleted, description FROM transactions_transaction 
WHERE is_deleted = true 
LIMIT 10;

# Count deleted vs active
SELECT is_deleted, COUNT(*) FROM transactions_transaction GROUP BY is_deleted;
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Delete doesn't disappear immediately | Check `_deleteTransaction()` is being called in transactions_screen.dart |
| Deleted transaction reappears after refresh | Check backend logs for batch_delete sync errors |
| Update changes don't persist | Verify `UnifiedSyncService.syncProfile()` is called |
| Offline delete not syncing | Check connectivity service and sync queue |
| "No active profile found" error | Verify you're logged in and profile is initialized |

---

## Success Criteria

✅ Transactions deleted immediately in app  
✅ Deleted transactions sync to backend (logs confirm)  
✅ Deleted transactions don't reappear after refresh  
✅ Updated transactions retain changes after refresh  
✅ Offline operations sync when connection restored  
✅ Database can be cleared for fresh tests  

---

## After Testing

Clear database before next test round:
```bash
python manage.py clear_transactions --all --force
```

This ensures clean state and no interference from previous test runs.
