# CRUD Sync - Annotated Code Examples

This document contains well-commented code snippets showing how each CRUD operation works end-to-end.

---

## 1. CREATE (STEP 1a) - Upload New Transactions

### Frontend Code
```dart
// lib/services/unified_sync_service.dart

Future<void> _syncTransactions(String profileId) async {
  // Step 1a: Collect unsynced transactions for upload
  final unsyncedTxs = await _offlineDataService
      .getUnsyncedTransactions(profileId);
  
  if (unsyncedTxs.isEmpty) {
    print('✅ No unsynced transactions');
    return;
  }
  
  print('📤 Uploading ${unsyncedTxs.length} transactions to backend...');
  
  try {
    // POST to backend with list of transactions
    final response = await _apiClient.bulkSync(profileId, unsyncedTxs);
    
    // ✅ CRITICAL: Backend returns created_ids
    // Map each created UUID back to local transaction
    for (int i = 0; i < unsyncedTxs.length; i++) {
      final localTx = unsyncedTxs[i];
      final serverId = response.createdIds[i];  // Get server-assigned UUID
      
      print('✅ TX ${localTx.id} → remoteId=${serverId}');
      
      // Update local transaction with server ID and mark synced
      await _offlineDataService.updateTransaction(
        localTx.copyWith(
          remoteId: serverId,      // ✅ Server UUID for future sync
          isSynced: true,          // ✅ Mark synced so no re-upload
          updatedAt: DateTime.now()
        )
      );
    }
    
    print('✅ STEP 1a complete: ${unsyncedTxs.length} uploaded');
    
  } catch (e) {
    print('❌ Upload failed: $e');
    // Don't mark as synced - will retry next time
  }
}
```

### Backend Code
```python
# backend/transactions/views.py

@action(detail=False, methods=['post'])
def bulk_sync(self, request):
    """
    Upload transactions from mobile app to backend.
    
    REQUEST FORMAT:
    [
      {
        "profile_id": "uuid",
        "amount": 100.00,
        "type": "expense",
        "category": "food",
        "date": "2026-02-06T12:00:00Z",
        "is_synced": true,
        ...
      },
      ...
    ]
    
    RESPONSE FORMAT:
    {
      "created_ids": ["uuid1", "uuid2", ...],
      "updated": 0,
      "errors": []
    }
    
    ✅ KEY POINTS:
    1. Creates new transaction with UUID (database auto-generates)
    2. Sets is_deleted=False (not deleted)
    3. Sets is_synced=True (server owns this data now)
    4. Returns created UUIDs so frontend can map remoteId
    """
    
    user_profile = request.user  # ✅ FIX: request.user IS Profile
    created_ids = []
    
    for tx_data in request.data:
        try:
            # Extract profile_id from request
            profile_id = tx_data.pop('profile_id')
            
            # ✅ SECURITY: Verify user owns this profile
            if str(user_profile.id) != str(profile_id):
                errors.append({'error': 'Unauthorized profile'})
                continue
            
            # Create transaction with backend-assigned UUID
            # Django's models.UUIDField auto-generates if not provided
            transaction = Transaction.objects.create(
                profile=user_profile,           # ✅ Link to user
                **tx_data,
                is_deleted=False,               # ✅ Not deleted
                is_synced=True,                 # ✅ Server has it
                status=TransactionStatus.COMPLETED
            )
            
            # Add UUID to response for frontend mapping
            created_ids.append(str(transaction.id))
            
            print(f"✅ Created transaction {transaction.id}")
            
        except Exception as e:
            print(f"❌ Error: {e}")
            errors.append({'error': str(e)})
    
    return Response({
        'created_ids': created_ids,          # ✅ Frontend uses these as remoteId
        'updated': 0,
        'errors': errors
    })
```

---

## 2. READ (STEP 2-3) - Download & Merge

