# Fedha Codebase AI Instructions

## Project Overview
**Fedha** is an offline-first personal finance tracker with three main components:
- **Flutter App** (iOS/Android): Core budget, loan, and goal tracking with SMS transaction parsing
- **Django Backend** (PostgreSQL): Profile sync, authentication, invoicing
- **Web Frontend** (Node.js): Optional web interface

Critical principle: **Offline-first architecture** — 90% of app works without internet.

## Architecture Diagrams

### App Data Flow
```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  UI Layer (Screens)                                              │
│  ↓                                                                │
│  Provider Consumers (read/notify)                                │
│  ↓                                                                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Service Layer (ChangeNotifier)                           │   │
│  │ ├─ AuthService (login, profile)                          │   │
│  │ ├─ OfflineDataService (local DB CRUD)                    │   │
│  │ ├─ UnifiedSyncService (batch sync)                       │   │
│  │ ├─ BudgetService (budget calculations)                   │   │
│  │ └─ ConnectivityService (network state)                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ↓                                                                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Data Layer (Drift ORM)                                   │   │
│  │ ├─ Transactions (amount, category, goalId)               │   │
│  │ ├─ Budgets (limits, spent tracking)                      │   │
│  │ ├─ Goals (targets, progress)                             │   │
│  │ ├─ Loans (principal, rate, term)                         │   │
│  │ ├─ Categories (classification)                           │   │
│  │ └─ SyncQueue (pending changes)                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ↓                                                                │
│  SQLite (offline-first)                                          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
         ↓ (when connected)
┌─────────────────────────────────────────────────────────────────┐
│                      DJANGO BACKEND                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  API Layer (DRF ViewSets)                                        │
│  ├─ TransactionViewSet (create, sync, batch_sync)               │
│  ├─ BudgetViewSet (CRUD, current, summary)                      │
│  ├─ GoalViewSet (CRUD, progress)                                │
│  ├─ LoanViewSet (CRUD, amortization)                            │
│  ├─ InvoiceViewSet (send, PDF, email)                           │
│  └─ CategoryViewSet (list, tree)                                │
│  ↓                                                                │
│  Models (Django ORM)                                             │
│  ├─ Transaction (type, status, amount, category)                │
│  ├─ Budget (period, spent tracking, constraints)                │
│  ├─ Goal (target, progress, status)                             │
│  ├─ Loan (principal, term, interest model)                      │
│  ├─ Invoice & Client (invoicing)                                │
│  └─ Category (classification)                                   │
│  ↓                                                                │
│  PostgreSQL Database                                             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Sync Workflow
```
Flutter App Changes
    ↓
Write to SQLite (OfflineDataService)
    ↓
Add to SyncQueue with timestamp
    ↓
ConnectivityService detects connection
    ↓
UnifiedSyncService batches (50 items/batch)
    ↓
POST /api/{resource}/batch_sync/ to Django
    ↓
Django validates, saves, returns conflicts
    ↓
Server-wins conflict resolution
    ↓
Update local records, mark is_synced=True
    ↓
Clear from SyncQueue
```

## Architecture Patterns

### Service Initialization Order
The app follows a strict initialization sequence in `lib/main.dart` → `_initializeServices()`:
1. **OfflineDataService** (Drift SQLite database) — must initialize first
2. **BiometricAuthService** 
3. **PermissionsService**
4. **ThemeService**
5. **ConnectivityService** (network detection)
6. **AuthService** (with all dependencies injected)
7. **UnifiedSyncService** (starts batch sync)
8. **BudgetService**
9. **MultiProvider** wraps entire app with these services

**Key pattern**: Services are singletons using factory constructors (e.g., `AuthService.instance`). Always pass dependencies via `initialize()` methods, not through constructors.

### Data Layer: Offline + Sync
- **OfflineDataService** (`lib/services/offline_data_service.dart`): 
  - Single-access point for Drift database
  - Manages CRUD for transactions, budgets, goals, loans
  - Handles sync queue (`SyncQueueItem` model) for pending changes
  
- **UnifiedSyncService** (`lib/services/unified_sync_service.dart`):
  - Watches connectivity state
  - Batches operations (50-item chunks) for efficiency
  - Syncs all entities: transactions, budgets, goals, profiles
  - Manages conflict resolution (server wins)

**Pattern**: Always write to both local database AND add to sync queue before assuming data is persisted remotely.

### Database Schema (Drift ORM)
Located in `lib/data/app_database.dart`:
- **Transactions**: Core finance records (amountMinor in integer cents, not decimals)
- **Categories**, **Budgets**, **Goals**, **Loans**: Metadata for transactions
- **Profiles**: User account info (local user representation)
- Profile scoping: Most queries filter by `profileId`

**Critical**: Amount fields use `amountMinor` (integer cents) with `_DecimalConverter()` for precision. Never use floats for money.

### Models
All in `lib/models/` with generated `.g.dart` files (JSON serialization via `json_serializable`):
- Use `@JsonSerializable()` on classes
- Never manually edit `.g.dart` files—regenerate via `dart run build_runner build`
- Enums in `enums.dart` (TransactionType, InteractionType, etc.)

## Critical Workflows

### Backend App Workflows

#### Transactions Workflow
**App → Backend → Database**
```
1. App: Create Transaction (offline)
   - Write to SQLite with is_synced=False
   - Add SyncQueueItem(resource: 'transactions', action: 'create')

