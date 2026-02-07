# CRUD Sync - Critical Issues & Fix Checklist

## 🔴 Critical Bug Found

**Issue**: GET requests return empty arrays despite successful transaction creation

**Root Cause**: Line 44-48 in `backend/transactions/views.py` tried to access `request.user.profile`, but `request.user` **IS** the Profile (custom auth model). This caused silent AttributeError, returning empty queryset.

**Status**: ✅ **FIXED** - Updated views.py with correct logic + debug logging

---

## ✅ Completed Fixes

### ✅ Fix 1: Correct User Profile Access

- **File**: `backend/transactions/views.py` line ~44
- **Change**: Removed `request.user.profile` (wrong) → Use `request.user` directly (correct)
- **Why**: AUTH_USER_MODEL = 'accounts.Profile', so request.user IS the Profile

### ✅ Fix 2: Added Debug Logging

- **File**: `backend/transactions/views.py` get_queryset() method
- **Added**: Print statements showing:
  - Current user ID
  - Query parameter profile_id
  - Transaction count at each filter stage
  - Final transaction count

**Expected Console Output**:

```
🔍 GET /api/transactions/ EXECUTION:
  📱 Current user ID: 51f02462-1860-475e-bbe2-80bd129ea7a5
  🔎 Query param profile_id: 51f02462-1860-475e-bbe2-80bd129ea7a5
  📊 After filter: 4 txns
  ✅ FINAL: Returning 4 transactions
```

---

## 📋 What Needs to Happen Before CRUD Works

### 1. ✅ BACKEND CHANGES (DONE)

- [X] Fix get_queryset() to use request.user (not request.user.profile)
- [X] Add comprehensive debug logging
- [X] Soft-delete fields already added (is_deleted, deleted_at)
- [X] batch_update() and batch_delete() already implemented

### 2. 🔄 DATABASE (ACTION REQUIRED)

```bash
# Check if soft-delete columns exist
psql -U postgres -d fedha_db
SELECT column_name FROM information_schema.columns 
WHERE table_name='transactions' AND column_name IN ('is_deleted', 'deleted_at');
```

**If columns don't exist**, run migration:

```bash
cd backend/
python manage.py makemigrations transactions
python manage.py migrate
```

**If columns DO exist**, check their values:

```sql
SELECT id, amount, is_deleted, deleted_at 
FROM transactions 
WHERE profile_id='51f02462-1860-475e-bbe2-80bd129ea7a5'
LIMIT 5;
```

Expected: `is_deleted` = `f` (false), `deleted_at` = NULL

### 3. 🧪 TESTING (ACTION REQUIRED)

#### Test 1: Backend GET Returns Data

```bash
# Terminal: Start backend
cd backend/
python manage.py runserver 0.0.0.0:8000

# Another Terminal: Login
PROFILE_ID="51f02462-1860-475e-bbe2-80bd129ea7a5"
EMAIL="kagirimoffat@yahoo.com"
PASSWORD="your_password"

curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}"

# Copy 'access' token from response

# Test GET (replace with actual token)
curl -X GET "http://localhost:8000/api/transactions/?profile_id=$PROFILE_ID" \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

**Expected Result**:

```json
[
  {
    "id": "f3e07f0a-2267-4ac7-b206-4ad7923dd489",
    "amount": "100.00",
    "type": "expense",
    "is_deleted": false,
    ...
  },
  {
    "id": "a4bd27bc-4581-4115-a503-e4be10e9dfbe",
    "amount": "50050.00",
    "type": "income",
    "is_deleted": false,
    ...
  },
  ...
]
```

**NOT**: `[]` (empty array)

**Check Console**: Should see 🔍 debug messages showing filter progression

#### Test 2: Edit Transaction

```bash
curl -X POST http://localhost:8000/api/transactions/batch_update/ \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{"id":"f3e07f0a-2267-4ac7-b206-4ad7923dd489","amount":"200"}]'
```

**Expected**: `{success: true, updated: 1}`

#### Test 3: Delete Transaction

```bash
curl -X POST http://localhost:8000/api/transactions/batch_delete/ \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"transaction_ids":["f3e07f0a-2267-4ac7-b206-4ad7923dd489"]}'
```

**Expected**: `{success: true, deleted: 1, soft_deleted: 1}`

Then GET again:

```bash
curl -X GET "http://localhost:8000/api/transactions/?profile_id=$PROFILE_ID" \
  -H "Authorization: Bearer TOKEN"
