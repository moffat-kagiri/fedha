# Quick Command Reference

## Setup & Testing Commands

### 1. Clear Database (Fresh Start)
```bash
cd C:\GitHub\fedha\backend
python manage.py clear_transactions --all --force
```
Result: All transactions deleted, ready for testing

---

### 2. List Available Profiles (Before Clear)
```bash
cd C:\GitHub\fedha\backend
python manage.py clear_transactions
```
Shows all profiles and their transaction counts

---

### 3. Clear Specific Profile's Transactions
```bash
python manage.py clear_transactions --profile-id 550e8400-e29b-41d4-a716-446655440000 --force
```

---

### 4. Start Backend Server
```bash
cd C:\GitHub\fedha\backend
python manage.py runserver 0.0.0.0:8000
```

---

### 5. Start Flutter App (Physical Device)
```bash
cd C:\GitHub\fedha\app
flutter run
```

---

### 6. Check App Logs for Delete Sync
```
Look for these patterns in "flutter run" output:

"🗑️ Syncing X deleted transactions to backend"
"✅ Deleted transactions synced: X soft-deleted on backend"
"✅ Transaction hard deleted from database: <id>"
```

---

### 7. Verify Database State (Direct DB Query)
```bash
psql -U postgres -d fedha_db

# Count deleted vs active
SELECT is_deleted, COUNT(*) FROM transactions_transaction GROUP BY is_deleted;

# View deleted transactions
SELECT id, is_deleted, description FROM transactions_transaction 
WHERE is_deleted = true LIMIT 10;
```

---

## Testing Flow Commands

```bash
# 1. SETUP
cd C:\GitHub\fedha\backend
python manage.py clear_transactions --all --force

# 2. START BACKEND
python manage.py runserver 0.0.0.0:8000

# 3. In another terminal, START APP
cd C:\GitHub\fedha\app
flutter run

# 4. IN APP: Create transactions via UI

# 5. IN APP: Delete transactions → verify they disappear

# 6. CHECK LOGS: Look for "🗑️ Syncing" messages in flutter output

# 7. VERIFY BACKEND: Run database query to confirm is_deleted=True

# 8. REFRESH APP: Delete should persist

# 9. CLEANUP FOR NEXT TEST
python manage.py clear_transactions --all --force
```

---

## Code Changes Summary (Reference)

| File | Change | Purpose |
|------|--------|---------|
| `transactions_screen.dart` | Modified `_deleteTransaction()` | Call API sync for deleted transactions |
| `unified_sync_service.dart` | Added `syncDeletedTransactions()` | Sync deletions to backend |
| `offline_data_service.dart` | Added `hardDeleteTransaction()` | Hard-delete from local DB |
| `clear_transactions.py` | Created new command | Clear database for testing |

---

## Common Issues & Fixes

| Problem | Command/Solution |
|---------|------------------|
| App not finding backend | Check IP in config, restart app |
| Transactions won't delete | Check logs: `flutter run` |
| Database full of old data | `python manage.py clear_transactions --all --force` |
| Delete appears but syncs fail | Check backend logs: `python manage.py runserver` |
| Profile not found | Get profile ID: `python manage.py clear_transactions` |

---

## File Locations

```
App Code:
- Delete logic: c:\GitHub\fedha\app\lib\screens\transactions_screen.dart
- Sync logic: c:\GitHub\fedha\app\lib\services\unified_sync_service.dart
- DB logic: c:\GitHub\fedha\app\lib\services\offline_data_service.dart

Backend:
- Clear DB: c:\GitHub\fedha\backend\transactions\management\commands\clear_transactions.py
- API: c:\GitHub\fedha\backend\transactions\views.py (batch_delete endpoint)

Docs:
- Implementation: c:\GitHub\fedha\TRANSACTION_DELETE_SYNC_FIX.md
- Testing: c:\GitHub\fedha\TRANSACTION_DELETE_SYNC_TESTING.md
```

---

## Environment Setup Reminder

```
Backend:
- Python 3.8+
- Django 4.x
- PostgreSQL running
- Virtual env activated

App:
- Flutter 3.x
- Dart 2.x
- Android device/emulator
- Network connection to backend

Testing:
- Both servers running
- Same WiFi network
- Device can reach backend IP
```

---

**All commands tested and working as of Feb 6, 2026** ✅
