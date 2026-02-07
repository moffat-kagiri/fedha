# CRUD Sync - Debug & Fix Guide

## 🔴 Critical Issue Identified

**Problem**: GET requests return empty arrays (52 bytes) even though transactions are created successfully.

**Root Cause**: `get_queryset()` was trying to access `request.user.profile`, but `request.user` **IS** the Profile itself (AUTH_USER_MODEL='accounts.Profile'). This caused an AttributeError that returned an empty queryset.

**Impact**: Users login successfully, transactions sync successfully, but GET returns empty list → UI shows no transactions.

---

## 🔧 Fixes Applied

### Fix #1: Correct User Profile Access
**File**: `backend/transactions/views.py` → `get_queryset()`

**Before** (BROKEN):
```python
try:
    user_profile = self.request.user.profile  # ❌ WRONG - causes AttributeError
except (Profile.DoesNotExist, AttributeError):
    return Transaction.objects.none()  # ❌ Returns empty, hides the bug
```

**After** (FIXED):
```python
# ✅ CRITICAL: request.user IS the Profile (custom auth model)
user_profile = self.request.user  # ✅ Correct - request.user is Profile itself

# No exception handling needed - if user is unauthenticated, permission class blocks
```

### Fix #2: Add Comprehensive Debug Logging
```python
def get_queryset(self):
    """Return transactions for current user with date filtering.
    
    CRITICAL: request.user IS the Profile (AUTH_USER_MODEL='accounts.Profile')
    NOT request.user.profile - Profile IS the custom user model itself.
    """
    user_profile = self.request.user
    profile_id = self.request.query_params.get('profile_id')
    
    # 🔍 DEBUG: Log query execution details
    print(f"\n🔍 GET /api/transactions/ EXECUTION:")
    print(f"  📱 Current user (request.user): {user_profile}")
    print(f"  📱 Current user ID: {user_profile.id if user_profile else 'None'}")
    print(f"  🔎 Query param profile_id: {profile_id}")
    
    # Filter: User's transactions that are NOT soft-deleted
    queryset = Transaction.objects.filter(profile=user_profile, is_deleted=False)
    print(f"  📊 After filter (profile={user_profile.id}, is_deleted=False): {queryset.count()} txns")
    
    # Validate profile_id parameter if provided
    if profile_id:
        if str(user_profile.id) != str(profile_id):
            print(f"  ❌ SECURITY: User {user_profile.id} != requested {profile_id}")
            return Transaction.objects.none()
        queryset = queryset.filter(profile_id=profile_id)
        print(f"  ✅ Profile validation passed")
    
    # ... rest of date filtering ...
    
    print(f"  ✅ FINAL: Returning {queryset.count()} transactions")
    return queryset
```

---

## 📋 Complete CRUD Sync Flow - With Fixes

### STEP 1: Frontend Creates Transaction (Offline)
```dart
// lib/services/offline_data_service.dart
await _offlineDataService.addTransaction(
  Transaction(
    id: uuid,
    amount: 100,
    isDeleted: false,      // ✅ Soft-delete flag
    remoteId: null,        // ✅ Will be set after sync
    isSynced: false,       // ✅ Needs sync
  )
);
```

### STEP 2: Frontend Uploads (Sync Step 1a)
```dart
// lib/services/unified_sync_service.dart - STEP 1a
final response = await _apiClient.bulkSync(profileId, transactions);
// Returns: {created_ids: [uuid1, uuid2, ...]}

// ✅ CRITICAL: Update remoteId after upload
for (var tx in transactions) {
  if (response.created_ids.contains(tx.id)) {
    await _offlineDataService.updateTransaction(
      tx.copyWith(
        remoteId: tx.id,  // ✅ Set remoteId so we can sync back
        isSynced: true     // ✅ Mark as synced
      )
    );
  }
}
```

### STEP 3: Backend Creates & Stores
```python
# backend/transactions/views.py - bulk_sync()
@action(detail=False, methods=['post'])
def bulk_sync(self, request):
    """
    Upload transactions: Creates new ones with UUIDs.
    
    Request: [
      {profile_id: uuid, amount: 100, type: 'expense', date: '...'},
      ...
    ]
    
    Response: {
      created_ids: [created_uuid1, created_uuid2, ...],  # ✅ Map to remoteId
      updated: 0,
      errors: []
    }
    """
    user_profile = request.user  # ✅ FIX: request.user IS Profile
    
    for tx_data in request.data:
        tx = Transaction.objects.create(
            profile=user_profile,          # ✅ Link to user
            amount=tx_data['amount'],
            type=tx_data['type'],
            date=tx_data['date'],
            is_deleted=False,              # ✅ Soft-delete flag
            is_synced=True,                # ✅ Server marks as synced
            # ... other fields ...
        )
    
    # Return list of created UUIDs
    return Response({'created_ids': created_ids})
```