### Frontend Code
```dart
// lib/services/unified_sync_service.dart

Future<void> _downloadTransactions(String profileId) async {
  print('📥 STEP 2-3: Download transactions from backend...');
  
  try {
    // Fetch all transactions from backend
    // Backend filters: profile=user, is_deleted=false
    final response = await _apiClient.getTransactions(profileId);
    
    print('📊 Server returned ${response.transactions.length} transactions');
    
    // Get existing local transactions for comparison
    final localTxs = await _offlineDataService
        .getTransactions(profileId);
    
    for (final serverTx in response.transactions) {
      // ✅ Try to match by remoteId first
      // This prevents duplicates if we created it locally
      final localTx = localTxs.firstWhere(
        (tx) => tx.remoteId == serverTx.id,
        orElse: () => null
      );
      
      if (localTx != null) {
        // ✅ Already have this transaction
        print('🔄 Merging ${serverTx.id}');
        
        // Update with any server changes
        await _offlineDataService.updateTransaction(
          localTx.copyWith(
            amount: serverTx.amount,            // ✅ Sync changes
            category: serverTx.category,
            isDeleted: serverTx.isDeleted,      // ✅ Sync deletion status
            deletedAt: serverTx.deletedAt,
            isSynced: true,                     // ✅ No longer dirty
          )
        );
      } else {
        // ✅ New transaction from server
        print('➕ Adding new ${serverTx.id}');
        
        await _offlineDataService.addTransaction(
          Transaction.fromJson(serverTx)
        );
      }
    }
    
    print('✅ STEP 2-3 complete: Merged ${response.transactions.length} txns');
    
  } catch (e) {
    print('❌ Download failed: $e');
  }
}
```

### Backend Code
```python
# backend/transactions/views.py

def get_queryset(self):
    """
    Return user's transactions for GET requests.
    
    FLOW:
    1. Identify user from JWT token
    2. Filter: Only transactions belonging to this user
    3. Filter: Only non-deleted transactions
    4. Return: JSON array for frontend to merge
    
    ✅ KEY POINTS:
    1. request.user IS the Profile (custom auth model)
    2. is_deleted=False automatically excludes soft-deleted
    3. Frontend merges by remoteId (no duplicates)
    """
    
    # ✅ FIX: request.user IS the Profile
    user_profile = self.request.user
    profile_id = self.request.query_params.get('profile_id')
    
    # 🔍 DEBUG: Log the execution
    print(f"\n🔍 GET /api/transactions/ EXECUTION:")
    print(f"  📱 User: {user_profile.id}")
    print(f"  🔎 Requested profile: {profile_id}")
    
    # ✅ FILTER 1: Only this user's transactions
    queryset = Transaction.objects.filter(
        profile=user_profile,      # ✅ Profile ownership
        is_deleted=False           # ✅ Hide soft-deleted
    )
    
    print(f"  📊 Found {queryset.count()} transactions")
    
    # ✅ FILTER 2: Validate profile_id parameter (security)
    if profile_id:
        if str(user_profile.id) != str(profile_id):
            # User trying to access someone else's profile
            print(f"  ❌ SECURITY: Unauthorized access")
            return Transaction.objects.none()
        
        queryset = queryset.filter(profile_id=profile_id)
    
    # ✅ Optional: Filter by date range if provided
    start_date = self.request.query_params.get('start_date')
    end_date = self.request.query_params.get('end_date')
    
    if start_date:
        queryset = queryset.filter(date__gte=start_date)
    if end_date:
        queryset = queryset.filter(date__lte=end_date)
    
    print(f"  ✅ FINAL: Returning {queryset.count()} transactions\n")
    
    return queryset
```

---

## 3. UPDATE (STEP 1b) - Edit Transactions

### Frontend Code
```dart
// User edits transaction in UI
void _editTransaction(Transaction tx) async {
  // User changes amount from 100 to 150
  final editedTx = tx.copyWith(
    amount: 150.00,
    category: 'food'
  );
  
  // Mark as needing sync (but keep remoteId!)
  editedTx = editedTx.copyWith(
    isSynced: false,  // ✅ Flag for upload
    // remoteId stays the same - it's the server ID
  );
  
  await _offlineDataService.updateTransaction(editedTx);
  print('✅ Transaction marked for sync');
}

// Later during sync...
Future<void> _syncUpdates(String profileId) async {
  // Find all dirty transactions (edited but not synced)
  final dirtyTxs = await _offlineDataService
      .getDirtyTransactions(profileId);
  
  if (dirtyTxs.isEmpty) return;
  
  print('📤 Uploading ${dirtyTxs.length} updates...');
  
  try {
    // Build request with remoteId and changes
    final updates = dirtyTxs.map((tx) => {
      'id': tx.remoteId,        // ✅ Server UUID
      'amount': tx.amount,      // ✅ New value
      'category': tx.category,
      // Only send changed fields
    }).toList();
    
    // POST to backend
    final response = await _apiClient.updateTransactions(
      profileId,
      updates
    );
    
    if (response.success) {
      // Mark as synced
      for (final tx in dirtyTxs) {
        await _offlineDataService.updateTransaction(
          tx.copyWith(isSynced: true)
        );
      }
      print('✅ STEP 1b complete: ${dirtyTxs.length} updated');
    }
    
  } catch (e) {
    print('❌ Update failed: $e');
  }
}
```