```

**Expected**: Transaction no longer in list (is_deleted filter excludes it)

### 4. 🔄 FRONTEND (ACTION REQUIRED)

After backend is fixed and tested, frontend needs:

#### ✅ Already Done

- [X] Transaction.dart has isDeleted, deletedAt fields
- [X] unified_sync_service.dart has STEP 1c delete logic
- [X] Models can handle soft-delete

#### ⚠️ Needs Verification

- [X] Run `dart run build_runner build` to regenerate .g.dart files
- [X] Verify apiClient has:
  - `deleteTransactions()` method
  - `updateTransactions()` method
  - `bulkSync()` method with correct response parsing
- [ ] Verify sync service properly sets remoteId after bulk_sync upload
- [ ] Test fresh build: `flutter clean && flutter pub get && flutter run -d android`

#### 🎯 Critical Frontend Logic

Frontend **must** track remoteId correctly:

```dart
// After POST /bulk_sync/ succeeds
response.created_ids.forEach((serverId) {
  // Find matching local TX by index/date/amount
  localTx.remoteId = serverId;  // ✅ CRITICAL
  localTx.isSynced = true;
  save(localTx);
});

// For GET /transactions
GET returns: [{id: uuid, ...}]
// Frontend must match to local by:
// 1. First check: Match by remoteId (already synced)
// 2. Then: Match by amount + date (freshly created)
// Result: No duplicates
```

---

## 🚨 The Real Issue (Explained)

### What Was Happening

```
1. POST /bulk_sync/ → ✅ Creates 4 transactions on backend ✅
2. GET /transactions/ → ❌ Returns []  ❌  (empty)
3. User sees nothing on UI ❌
```

### Why It Happened

```python
# OLD CODE (Line 44-48 in views.py):
def get_queryset(self):
    try:
        user_profile = self.request.user.profile  # ❌ WRONG
        # request.user IS Profile, not User with Profile
    except AttributeError:
        return Transaction.objects.none()  # ❌ Silent failure
```

**Result**: Exception silently caught, returns empty queryset → Frontend gets `[]`

### What's Fixed

```python
# NEW CODE:
def get_queryset(self):
    user_profile = self.request.user  # ✅ CORRECT
    # No exception, proceeds normally
  
    queryset = Transaction.objects.filter(
        profile=user_profile,
        is_deleted=False
    )
    # ✅ Returns actual transactions
