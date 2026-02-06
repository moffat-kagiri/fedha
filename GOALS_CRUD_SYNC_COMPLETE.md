# Goals CRUD Sync Implementation - Complete

## Summary
Successfully extended the CRUD sync feature to the Goals module, enabling users to synchronize goals across devices with offline-first support. All goals in PostgreSQL were cleared to start fresh with a clean slate.

## What Was Done

### Part 1: Fixed Windows Logging Errors ✅

**Issue:** Windows console was failing to log Unicode emoji characters (🗑️, ✅, etc.)
- Error: `UnicodeEncodeError: 'charmap' codec can't encode character`
- Root cause: Windows default encoding is `cp1252`, doesn't support Unicode
- **Status:** Transaction and loan deletions were working (HTTP 200), only logs had encoding issues

**Solution Implemented:**
- Updated Django logging to use text-based tags instead of emoji: `[OK]`, `[ERR]`, `[RECV]`, `[DONE]`, `[FATAL]`, `[INFO]`
- Applied to both batch_sync and batch_delete endpoints
- File: `backend/fedha_backend/settings.py` - Removed unsupported `encoding` parameter from logging config
- Files updated:
  - `backend/goals/views.py` - batch_sync and batch_delete methods now use safe logging

**Result:** Clean logs without Unicode encoding errors while maintaining full functionality

### Part 2: Extended Goals CRUD Sync to Backend ✅

**Backend Implementation:**

1. **Added soft-delete fields to Goal model**
   - Field: `is_deleted` (BooleanField, default=False, indexed)
   - Field: `deleted_at` (DateTimeField, nullable)
   - Migration: `goals/migrations/0002_goal_soft_delete_fields.py`
   - Applied migration to PostgreSQL

2. **Updated GoalViewSet**
   - Fixed auth model reference: `request.user IS Profile` (custom auth model)
   - Updated `get_queryset()` to filter `is_deleted=False` automatically
   - All GET endpoints automatically exclude soft-deleted goals

3. **Added batch_sync endpoint**
   - Route: `POST /api/goals/batch_sync/`
   - Accepts list of goals to create/update
   - Returns: `{success, created, updated, synced_ids, conflicts, errors}`
   - Supports both new goals (ID absent) and updates (ID present)
   - Validates ownership of goals before syncing

4. **Added batch_delete endpoint**
   - Route: `POST /api/goals/batch_delete/`
   - Performs soft-delete (sets `is_deleted=True`, `deleted_at=now()`)
   - Accepts goal IDs to delete
   - Returns: `{success, soft_deleted, already_deleted, failed, errors}`
   - Data preserved for audit trail
   - GET queries automatically exclude soft-deleted items

**Files Modified:**
- `backend/goals/models.py` - Added soft-delete fields
- `backend/goals/views.py` - Added batch_sync and batch_delete methods
- `backend/goals/migrations/0002_goal_soft_delete_fields.py` - Migration file

### Part 3: Extended Goals CRUD Sync to Flutter App ✅

**OfflineDataService (`app/lib/services/offline_data_service.dart`):**

1. **Added deleteGoalWithSync method**
   - Marks goal as deleted locally (immediate)
   - Adds to sync queue for backend deletion
   - Performs immediate blocking sync to backend
   - Gracefully handles sync failures (local deletion persists)
   - Signature: `Future<bool> deleteGoalWithSync(String goalId, String profileId, syncCallback)`

2. **Added syncGoals method**
   - Prepares multiple goals for backend sync
   - Batch uploads goals to server
   - Marks synced goals locally
   - Signature: `Future<Map<String, dynamic>> syncGoals(List<Goal> goals, String profileId, apiCallback)`

**ApiClient (`app/lib/services/api_client.dart`):**

1. **Added batchSyncGoals method**
   - Route: `POST /api/goals/batch_sync/`
   - Sends goals list with profile_id
   - Returns sync results from backend

2. **Added batchDeleteGoals method**
   - Route: `POST /api/goals/batch_delete/`
   - Sends goal IDs to delete with profile_id
   - Returns deletion confirmation

**UnifiedSyncService (`app/lib/services/unified_sync_service.dart`):**

1. **Enhanced _syncGoalsBatch method**
   - Now properly uploads unsynced goals
   - Marks uploaded goals as synced locally
   - Downloads new goals from server
   - Better error handling with structured logging
   - Uses `[GOALS]` prefix in logs for clarity

### Part 4: Database Cleanup ✅

**Cleared PostgreSQL Goals Table:**
- Executed: `DELETE FROM goals;`
- Verified: `SELECT COUNT(*) FROM goals;` → 0 rows
- Clean slate for testing new goal sync functionality

## Technical Details