2. App (when online): Batch Sync
   - Call POST /api/transactions/batch_sync/
   - Send 50 transactions with profile_id, category, goalId, amountMinor (cents)

3. Django: Process Batch
   - Filter by profile (profile_id in request.data)
   - Validate: amount > 0, type in [income|expense|transfer|savings]
   - Check status: pending → completed
   - Index: (profile, date), (profile, category), (profile, is_synced)

4. Return: Synced IDs or conflicts (backend uses server values)
```

#### Budgets Workflow
**Creating & Tracking Spending**
```
1. App: Create Budget
   - POST /api/budgets/
   - Body: {name, category, budget_amount, period, start_date, end_date, profile_id}
   - Constraints: budget_amount > 0, end_date > start_date

2. Backend: Filtering
   - GET /api/budgets/?current_only=true
   - Returns active budgets where start_date ≤ now ≤ end_date
   - Calculated field: spent_amount (sum of matching transactions)

3. App: Real-time Tracking
   - BudgetService watches transaction changes
   - Updates spent_amount via local calculation (amountMinor → decimal)
   - Shows: % spent, remaining, alerts if > 80%

4. Sync: Mark is_synced=True after server confirms
```

#### Goals Workflow
**Target Tracking & Progress**
```
1. App: Create Goal
   - POST /api/goals/
   - Body: {name, goal_type, target_amount, target_date, currency, linked_category}
   - Types: savings | debtReduction | insurance | emergencyFund | investment

2. Transaction Link:
   - Transactions can have goal_id (string reference)
   - App calculates: current_amount = sum of transactions where goal_id matches

3. Progress Calculation:
   - % complete = current_amount / target_amount
   - Projected completion = linear regression of recent contributions
   - Days ahead/behind target schedule

4. Status Transitions:
   - active → completed (when current_amount ≥ target_amount)
   - active → paused / cancelled (user action)
   - completed_date set automatically
```

#### Loans/Invoicing Workflow
**Loan Tracking & Invoice Generation**
```
1. App: Create Loan
   - POST /api/loans/
   - Body: {principal, annual_rate, term_months, interest_type, payment_frequency}
   - Interest types: simple | compound | reducingBalance

2. Calculations (mostly offline):
   - Monthly payment = calculatePayment(principal, rate, term)
   - Amortization schedule generated client-side
   - Interest accrual tracked in local database

3. Invoice Generation:
   - POST /api/invoices/ with client_id, amount, items
   - Django generates PDF with logo, itemization
   - Sends email via SendGrid/SMTP

4. Sync: Invoice status changes sync back (draft → sent → paid)
```

#### Categories Workflow
**Classification & Hierarchy**
```
1. App: Categories (mostly offline)
   - Predefined list (Food, Transport, Utilities, etc.)
   - Users can create custom categories locally
   - Stored as string in transactions (category field)

2. Backend: Category List
   - GET /api/categories/ → returns system + user categories
   - Optional: tree structure (parent_category field)
   - Used for filtering, budgets, analytics

3. Sync: Custom categories sync via sync queue
   - category string stored in transaction
   - Backend creates Category record if doesn't exist
```

#### Profile Sync Workflow
**Multi-Device Account Sync**
```
1. Login (Device A):
   - POST /api/accounts/login/ → get JWT token + profile
   - Store in flutter_secure_storage
   - OfflineDataService creates local profile record

2. Add Transaction (Device A - offline):
   - Written to SQLite + sync queue
   - Synced when online → marked is_synced=True

3. Login (Device B):
   - Restores profile from server
   - Calls GET /api/transactions/?profile_id=xxx
   - Pulls all synced transactions for this profile
   - Builds local SQLite from server source of truth

4. Conflict: Device A and B edit same transaction offline
   - Both sync to server
   - Server-wins: Device B's local copy gets overwritten
   - Next sync pull fetches server version