### STEP 4: Backend GET (Returns Non-Deleted)
```python
# backend/transactions/views.py - get_queryset()
def get_queryset(self):
    """Return user's transactions, excluding soft-deleted."""
    user_profile = self.request.user  # ✅ FIX
    
    # ✅ FILTER 1: Profile ownership
    queryset = Transaction.objects.filter(
        profile=user_profile,  # ✅ Only user's transactions
        is_deleted=False       # ✅ Hide soft-deleted
    )
    
    # ✅ FILTER 2: Validate profile_id parameter
    profile_id = self.request.query_params.get('profile_id')
    if profile_id and str(user_profile.id) != str(profile_id):
        return Transaction.objects.none()  # ✅ Security check
    
    return queryset
```

### STEP 5: Frontend Downloads (Sync Step 2-3)
```dart
// lib/services/unified_sync_service.dart - STEP 2-3
// Download all transactions
final response = await _apiClient.getTransactions(profileId);

// Merge: Match by remoteId (prevents duplicates)
for (var serverTx in response.transactions) {
    // Try to find matching local transaction
    var localTx = localTransactions.firstWhere(
        (tx) => tx.remoteId == serverTx.id,
        orElse: () => null
    );
    
    if (localTx != null) {
        // ✅ Already have this - update if needed
        await _offlineDataService.updateTransaction(
            localTx.copyWith(
                amount: serverTx.amount,  // ✅ Sync server changes
                isDeleted: serverTx.isDeleted,  // ✅ Sync deletion status
                deletedAt: serverTx.deletedAt,
                isSynced: true
            )
        );
    } else {
        // ✅ New transaction from server
        await _offlineDataService.addTransaction(
            Transaction.fromJson(serverTx)
        );
    }
}
```

### STEP 6: Edit Transaction (Sync Step 1b)
```dart
// Frontend: Mark for upload
tx = tx.copyWith(amount: 150, isSynced: false);
await _offlineDataService.updateTransaction(tx);

// Backend: Update
POST /api/transactions/batch_update/
[
  {
    'id': 'remote-uuid',  // ✅ Use remoteId for updates
    'amount': 150
  }
]

// ✅ Query checks: is_deleted=False, profile matches
```

### STEP 7: Delete Transaction (Sync Step 1c)
```dart
// Frontend: Mark deleted
tx = tx.copyWith(isDeleted: true, deletedAt: now(), isSynced: false);
await _offlineDataService.updateTransaction(tx);

// Backend: Soft-delete
POST /api/transactions/batch_delete/
{
  'transaction_ids': ['remote-uuid1', ...]
}

// ✅ Sets: is_deleted=True, deleted_at=NOW()
// ✅ GET requests automatically exclude these
```

---

## ✅ Verification Checklist

### Database Level
- [ ] Run: `SELECT COUNT(*) FROM transactions WHERE is_deleted=False;`
  - Should see ~4 transactions from backend_output.txt
- [ ] Run: `SELECT * FROM transactions WHERE is_deleted=False AND profile_id='51f02462-1860-475e-bbe2-80bd129ea7a5';`
  - Should see the 4 transactions from your test
- [ ] Check: `is_deleted` column is all `f` (false)

### Backend Logging
When you run GET, you should see in console:
```
🔍 GET /api/transactions/ EXECUTION:
  📱 Current user (request.user): kagirimoffat@yahoo.com
  📱 Current user ID: 51f02462-1860-475e-bbe2-80bd129ea7a5
  🔎 Query param profile_id: 51f02462-1860-475e-bbe2-80bd129ea7a5
  📊 After filter (...): 4 txns
  ✅ Profile validation passed
  ✅ FINAL: Returning 4 transactions
```

### API Response
GET `/api/transactions/?profile_id=51f02462-1860-475e-bbe2-80bd129ea7a5`

**Before** (Broken):
```json
[]  // ❌ Empty - 52 bytes
```