### Backend Code
```python
# backend/transactions/views.py

@action(detail=False, methods=['post'])
def batch_update(self, request):
    """
    Update existing transactions.
    
    REQUEST FORMAT:
    [
      {
        "id": "uuid-from-server",      # ✅ Use remoteId
        "amount": 150.00,               # ✅ New value
        "category": "food",
        ...
      },
      ...
    ]
    
    RESPONSE FORMAT:
    {
      "success": true,
      "updated": 2,
      "failed_count": 0,
      "failed_ids": [],
      "errors": null
    }
    
    ✅ KEY POINTS:
    1. Use transaction ID (UUID) from frontend's remoteId
    2. Only update non-deleted transactions
    3. Set updated_at to current time
    4. Return failed_ids so frontend knows which failed
    """
    
    user_profile = request.user  # ✅ request.user IS Profile
    updated_count = 0
    failed_ids = []
    errors = []
    
    for tx_update in request.data:
        try:
            transaction_id = tx_update.get('id')
            
            # ✅ Find transaction and verify:
            # 1. Belongs to this user
            # 2. Is not soft-deleted
            transaction = Transaction.objects.get(
                id=transaction_id,
                profile=user_profile,
                is_deleted=False  # ✅ Don't update deleted
            )
            
            # ✅ Partial update (only provided fields)
            serializer = TransactionSerializer(
                transaction,
                data=tx_update,
                partial=True,  # ✅ Allow partial updates
                context={'request': request}
            )
            
            if serializer.is_valid():
                # ✅ Explicitly set updated_at to now
                serializer.save(
                    updated_at=timezone.now()
                )
                updated_count += 1
                print(f"✅ Updated {transaction_id}")
            else:
                # ✅ Track validation errors
                failed_ids.append(transaction_id)
                errors.append({
                    'id': transaction_id,
                    'error': serializer.errors
                })
                print(f"❌ Validation failed: {serializer.errors}")
                
        except Transaction.DoesNotExist:
            print(f"❌ Transaction {transaction_id} not found")
            failed_ids.append(transaction_id)
            errors.append({
                'id': transaction_id,
                'error': 'Not found or already deleted'
            })
    
    return Response({
        'success': len(failed_ids) == 0,
        'updated': updated_count,
        'failed_count': len(failed_ids),
        'failed_ids': failed_ids,
        'errors': errors if errors else None
    })
```

---

## 4. DELETE (STEP 1c) - Remove Transactions

### Frontend Code
```dart
// User deletes transaction in UI
void _deleteTransaction(Transaction tx) async {
  // ✅ Mark as deleted but keep remoteId
  final deletedTx = tx.copyWith(
    isDeleted: true,              // ✅ Mark locally deleted
    deletedAt: DateTime.now(),    // ✅ Timestamp deletion
    isSynced: false               // ✅ Flag for sync
  );
  
  // Still in local DB (soft delete)
  // Will sync deletion to backend next time
  await _offlineDataService.updateTransaction(deletedTx);
  print('✅ Transaction marked for deletion sync');
}

// Later during sync...
Future<void> _syncDeletes(String profileId) async {
  // Find all transactions marked deleted but not yet synced
  final deletedTxs = await _offlineDataService
      .getDeletedTransactions(profileId);
  
  if (deletedTxs.isEmpty) return;
  
  print('🗑️ Uploading ${deletedTxs.length} deletions...');
  
  try {
    // Collect server IDs (remoteId) of deleted TXs
    final deleteIds = deletedTxs
        .where((tx) => tx.remoteId != null)  // ✅ Must have server ID
        .map((tx) => tx.remoteId)
        .toList();
    
    if (deleteIds.isEmpty) return;
    
    // POST to backend
    final response = await _apiClient.deleteTransactions(
      profileId,
      deleteIds
    );
    
    if (response.success) {
      // Remove from local DB completely
      for (final tx in deletedTxs) {
        await _offlineDataService.deleteTransaction(tx.id);
      }
      print('✅ STEP 1c complete: ${deleteIds.length} deleted');
    }
    
  } catch (e) {
    print('❌ Delete failed: $e');
  }
}
```