```

### Adding a New Feature
1. **Add model** in `lib/models/` with JSON serialization
2. **Add database table** in `lib/data/app_database.dart`
3. **Add service methods** in appropriate service (OfflineDataService, BudgetService, etc.)
4. **Wire sync** in UnifiedSyncService (add batch sync method)
5. **Add UI** in `lib/screens/` using Provider for state management
6. **Test offline** by toggling connectivity via ConnectivityService

### Syncing a Feature with Backend
- Create corresponding Django model in `backend/` app (e.g., `accounts/models.py`, `budgets/models.py`)
- Add DRF serializer (`serializers.py`)
- Add viewset with `@action(detail=False)` for batch operations
- Update UnifiedSyncService sync logic (search for `_syncTransactions` pattern)
- Test via CONNECTION_GUIDE setup (local, tunnel, or device network)

### Testing SMS Features
- SMS detection is **fully offline** via `OfflineSmsParser` in `lib/services/sms_transaction_extractor.dart`
- Pattern matching handles M-Pesa, Airtel Money, equity, KCB, Co-op banks
- Use `lib/test/auth_test_flow.dart` as reference for flow testing
- **Note**: `flutter_sms_inbox` is Android-only; iOS uses SMS app fallback

### Backend Development
- Django app structure: `backend/{app}/models.py`, `views.py`, `serializers.py`, `urls.py`
- Use DRF authentication: `simplejwt` (JWT tokens)
- Profile scoping in views: filter querysets by `request.user.profile`
- Signals in `signals.py` handle cascading deletes
- **Connection options** in `docs/CONNECTION_GUIDE.md`: localhost, LAN IP, or Cloudflare tunnel

## Code Conventions

### Naming
- Services: `*Service` (AuthService, OfflineDataService)
- Models: PascalCase classes, lowerCamelCase fields
- Database tables: PascalCase + plural (Transactions, Categories)
- Enums: UpperCamelCase (TransactionType, InterestType)

### Logging
Use `AppLogger.getLogger('ClassName')` from `lib/utils/logger.dart`:
```dart
final _logger = AppLogger.getLogger('MyService');
_logger.info('Message');  // info, warning, severe
```

### Error Handling
- Always catch and log network errors in sync operations
- Use `try-catch` + `notifyListeners()` in services (ChangeNotifier pattern)
- Propagate critical auth errors to AuthService for logout

### State Management (Provider)
- Services use `ChangeNotifier` mixin (AuthService, BudgetService, UnifiedSyncService)
- Wrap in `MultiProvider` at app level (main.dart)
- Use `Consumer<ServiceType>()` in widgets to rebuild on changes
- Never store state in widgets; always in services

## Development Workflows

### Build & Run
```bash
# Flutter app (Android)
flutter run -d android

# Generate database & models
dart run build_runner build

# Backend
cd backend && python manage.py migrate && python manage.py runserver

# Web (optional)
cd web && npm install && npm start
```

### Testing
- Unit tests: `test/` directory
- Run: `flutter test`
- Test flows exist in `auth_test_flow.dart`, `widget_test.dart`

### Debugging Offline Sync
1. Check sync queue: `OfflineDataService().getSyncQueue(profileId)`
2. Monitor via logs: `AppLogger` shows sync progress
3. Toggle connectivity: `ConnectivityService().isConnected`
4. Validate backend: use CONNECTION_GUIDE tunnel for remote access

## Important Dependencies

### Flutter
- **provider**: State management (6.1.5+)
- **drift**: SQLite ORM database (2.30.0)
- **google_sign_in**: OAuth authentication
- **flutter_secure_storage**: Encrypted credentials
- **local_auth**: Biometric auth
- **connectivity_plus**: Network state
- **workmanager**: Background tasks (SMS listener)
- **awesome_notifications**: Local notifications
- **fl_chart**, **syncfusion_flutter_charts**: Analytics charts

### Backend (Django)
- **djangorestframework**: REST API
- **djangorestframework_simplejwt**: JWT auth
- **django-cors-headers**: Cross-origin requests
- **psycopg2**: PostgreSQL adapter
- **factory_boy**: Test data generation

## Common Pitfalls

1. **Sync conflicts**: Server always wins on merge. Local changes get queued, not merged.
2. **Profile scoping**: ALWAYS filter by profileId. Queries without it will leak data.
3. **Offline testing**: Simulate via ConnectivityService.simulateOffline() or kill wifi.
4. **Money precision**: Use `amountMinor` (cents) + `_DecimalConverter`, never floats.
5. **Background tasks**: Android requires workmanager setup; iOS has limitations (check `background_service.dart`).
6. **JSON serialization**: Regenerate models after schema changes: `dart run build_runner build`

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, service initialization |
| `lib/services/offline_data_service.dart` | Local database CRUD |
| `lib/services/unified_sync_service.dart` | Sync orchestration |
| `lib/services/auth_service.dart` | Auth + profile state |
| `lib/data/app_database.dart` | Drift schema definition |
| `lib/models/*.dart` | Domain models + serialization |
| `lib/services/sms_transaction_extractor.dart` | Offline SMS parsing |
| `backend/accounts/`, `budgets/`, etc. | Django REST endpoints |
| `docs/OFFLINE_FEATURES.md` | Feature capabilities matrix |
| `docs/CONNECTION_GUIDE.md` | Backend connection setup |