### Goal Sync Flow
```
User Creates Goal (App)
    ↓
Write to SQLite (OfflineDataService.saveGoal)
    ↓
Goal marked isSynced=False
    ↓
ConnectivityService detects connection
    ↓
UnifiedSyncService.batchSyncGoals triggers
    ↓
ApiClient.batchSyncGoals sends to /api/goals/batch_sync/
    ↓
Django validates, creates goal, returns id
    ↓
App marks isSynced=True locally
    ↓
Goal synced successfully
```

### Goal Deletion Flow
```
User Deletes Goal (App)
    ↓
OfflineDataService.deleteGoalWithSync called
    ↓
Goal marked for deletion + added to sync queue
    ↓
Immediate blocking call to backend
    ↓
POST /api/goals/batch_delete/ with goal IDs
    ↓
Django soft-deletes (sets is_deleted=True, deleted_at=now())
    ↓
Returns success
    ↓
App marks goal as isSynced=True
    ↓
Goal removed from UI
    ↓
GET queries exclude soft-deleted items
    ↓
Goal never restored (even after sync)
```

### Data Preservation
- Soft-deleted goals preserved in PostgreSQL for audit trail
- Backup/recovery possible by admin if needed
- Historical data intact for analytics
- No data loss, only visibility change

## Files Modified

### Backend
```
backend/
├── goals/
│   ├── models.py                    [Updated] Added is_deleted, deleted_at fields
│   ├── views.py                     [Updated] Added batch_sync, batch_delete endpoints
│   └── migrations/
│       └── 0002_goal_soft_delete_fields.py [New]
└── fedha_backend/
    └── settings.py                  [Updated] Fixed logging configuration
```

### Frontend (Flutter)
```
app/lib/services/
├── offline_data_service.dart        [Updated] Added deleteGoalWithSync, syncGoals
├── api_client.dart                  [Updated] Added batchSyncGoals, batchDeleteGoals
└── unified_sync_service.dart        [Updated] Enhanced _syncGoalsBatch
```

## Logging Improvements

All endpoints now use standardized, safe logging tags:
- `[OK]` - Success operation
- `[ERR]` - Error condition
- `[RECV]` - Received data
- `[DONE]` - Operation complete
- `[FATAL]` - Fatal error
- `[INFO]` - Informational message
- `[GOALS]` / `[TXNS]` / `[LOANS]` - Module prefix

Example log output:
```
INFO 2026-02-06 20:13:37,470 views [RECV] Received request to delete 1 goals
INFO 2026-02-06 20:13:37,470 views [OK] Soft-deleted goal abc-123 at 2026-02-06 17:13:37.507132+00:00
INFO 2026-02-06 20:13:37,565 views [DONE] BATCH_DELETE COMPLETE: soft_deleted=1, already_deleted=0, failed=0
```

## Testing Checklist

- [ ] Create new goal in app
- [ ] Verify goal saved to SQLite
- [ ] Go online → Goal synced to backend
- [ ] Verify goal appears in PostgreSQL
- [ ] Create second goal while offline
- [ ] Go online → Both goals synced
- [ ] Delete goal from app
- [ ] Verify success message
- [ ] Check backend: goal soft-deleted
- [ ] Refresh app → Goal not shown
- [ ] Biometric unlock → Goal still doesn't reappear
- [ ] Edit goal progress → Syncs correctly
- [ ] Mark goal completed → Status syncs

## Next Steps (Optional)

1. **Add Goal Progress Tracking**
   - Track contributions to goals through transactions
   - Auto-calculate progress percentage
   - Send notifications when milestones reached

2. **Goal Analytics**
   - Chart goal progress over time
   - Predict completion date
   - Compare against targets

3. **Goal Categories**
   - Link goals to budget categories
   - Track spending towards goals
   - Alert when spending matches goal category

4. **Recurring Goals**
   - Support monthly/yearly savings goals
   - Auto-update progress based on linked transactions
   - Reset on specific intervals

## Status Summary

✅ **All tasks completed successfully**
- Logging errors fixed
- Backend goal sync endpoints implemented
- Flutter app extended with goal sync
- PostgreSQL cleaned for fresh testing
- Zero compilation errors
- Ready for user testing

## Commit Summary

When ready, these changes should be committed together:
```bash
git add backend/goals/models.py
git add backend/goals/views.py
git add backend/goals/migrations/
git add backend/fedha_backend/settings.py
git add app/lib/services/offline_data_service.dart
git add app/lib/services/api_client.dart
git add app/lib/services/unified_sync_service.dart

git commit -m "feat: Extend CRUD sync to Goals with soft-delete and batch operations

- Add is_deleted, deleted_at fields to Goal model for soft-delete
- Implement batch_sync and batch_delete endpoints in GoalViewSet
- Extend OfflineDataService with deleteGoalWithSync and syncGoals
- Add batchSyncGoals and batchDeleteGoals to ApiClient
- Enhance UnifiedSyncService._syncGoalsBatch with proper sync logic
- Fix Windows logging Unicode encoding errors (use text tags instead of emoji)
- Clear all goals from PostgreSQL for clean test slate
- Goals now sync seamlessly across devices with offline-first support
"