**After** (Fixed):
```json
[
  {
    "id": "f3e07f0a-2267-4ac7-b206-4ad7923dd489",
    "amount": "100.00",
    "type": "expense",
    "date": "2026-02-04T19:22:20Z",
    "is_deleted": false,
    "is_synced": true,
    ...
  },
  ...
]  // ✅ 4 transactions
```

---

## 🛠️ Step-by-Step Fix Procedure

### 1. Verify Database State
```bash
# Login to PostgreSQL
psql -U postgres -d fedha_db

# Check transactions table structure
\d transactions

# Check soft-delete column
SELECT 
    id, amount, type, category, 
    is_synced, is_deleted, profile_id
FROM transactions 
WHERE profile_id='51f02462-1860-475e-bbe2-80bd129ea7a5'
ORDER BY created_at DESC
LIMIT 10;
```

**Expected**:
- `is_deleted` column exists and shows `f` (false)
- `profile_id` matches your test user ID
- `is_synced` is `t` (true) after upload

### 2. Test Backend GET Directly
```bash
# Terminal 1: Start backend
cd backend/
python manage.py runserver 0.0.0.0:8000

# Terminal 2: Login and get token
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"kagirimoffat@yahoo.com","password":"..."}'

# Copy the access token from response

# Terminal 2: Test GET
curl -X GET "http://localhost:8000/api/transactions/?profile_id=51f02462-1860-475e-bbe2-80bd129ea7a5" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Should NOT be empty []
```

**Expected Response**: Array with 4 transactions, NOT `[]`

### 3. Add Detailed Logging (Already Done)
The fix includes comprehensive logging. Check console output for the 🔍 debug messages.

### 4. Test Each CRUD Operation

#### CREATE
```bash
POST /api/transactions/bulk_sync/
[
  {
    "profile_id": "51f02462-1860-475e-bbe2-80bd129ea7a5",
    "amount": 500,
    "type": "expense",
    "category": "food",
    "date": "2026-02-06T12:00:00Z",
    "status": "completed"
  }
]

# ✅ Check response: {created_ids: [...]}
```

#### READ
```bash
GET /api/transactions/?profile_id=51f02462-1860-475e-bbe2-80bd129ea7a5

# ✅ Check response: Array with transactions, NOT []
# ✅ Check each has is_deleted=false
```

#### UPDATE
```bash
POST /api/transactions/batch_update/
[
  {
    "id": "f3e07f0a-2267-4ac7-b206-4ad7923dd489",
    "amount": 150
  }
]

# ✅ Check: {success: true, updated: 1}
# ✅ GET should reflect new amount
```

#### DELETE
```bash
POST /api/transactions/batch_delete/
{
  "transaction_ids": ["f3e07f0a-2267-4ac7-b206-4ad7923dd489"]
}

# ✅ Check: {success: true, deleted: 1, soft_deleted: 1}
# ✅ Check DB: is_deleted=true, deleted_at set
# ✅ GET should NOT include it anymore
```

---

## 🚀 Quick Restart Procedure

```bash
# 1. Stop any running servers
# Ctrl+C in terminals

# 2. Pull latest code (fixes already applied)
cd c:\GitHub\fedha

# 3. Restart backend with fresh state
cd backend/
python manage.py runserver 0.0.0.0:8000

# 4. In separate terminal, test:
curl -X GET "http://localhost:8000/api/transactions/?profile_id=YOUR_PROFILE_ID" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 5. Check console output for 🔍 debug messages
```

---

## 🔍 Common Issues & Solutions

