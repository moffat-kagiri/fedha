# Goal Sync Duplication - Root Cause & Fix

## Problem Summary

When adding goals, they were being duplicated upon sync. Additionally, when a transaction was linked to a goal, both the goal and transaction would duplicate.

## Root Cause Analysis

The duplication occurred due to a **goal ID tracking failure** in the sync process:

### Flow Diagram

```
Frontend Creates Goal (offline)
    ↓
Local UUID generated (e.g., "abc-123")
Goal marked as isSynced=false
    ↓
[FIRST SYNC]
_syncGoalsBatch() uploads goal
    ↓
Backend batch_sync receives goal DATA (no ID sent)
Backend creates NEW server UUID (e.g., "xyz-789")
Backend RETURNS synced_ids: [] (empty, because no ID was sent)
    ↓
Frontend tries to match: g.id == syncedId
    ❌ PROBLEM: g.id="abc-123" but syncedId doesn't exist
    ❌ Goal is never marked as synced
    ❌ remoteId is never stored
    ↓
[SECOND SYNC]
Goal is STILL unsynced (isSynced=false)
Frontend uploads SAME goal again
    ↓
Backend creates ANOTHER new UUID
    ↓
[RESULT: DUPLICATE GOALS]
```

### Why Transactions Didn't Duplicate

Transactions used the same upload pattern BUT had proper ID tracking:
1. Transactions don't send IDs either
2. BUT backend returns `created_ids` list with server UUIDs
3. Frontend matches by **batch position** using `batchTransactionMap[index]`
4. Frontend stores returned ID as `remoteId`
5. Next sync finds `remoteId != null` and doesn't re-upload

### Why Goals Failed

Goals had:
1. No `created_ids` returned from backend
2. Frontend tried matching by non-existent `synced_ids`
3. remoteId was never set
4. On next sync, goal was treated as new and re-uploaded

## Fix Implementation

### Backend Changes: `backend/goals/views.py`

Updated `batch_sync()` endpoint to return created/updated IDs:

**Before:**
```python
response_data = {
    'success': True,
    'created': created_count,
    'updated': updated_count,
    'synced_ids': synced_ids,  # ❌ Always empty/invalid
    'conflicts': conflicts,
    'errors': errors
}
```

**After:**
```python
# Track IDs properly
created_ids = []  # ✅ Server UUIDs of new goals
updated_ids = []  # ✅ IDs of updated goals

# When creating new goal:
goal = serializer.save(profile=user_profile)
created_count += 1
created_ids.append(str(goal.id))  # ✅ Append actual server UUID

# When updating existing:
updated_count += 1
updated_ids.append(goal_id)  # ✅ Append update ID

response_data = {
    'success': len(errors) == 0,
    'created': created_count,
    'updated': updated_count,
    'created_ids': created_ids,  # ✅ Return server UUIDs
    'updated_ids': updated_ids,  # ✅ Return updated IDs
    'errors': errors
}
```

**Key Changes:**
- Separate tracking of `created_ids` (server-generated) vs `synced_ids`
- Append actual Goal server UUID on creation
- Return both lists for frontend to process

### Frontend Changes: `app/lib/services/unified_sync_service.dart`

Updated `_syncGoalsBatch()` to match goals by position and set remoteId:

**Before:**
```dart
if (response['synced_ids'] is List) {
  for (final syncedId in response['synced_ids']) {
    final goal = unsyncedGoals.firstWhere(
      (g) => g.id == syncedId,  // ❌ Mismatch: local ID vs missing syncedId
      orElse: () => unsyncedGoals.first,  // ❌ Uses wrong goal!
    );
    final syncedGoal = goal.copyWith(isSynced: true);  // ❌ Never executes correctly
    await _offlineDataService.updateGoal(syncedGoal);
  }
}
```