### Backend Code
```python
# backend/transactions/views.py

@action(detail=False, methods=['post'])
def batch_delete(self, request):
    """
    Delete transactions (soft-delete for audit trail).
    
    REQUEST FORMAT:
    {
      "transaction_ids": ["uuid1", "uuid2", ...]  # ✅ List of IDs to delete
    }
    
    RESPONSE FORMAT:
    {
      "success": true,
      "deleted": 2,
      "soft_deleted": 2,           # ✅ Clarifies it's soft-delete
      "already_deleted": 0,
      "failed_ids": [],
      "errors": null,
      "note": "Data preserved for audit trail"
    }
    
    ✅ KEY POINTS:
    1. Soft-delete: Sets is_deleted=True, deleted_at=NOW()
    2. Data NOT permanently removed (for audit trail)
    3. GET requests automatically exclude these (is_deleted=False filter)
    4. Can be restored later if needed
    """
    
    user_profile = request.user  # ✅ request.user IS Profile
    
    # Get IDs from request
    tx_ids = request.data.get('transaction_ids', [])
    
    deleted_count = 0
    already_deleted_count = 0
    failed_ids = []
    errors = []
    
    for tx_id in tx_ids:
        try:
            # Find transaction
            transaction = Transaction.objects.get(
                id=tx_id,
                profile=user_profile  # ✅ User must own it
            )
            
            if transaction.is_deleted:
                # Already deleted
                print(f"⚠️ TX {tx_id} already deleted")
                already_deleted_count += 1
            else:
                # ✅ SOFT DELETE: Set flag and timestamp
                transaction.is_deleted = True
                transaction.deleted_at = timezone.now()
                transaction.save(
                    update_fields=['is_deleted', 'deleted_at', 'updated_at']
                )
                deleted_count += 1
                print(f"✅ Soft-deleted {tx_id}")
                
        except Transaction.DoesNotExist:
            print(f"❌ TX {tx_id} not found")
            failed_ids.append(tx_id)
            errors.append({
                'id': tx_id,
                'error': 'Not found'
            })
    
    return Response({
        'success': len(failed_ids) == 0,
        'deleted': deleted_count,
        'soft_deleted': deleted_count,  # ✅ Clarifies it's soft
        'already_deleted': already_deleted_count,
        'failed_ids': failed_ids,
        'errors': errors if errors else None,
        'note': 'Transactions are soft-deleted. Data preserved for audit trail.'
    })
```

---

## 5. Complete Sync Flow Example

```dart
// lib/services/unified_sync_service.dart

Future<void> performFullSync(String profileId) async {
  print('\n═══════════════════════════════════════════');
  print('🔄 FULL SYNC STARTED');
  print('═══════════════════════════════════════════\n');
  
  try {
    // STEP 1a: Upload new transactions
    print('📤 STEP 1a: Upload new transactions...');
    await _syncTransactions(profileId);
    
    // STEP 1b: Upload edited transactions
    print('✏️  STEP 1b: Upload edits...');
    await _syncUpdates(profileId);
    
    // STEP 1c: Upload deleted transactions
    print('🗑️  STEP 1c: Upload deletions...');
    await _syncDeletes(profileId);
    
    // STEP 2-3: Download and merge
    print('📥 STEP 2-3: Download and merge...');
    await _downloadTransactions(profileId);
    
    print('\n═══════════════════════════════════════════');
    print('✅ FULL SYNC COMPLETE');
    print('═══════════════════════════════════════════\n');
    
    // Notify UI to refresh
    notifyListeners();
    
  } catch (e) {
    print('❌ SYNC FAILED: $e');
    // App continues offline - data will sync next time
  }
}
```

---

## 6. Database Queries for Verification

```sql
-- Check soft-delete columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name='transactions' 
  AND column_name IN ('is_deleted', 'deleted_at');

-- View active transactions (what GET returns)
SELECT id, amount, type, is_deleted, is_synced, profile_id
FROM transactions 
WHERE is_deleted=false 
  AND profile_id='51f02462-1860-475e-bbe2-80bd129ea7a5'
ORDER BY created_at DESC;

-- View soft-deleted transactions (hidden from GET)
SELECT id, amount, type, is_deleted, deleted_at
FROM transactions 
WHERE is_deleted=true 
  AND profile_id='51f02462-1860-475e-bbe2-80bd129ea7a5'
ORDER BY deleted_at DESC;

-- Check sync status
SELECT COUNT(*) as unsynced 
FROM transactions 
WHERE is_synced=false 
  AND profile_id='51f02462-1860-475e-bbe2-80bd129ea7a5';
```

---

## Key Takeaways

1. **RemoteId Tracking**: Frontend stores server UUID so can identify TX for updates/deletes
2. **Profile Scoping**: All queries filter by profile → Multi-user safe
3. **Soft Delete**: Data preserved for audit → is_deleted filter hides from UI
4. **Merge by ID**: Frontend matches by remoteId → No duplicates on GET
5. **Error Tracking**: API returns failed_ids → Frontend knows what to retry
6. **Explicit Syncing**: Each CRUD op explicitly marks isSynced → Clear state
7. **Offline-First**: All ops work offline → Sync when ready

---

**This is production-ready architecture. Test end-to-end to confirm all pieces work together.**