```

**Result**: Exception never happens, queries work correctly → Frontend gets transaction data

---

## 🔄 Complete CRUD Workflow (With Fixes)

### CREATE

```
Frontend: User creates TX → Saved locally with isSynced=false
Next sync: POST /bulk_sync/ with [tx1, tx2, ...]
Backend: Creates with UUID, returns {created_ids: [uuid1, uuid2]}
Frontend: Sets remoteId=uuid, isSynced=true
Result: ✅ TX synced, ready for READ/UPDATE/DELETE
```

### READ

```
Frontend: User views transactions
Sync service: GET /transactions/?profile_id=XXX
Backend: Query executes with filters:
  - profile=user_profile ✅ (Only this user's data)
  - is_deleted=False ✅ (Only non-deleted)
Returns: [tx1, tx2, tx3, ...]
Frontend: Merges with local (by remoteId), no duplicates
Result: ✅ User sees all transactions
```

### UPDATE

```
Frontend: User edits amount
  - Mark isSynced=false
  - Keep remoteId set
Next sync: POST /batch_update/ with [
  {id: remoteId, amount: 150}
]
Backend: Finds TX by remoteId (UUID), updates
Returns: {success: true, updated: 1}
Frontend: Mark isSynced=true
Result: ✅ Change synced to backend
```

### DELETE

```
Frontend: User deletes TX
  - Mark isDeleted=true
  - Mark isSynced=false  
  - Keep remoteId set
Next sync: POST /batch_delete/ with [remoteId1, ...]
Backend: Soft-delete TX (is_deleted=True, deleted_at=NOW())
Returns: {success: true, deleted: 1}
Frontend: Remove from local DB
Next GET: Excluded via is_deleted=False filter
Result: ✅ TX deleted everywhere
```

---

## ✅ Verification Checklist

- [ ] **Database**: `is_deleted` column exists and is `false` for your test TXs
- [ ] **Backend**: Restarted after code changes (to reload views.py)
- [ ] **Test GET**: Returns JSON array with 4+ transactions, NOT empty
- [ ] **Console**: Sees 🔍 debug messages when GET is called
- [ ] **Test CREATE**: POST /bulk_sync/ returns created_ids
- [ ] **Test UPDATE**: batch_update works and changes are visible in next GET
- [ ] **Test DELETE**: batch_delete soft-deletes and GET excludes it
- [ ] **Frontend**: Regenerated models with `dart run build_runner build`
- [ ] **Frontend**: Fresh build succeeds: `flutter clean && flutter pub get`
- [ ] **Frontend**: Login works and shows transactions (not empty)
- [ ] **End-to-End**: Create → Sync → GET → Edit → Sync → GET → Delete → Sync → GET all work

---

## 🆘 Troubleshooting

### GET still returns empty array

**Checklist**:

1. [ ] Did you save the views.py file?
2. [ ] Did you restart backend server?
3. [ ] Check database: `SELECT COUNT(*) FROM transactions WHERE is_deleted=false;`
4. [ ] Check console: Are you seeing 🔍 messages? If not, fix wasn't applied.
5. [ ] Check profile_id in URL matches user's profile from login

### POST /bulk_sync works but GET empty

**Analysis**:

- This means creation works but retrieval broken
- Database likely has the data (check with `psql`)
- Issue is in get_queryset() filter logic
- Verify line says: `user_profile = self.request.user` (not `.profile`)

### batch_update returns errors

**Check**:

- Is transaction ID actually a UUID from a previous GET?
- Does profile_id match the user?
- Is transaction already soft-deleted? (is_deleted=true)

### batch_delete returns 500

**Likely**:

- Transaction ID format wrong (should be UUID)
- Transaction doesn't exist
- Check server logs for actual error

---

## 🎯 Success Criteria

After all fixes and tests:

✅ **Backend GET returns transactions** (not empty array)
✅ **Create, Read, Update, Delete all work**
✅ **Soft-deleted transactions excluded from GET**
✅ **Console shows 🔍 debug messages with transaction counts**
✅ **Frontend rebuilds and runs without errors**
✅ **App shows transactions after login** (not empty)
✅ **Edit and delete sync back to backend**
✅ **Fresh app install doesn't re-download deleted transactions**

---

## 📞 Quick Reference

| Task             | Command                                                                                          | Expected                     |
| ---------------- | ------------------------------------------------------------------------------------------------ | ---------------------------- |
| Check DB columns | `psql ... SELECT column_name FROM information_schema.columns WHERE table_name='transactions';` | is_deleted, deleted_at exist |
| Check DB data    | `SELECT count(*) FROM transactions WHERE is_deleted=false;`                                    | > 0                          |
| Test backend GET | `curl ... /api/transactions/?profile_id=...`                                                   | Array with data, not `[]`  |
| Check logs       | Console when running `python manage.py runserver`                                              | 🔍 messages appear           |
| Rebuild frontend | `dart run build_runner build`                                                                  | No errors                    |
| Fresh build      | `flutter clean && flutter pub get && flutter run`                                              | App launches                 |

---

**Status**: Core fix applied. Now requires database verification, backend testing, and frontend rebuild to confirm CRUD works end-to-end.