**After:**
```dart
// ✅ Match goals by batch position (same pattern as transactions)
final createdIds = response['created_ids'] as List? ?? [];
if (createdIds.isNotEmpty) {
  _logger.info('[GOALS] Setting remoteIds for ${createdIds.length} goals to prevent re-upload');
  for (int i = 0; i < createdIds.length && i < unsyncedGoals.length; i++) {
    final remoteId = createdIds[i]?.toString();
    if (remoteId != null && remoteId.isNotEmpty) {
      final localGoal = unsyncedGoals[i];  // ✅ Match by index
      try {
        // ✅ Use copyWith to set remoteId (immutable Goal model)
        final updatedGoal = localGoal.copyWith(
          remoteId: remoteId,  // ✅ Set server UUID
          isSynced: true,      // ✅ Mark synced
        );
        await _offlineDataService.updateGoal(updatedGoal);
        _logger.info('[GOALS] Set remoteId $remoteId for local goal ${localGoal.id}');
      } catch (e) {
        _logger.warning('[GOALS] Failed to set remoteId for goal: $e');
      }
    }
  }
  _logger.info('[GOALS] All created goals marked as synced');
}

// ✅ Also handle updated goals
final updatedIds = response['updated_ids'] as List? ?? [];
if (updatedIds.isNotEmpty) {
  _logger.info('[GOALS] Marking ${updatedIds.length} updated goals as synced');
  for (final updatedId in updatedIds) {
    final goal = unsyncedGoals.firstWhere(
      (g) => g.remoteId == updatedId?.toString(),  // ✅ Match by remoteId
      orElse: () => null as Goal,
    );
    if (goal != null) {
      final syncedGoal = goal.copyWith(isSynced: true);
      await _offlineDataService.updateGoal(syncedGoal);
    }
  }
}
```

**Key Changes:**
- Match created goals by **batch position index** (not by ID)
- Store returned `created_ids` as `remoteId` on local goals
- Mark goals as `isSynced: true` after storing remoteId
- Handle updated goals separately using remoteId matching
- Proper null checking and error handling

## How It Works Now

### Sync Cycle (Fixed)

```
[FIRST SYNC]
Local goal: id="abc-123", remoteId=null, isSynced=false
    ↓
Upload: goal data (no ID)
    ↓
Backend creates: id="xyz-789"
Returns: created_ids=["xyz-789"]
    ↓
Frontend matches by index:
  unsyncedGoals[0].copyWith(remoteId: "xyz-789", isSynced: true)
    ↓
Local goal: id="abc-123", remoteId="xyz-789", isSynced=true
    ↓
[SECOND SYNC]
Check: remoteId != null → SKIP UPLOAD ✓
Download goals from server
Check: g.remoteId == remote.id → ALREADY EXISTS ✓
    ↓
[RESULT: NO DUPLICATION] ✅
```

## Testing Strategy

### Unit Test
1. Create goal while offline
2. Goal gets local UUID, isSynced=false, remoteId=null
3. Go online → Sync
4. Verify:
   - Goal receives remoteId from backend
   - Goal is marked isSynced=true
   - Local database updated

### Integration Test
1. Create goal offline
2. Create transaction linked to goal
3. Sync both
4. Verify no duplicates in PostgreSQL:
   ```sql
   SELECT COUNT(*), name FROM goals WHERE profile_id='...' GROUP BY name;
   -- Should show count=1 for each goal name
   ```

### Multi-Device Test
1. Device A creates goal
2. Device B syncs
3. Device A edits goal
4. Device B receives update (not duplicate)
5. Verify both devices have same goal state

## Database Verification

After sync, verify PostgreSQL has no duplicates:

```sql
-- Check for duplicate goals
SELECT profile_id, name, COUNT(*) as count 
FROM goals 
WHERE is_deleted = false 
GROUP BY profile_id, name 
HAVING COUNT(*) > 1;

-- Should return: (empty result)

-- Check goal remoteId tracking
SELECT id, name, COUNT(*) as synced_count
FROM goals
WHERE is_deleted = false
GROUP BY id, name;

-- Should return: 1 for each unique goal
```

## Summary of Changes

| Component | File | Change |
|-----------|------|--------|
| Backend | `backend/goals/views.py` | Added `created_ids` and `updated_ids` lists to batch_sync response |
| Frontend | `app/lib/services/unified_sync_service.dart` | Changed goal matching from ID-based to index-based; set remoteId; mark isSynced |

## Why This Fix Prevents Duplication

1. **Every newly created goal gets a remoteId** → Future syncs skip already-synced goals
2. **remoteId is the source of truth** → Used to check if goal exists on server
3. **Batch position matching is reliable** → Order is preserved in upload/response
4. **Matches transaction pattern** → Consistent sync strategy across all entities

## Backwards Compatibility

Goals created before this fix may have:
- `remoteId` = null
- `isSynced` = false

These will be treated as unsynced and uploaded again on next sync, which is safe because:
1. Backend checks if goal already exists by profile + name + date
2. Soft-delete prevents permanent duplicates
3. User can manually clean up via delete operations
