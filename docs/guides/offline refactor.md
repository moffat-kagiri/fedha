## Codebase Refactor: Offline-First Goal & Budget Tracking Optimization

### Context
This Flutter app (Fedha) has had its backend dependency removed in this branch. The goal and budget tracking features are experiencing performance issues as a result of lingering sync logic, redundant event emissions, and backend-coupled code paths that now run unnecessarily or fail silently.

---

### Primary Objectives

**1. Audit and Remove Backend Dependency**
- Delete the `/backend` directory entirely from this branch
- Remove all `AppMode.localOnly` guard checks — local-only is now the default and only mode; replace every `if (!AppMode.localOnly)` block with its offline body directly, then delete `app_mode.dart`
- Strip all `UnifiedSyncService` sync calls from `OfflineDataService.saveTransaction`, `updateTransaction`, `saveGoal`, etc. — the `unawaited(_syncService?.syncAfterCrud(...))` calls should be removed entirely
- Remove `UnifiedSyncService` as a provider and dependency from `main.dart` and all service constructors; replace with a no-op stub or remove entirely if nothing else depends on it
- Remove `ApiClient` calls from the critical path in `main.dart` — the `_initializeNetworkServicesInBackground()` function and `ConnectionManager.findWorkingConnection()` should be removed or stubbed out

**2. Fix Goal Tracking Performance**
- In `TransactionEventService._recalculateGoalProgress`, the method re-fetches all transactions for a profile on every single transaction event. Refactor to accept a pre-loaded transaction list as an optional parameter to avoid redundant database reads
- In `TransactionEventService._handleTransactionAdded`, `loadBudgetsForProfile` is called on every new transaction — this triggers two database writes (creating default budgets) even when they already exist. Add an in-memory flag or a lightweight existence check before calling it
- `_processedTransactionIds` in `TransactionEventService` uses a `Set<String>` that grows unboundedly and is only cleaned up with a 5-second `Future.delayed`. Replace with a time-bounded LRU cache or a fixed-size set that evicts oldest entries

**3. Fix Budget Tracking Performance**
- In `BudgetService.loadBudgetsForProfile`, default budgets ("other" and "savings") are created inside a loop on every profile load. Extract this to a one-time initialization guard using a `SharedPreferences` key like `budgets_initialized_$profileId` so it only runs once per profile
- `_recalculateBudgets` in `TransactionEventService` resets all budget spent amounts to zero and then replays every transaction on every update event. This is O(n×m). Refactor to an incremental update: only adjust the affected budget's `spentAmount` by the delta of the changed transaction, not a full replay
- The `_updateBudgetSpending` method calls `_offlineDataService.getAllBudgets` and `_offlineDataService.updateTransaction` on every single transaction. Cache the active budgets for the current month in memory within `TransactionEventService` and invalidate only when a budget is created, updated, or deleted

**4. Eliminate Duplicate Event Emissions**
- Trace all call sites of `TransactionEventService.onTransactionCreated` — it is currently called both from `OfflineDataService.saveTransaction` (via `_eventService`) and from `GoalTransactionService.createSavingsTransaction`, `GoalTransactionService.transferBetweenGoals`, and `TransactionOperations.createTransaction`. Remove the duplicate emissions: the single emission inside `OfflineDataService` should be the canonical source of truth, and all other callers should be stripped of their direct event calls
- In `OfflineDataService.approvePendingTransaction`, the event service is temporarily set to null and then restored to work around duplicate emissions — this is a code smell introduced by the duplication above. Once duplicates are removed, simplify this method back to a straightforward save + single emit

**5. Clean Up Dead Code**
- Remove `SyncManager` (`sync_manager.dart`) entirely — it references `ApiClient.syncTransactions` with a wrong signature and is not wired into any provider
- Remove the `service_stubs.dart` duplicate definitions of `ThemeService`, `CurrencyService`, `NotificationService`, `GoogleAuthService` — these conflict with the real implementations; audit all imports and ensure only the real services are used
- Remove `auth_service_sqlite.dart` — it is a duplicate of `auth_service.dart` and should not exist in the codebase
- Remove `api_client_sqlite.dart` — same reason
- Remove `profile_management_extension.dart`'s `updateLocalProfile` method which calls `setCurrentProfile` after writing to `current_profile_data` key — this key is no longer the canonical storage location and will cause profile corruption
- Remove the `_getOrCreateDeviceId` method from `AuthService` — it is defined but never called

**6. Simplify `main.dart`**
- Remove `_initializeNetworkServicesInBackground`, `_initializeNetworkServices`, `_runPostStartupSync`, `_registerBackgroundTasks`, and `ConnectionManager` usage entirely
- Remove `UnifiedSyncService` from `_buildProviders()`
- Remove `conn_svc.ConnectivityService` from providers — it depends on `ApiClient` and serves no purpose offline
- Simplify `MyApp.didChangeAppLifecycleState` — remove the sync-on-resume logic and the `_syncDataOnResume` / `_syncDataInBackground` methods; keep only the biometric session invalidation and SMS listener restart
- Remove WorkManager background task registration (`sms_listener`, `daily_review`, `background_sync`) or reduce to only the daily notification task if notifications are still desired

**7. Verify Correctness After Changes**
- After all removals, run a full import audit: search for any remaining imports of `unified_sync_service.dart`, `api_client.dart`, `connectivity_service.dart`, `connection_manager.dart`, `app_mode.dart`, and `sync_manager.dart` and remove them
- Confirm `OfflineDataService` can be instantiated without `UnifiedSyncService` — the `setSyncService` method and `_syncService` field should be removed
- Confirm `BudgetService`, `TransactionEventService`, and `GoalTransactionService` all function correctly in unit tests or manual smoke tests with no network available
- Ensure `TransactionEventService` is initialized with just `OfflineDataService` and `BudgetService` and no sync service reference

---

### Acceptance Criteria
- App cold-starts and reaches the home screen with no network and no errors in logs
- Adding a transaction updates the correct budget and goal within 200ms
- No duplicate budget updates or goal recalculations occur on a single transaction save
- No references to `UnifiedSyncService`, `ApiClient`, `AppMode`, or `ConnectivityService` remain in non-stub code
- The `/backend` directory does not exist in this branch