### Issue: GET still returns empty array
**Check**:
1. Are debug messages printing? (If not, fix wasn't applied)
2. What does profile_id show in logs? (Should match user ID)
3. What does transaction count show after filter? (Should be > 0)

**Solutions**:
- Verify you edited the right file: `backend/transactions/views.py`
- Verify line ~50 says `user_profile = self.request.user` (not `.profile`)
- Restart backend after changes
- Check database directly: `SELECT COUNT(*) FROM transactions WHERE profile_id='...' AND is_deleted=false;`

### Issue: Profile validation fails
**Symptom**: Logs show "SECURITY: User X != requested Y"
**Cause**: Frontend sending wrong profile_id in query
**Solution**: Verify frontend passes correct profile_id from login response

### Issue: Soft-delete not working
**Symptom**: Deleted transactions still appear in GET
**Cause**: is_deleted column not properly set or missing
**Solution**: 
```bash
SELECT is_deleted FROM transactions LIMIT 1;
# If column doesn't exist: python manage.py migrate
```

### Issue: batch_update/batch_delete fail
**Symptom**: API returns 500 error
**Cause**: Usually transaction not found or permission denied
**Solution**:
- Verify transaction exists: `SELECT id FROM transactions WHERE id='...'`
- Verify profile matches: `SELECT profile_id FROM transactions WHERE id='...';`
- Check server logs for actual error

---

## 📊 Data Flow Summary

```
Create (STEP 1a)
  ↓
Frontend: Add TX locally + queue for sync
  ↓
POST /bulk_sync/ → Backend creates with UUID
  ↓
Response: {created_ids: [uuid]}
  ↓
Frontend: Sets remoteId = uuid, isSynced = true
  ↓
[sync completes, TX has remoteId pointing to server]

Get (STEP 2-3)
  ↓
Frontend: Next sync, download all
  ↓
GET /transactions/ + is_deleted=False filter
  ↓
Backend: Returns only non-deleted, user's TXs
  ↓
Frontend: Merges by remoteId (no duplicates)
  ↓
[UI shows all non-deleted transactions]

Edit (STEP 1b)
  ↓
Frontend: User edits, marks isSynced=false
  ↓
POST /batch_update/ with remoteId
  ↓
Backend: Finds by UUID, updates, sets updated_at
  ↓
Frontend: isSynced=true after response
  ↓
[next GET includes updated values]

Delete (STEP 1c)
  ↓
Frontend: Mark isDeleted=true, isSynced=false
  ↓
POST /batch_delete/ with remoteId
  ↓
Backend: Sets is_deleted=True, deleted_at=NOW()
  ↓
Frontend: Remove from local DB
  ↓
[next GET automatically excludes via is_deleted filter]
```

---

## 🎯 Expected Test Results

After applying fixes:

| Operation | Frontend | Backend | Result |
|-----------|----------|---------|--------|
| Login | ✅ Succeed | ✅ JWT issued | Token received |
| Create TX (sync) | ✅ Add locally | ✅ Create + UUID | remoteId set |
| GET /transactions/ | ✅ Request sent | ✅ Filter + return | 4+ transactions |
| Edit TX (sync) | ✅ Mark dirty | ✅ Update | Changes visible |
| Delete TX (sync) | ✅ Mark deleted | ✅ Soft-delete | Excluded from GET |

---

## 📝 Notes for Frontend Integration

### Key Points
1. **remoteId Tracking**: After upload, ALWAYS set remoteId to match server UUID
2. **Profile ID**: Keep it after login, use in all subsequent requests
3. **Soft Delete**: isDeleted flag is local - backend determines actual deletion
4. **Sync Merging**: Match by remoteId, not local id, to prevent duplicates
5. **Get Filtering**: Backend filters is_deleted=False, so deleted TXs disappear automatically

### Example Frontend Flow
```dart
// After login
profileId = loginResponse.profile.id;  // Save this

// After creating TX
tx = Transaction(...);
await offline.addTransaction(tx);

// Next sync
POST /bulk_sync/ with transaction
Response: {created_ids: [uuid]}

// Update local
tx.remoteId = uuid;
tx.isSynced = true;
await offline.updateTransaction(tx);

// Later: Get all
GET /transactions/?profile_id=$profileId

// Response is only non-deleted TXs (backend filtered)
```

---

## 🎓 Why This Architecture Works

1. **Profile Scoping**: All queries filtered by profile → Multi-user safe
2. **Soft Delete**: Data preserved → Audit trail, recovery possible
3. **RemoteId Tracking**: Frontend knows which local TX = which server UUID → No re-uploads
4. **Automatic Filtering**: GET excludes soft-deleted → UI stays clean
5. **Idempotent**: Can retry failed syncs safely → Network reliability
6. **Offline-First**: All operations work offline, sync when ready → Great UX

---

## ✨ Summary

**Fixed**: `get_queryset()` now correctly accesses `request.user` as Profile
**Added**: Comprehensive debug logging at every step
**Result**: GET will return transactions instead of empty array
**Next**: Test CREATE → READ → UPDATE → DELETE flow end-to-end

All CRUD operations are now properly integrated with soft-delete and sync architecture.
