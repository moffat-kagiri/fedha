# Fedha – Personal Finance Tracker

> **Intelligent offline-first personal finance management with advanced analytics, loan calculators, and budget tracking for iOS, Android, and Web.**

---

## 🎯 What is Fedha?

Fedha is a sophisticated personal finance management application designed for users who need **powerful financial tools without internet dependencies**. With an offline-first architecture, intelligent SMS transaction parsing, and comprehensive financial planning features, Fedha puts you in complete control of your finances.

**Key Tagline:** *Privacy-first. Offline-first. Feature-rich.*

---

## 💡 Benefits

### For Personal Finance Management
- **Complete Privacy** – All your sensitive financial data stays on your device. No cloud syncing unless you explicitly configure it.
- **Works Offline** – Track transactions, manage budgets, and plan goals even without internet connectivity.
- **Intelligent Transaction Capture** – Automatic SMS parsing for M-Pesa, Airtel Money, and major bank transactions.
- **Multi-Currency Support** – Manage finances across different currencies seamlessly.

### For Financial Planning
- **Smart Goal Setting** – Progressive goal wizards with intelligent target suggestions based on your financial capacity.
- **Comprehensive Loan Management** – Advanced loan calculators with multiple interest models (simple, compound, reducing balance).
- **Budget Analytics** – Real-time spending tracking against budgets with predictive alerts and insights.
- **Investment Planning** – IRR calculators and risk assessment tools to guide investment decisions.

### For Developers & Deployers
- **Production-Ready** – Enterprise-grade state management (Provider pattern), offline sync architecture, and comprehensive error handling.
- **Flexible Deployment** – Native Android/iOS apps, optional web interface, and Django REST backend.
- **Security-First** – Biometric authentication, encrypted local storage, and flexible KMS integration for production deployments.

---

## 📱 Installation & Quick Start

### ⭐ **Quickest Way: Download APK** (Recommended for Most Users)

If you just want to **download and install the app**, use **Option 2** below. No technical knowledge required!

---

### Installation Options

#### Option 1: Build from Source (For Developers & Contributors)

##### Prerequisites
- Flutter SDK ≥3.19.0
- Dart SDK ≥3.8.0
- Python ≥3.8 (for backend)
- Git

##### Step 1: Clone the Repository
```bash
git clone https://github.com/moffat-kagiri/fedha.git
cd fedha
```

##### Step 2: Set Up Flutter App
```bash
cd app
flutter pub get
flutter pub run build_runner build  # Generate models and database code
```

##### Step 3: Run on Your Device

**Android:**
```bash
flutter run -d android
# Or install APK directly:
# flutter build apk --release
```

**iOS:**
```bash
flutter run -d ios
# Or build for App Store:
# flutter build ipa --release
```

**Web (Optional):**
```bash
cd ../web
npm install && npm start
```

##### Step 4: Set Up Backend (Optional but Recommended)
For full sync capabilities, set up the Django backend:

```bash
cd ../backend
python -m venv .venv
# On Windows:
.venv\Scripts\activate
# On macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

Then configure the app to connect to your backend:
1. Open `app/lib/config/api_config.dart`
2. Set your backend URL (local development, LAN IP, or Cloudflare tunnel)
3. Run: `flutter run`

#### Option 2: Download Pre-Built APK (Android Only) ⭐ **Easiest for End Users**

**Latest Release:** [Download Fedha v1.0.0 APK](https://github.com/moffat-kagiri/fedha/releases/download/v1.0.0/app-release.apk) (65 MB)

**Installation Steps:**
1. Download the APK file to your Android device (Android 11+)
2. Open **Settings** → **Security** (or **Apps & Notifications**)
3. Enable **"Unknown Sources"** or **"Install from Unknown Sources"**
4. Locate the downloaded APK file in your Files app or Downloads folder
5. Tap the APK and select **Install**
6. Once installed, launch **Fedha** from your app drawer
7. Create an account or sign in to get started

**No tech stack required!** This is the simplest way for non-technical users to install Fedha.

*Note: iOS users should build from source using Xcode or install via TestFlight distribution.*

#### Option 3: Manual APK Build (For Customization)
```bash
cd app
flutter build apk --release
# Find APK at: app/build/app/outputs/flutter-apk/app-release.apk
```

---

## ✨ Features Showcase

### 💰 Transaction Management
- **Smart Entry** – Quick transaction entry with category suggestions
- **SMS Import** – Automatic detection of bank transfers, mobile money, and card transactions
- **Flexible Categories** – Predefined categories with custom category creation
- **Multi-Currency** – Track transactions in different currencies with real-time conversion
- **Status Tracking** – Mark transactions as pending, completed, or cancelled

### 📊 Budget Tracking & Analytics
- **Budget Creation** – Set spending limits per category with flexible time periods
- **Real-Time Tracking** – Live spending percentage against budget limits
- **Smart Alerts** – Notifications at 80% and 100% of budget spent
- **Analytics Dashboard** – Visualized spending patterns with trends and comparisons
- **Budget Review** – Detailed analysis of budget vs. actual spending

### 🎯 Goal Management
- **Goal Types** – Savings, debt reduction, insurance, emergency funds, investments
- **Progress Tracking** – Visual progress indicators and completion projections
- **Smart Linking** – Link transactions directly to goals for accurate progress
- **Goal Wizards** – Progressive goal setting with personalized recommendations based on user profile

### 🏦 Loan & Debt Management
- **Loan Calculator** – Calculate EMI, total interest, and amortization schedules
- **Multiple Interest Models** – Simple interest, compound interest, reducing balance
- **Debt Repayment Planner** – Strategic debt payoff scheduling with multiple strategies
- **APR Calculations** – Accurate Annual Percentage Rate calculations for loan comparison

### 💎 Financial Planning Tools
- **Investment Calculator** – IRR, ROI, and compound interest calculations
- **Risk Assessment** – Investment risk profiling based on financial capacity
- **Protection Plans** – Health, vehicle, home, and emergency fund calculators
- **Emergency Fund Planner** – Calculate ideal emergency fund based on expenses

### 🔐 Security & Privacy
- **Biometric Authentication** – Face ID, Fingerprint, PIN-based authentication
- **Encrypted Storage** – Local encryption for all sensitive data
- **Offline-First** – No mandatory cloud dependency; sync only when needed
- **Session Management** – Automatic locking with configurable timeout

### 🌐 Multi-Platform Support
- **Native Android** – Full-featured Android app with SMS integration
- **Native iOS** – Complete iOS support with biometric authentication
- **Web Interface** – Optional web dashboard for viewing and managing finances
- **Responsive Design** – Works seamlessly across phone, tablet, and desktop sizes

---

## 🏗️ Architecture & Technical Excellence

### Advanced State Management
- **Provider Pattern** – Reactive, efficient state management using the Provider package (v6.1.5+)
- **Service Layer** – Decoupled services for data, auth, sync, and business logic
- **ChangeNotifier** – Optimized rebuilds through Provider consumers and selectors

### Offline-First Data Layer
- **Drift ORM** – Type-safe, reactive SQLite database with code generation
- **Local-First Sync** – Batch sync queue for efficient server synchronization
- **Conflict Resolution** – Server-authoritative merge strategy for multi-device consistency
- **Encrypted Cache** – Secure local storage with optional encryption

### Intelligent Sync Architecture
```
Local Changes → Queue → Batch (50 items) → Server Validation → Merge → Local Update
```
- Automatic detection of connectivity status
- Intelligent batching for network efficiency
- Server-wins conflict resolution for data consistency
- Offline operation without degradation

### SMS Transaction Intelligence
- **Pattern Matching** – Bank-specific regex patterns (M-Pesa, Airtel, KCB, Equity, Co-op)
- **Fully Offline** – No API calls required for SMS parsing
- **High Accuracy** – Extracts amount, date, transaction type, and balance
- **Extensible** – Easy to add new bank patterns

### Backend REST API
- **Django REST Framework** – Modern, REST-compliant API
- **JWT Authentication** – Secure token-based authentication
- **PostgreSQL** – Robust relational database for server data
- **Profile Isolation** – Complete data isolation between users
- **Batch Operations** – Optimized endpoints for batch transaction sync

### Code Quality & Architecture
- **Repository Pattern** – Abstract data layer from business logic
- **Service Injection** – Dependency injection for testability
- **Error Handling** – Comprehensive try-catch with logging and user feedback
- **Logging Framework** – Structured logging for debugging and monitoring
- **SOLID Principles** – Well-organized code with single responsibility
- **Model Generation** – JSON serialization via json_serializable with code generation

### Performance Optimizations
- **Lazy Loading** – Screens load data on demand
- **Batch Sync** – 50-item batches reduce network overhead
- **Type Safety** – Dart type system catches errors at compile time
- **Memory Efficient** – Proper state cleanup and resource disposal

---

## 📁 Project Structure

```
fedha/
├── app/                           # Flutter mobile & web app
│   ├── lib/
│   │   ├── main.dart             # App initialization & service setup
│   │   ├── screens/              # 40+ UI screens
│   │   ├── services/             # Core business logic & data
│   │   │   ├── offline_data_service.dart      # Local database CRUD
│   │   │   ├── unified_sync_service.dart      # Batch sync orchestration
│   │   │   ├── auth_service.dart              # Authentication & profile
│   │   │   ├── budget_service.dart            # Budget calculations
│   │   │   └── goal_transaction_service.dart  # Goal progress tracking
│   │   ├── models/               # Domain models (25+ types)
│   │   ├── data/                 # Drift database schema & queries
│   │   ├── widgets/              # Reusable UI components
│   │   ├── utils/                # Helpers (logger, converters)
│   │   └── config/               # Environment & API configuration
│   ├── test/                     # Unit & integration tests
│   └── pubspec.yaml              # Dependencies (Provider, Drift, etc.)
│
├── backend/                       # Django REST API
│   ├── accounts/                 # User profiles & authentication
│   ├── transactions/             # Transaction endpoints & sync
│   ├── budgets/                  # Budget REST API
│   ├── goals/                    # Goal tracking endpoints
│   ├── categories/               # Category management
│   ├── invoicing/                # Invoice generation & management
│   ├── fedha_backend/            # Django settings & URLs
│   └── requirements.txt           # Python dependencies
│
├── web/                          # Optional Node.js web interface
│   ├── src/                      # React/Vue components
│   └── package.json              # Web dependencies
│
└── docs/                         # Documentation
    ├── guides/                   # Architecture guides
    ├── summaries/                # Implementation reports
    └── CONNECTION_GUIDE.md       # Backend setup instructions
```

---

## 🎓 Key Architecture Decisions

### 1. Offline-First Philosophy
Fedha operates without internet first and syncs when available. This means:
- **Zero Latency** for user interactions
- **Complete Offline Functionality** for core features
- **Eventual Consistency** via server-authoritative sync
- **User Privacy** through local-first storage

### 2. Service-Based Architecture
Services are singleton providers with dependency injection:
```dart
// Services initialized once at app startup
AuthService.initialize(offlineDataService, apiClient);
BudgetService.initialize(offlineDataService);
UnifiedSyncService.initialize(offlineDataService, apiClient, authService);
```

### 3. Provider Pattern for State Management
Avoids Redux/Bloc boilerplate while maintaining reactive updates:
```dart
Consumer<BudgetService>(
  builder: (context, budgetService, _) {
    return BudgetCard(budget: budgetService.currentBudget);
  },
)
```

### 4. Type-Safe Database with Drift
Compile-time database code generation:
```dart
// Models are generated from schema
extension TransactionQuery on Database {
  Selectable<Transaction> transactionsByProfile(String profileId) {
    return select(transactions)
      ..where((t) => t.profileId.equals(profileId));
  }
}
```

### 5. Batch Sync for Efficiency
Reduces network roundtrips by batching 50 items per request:
```
Queue: [1..50 items] → POST /api/transactions/batch_sync/
Queue: [51..100 items] → POST /api/transactions/batch_sync/
```

---

## 🔧 Development Tools

### Build Commands
```bash
# Generate models & database
dart run build_runner build

# Run on Android
flutter run -d android

# Build APK
flutter build apk --release

# Run tests
flutter test

# Generate coverage
flutter test --coverage
```

### Backend Commands
```bash
# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Run Django tests
python manage.py test

# Access Django admin
python manage.py createsuperuser
python manage.py runserver
# Navigate to http://localhost:8000/admin/
```

---

## 🎯 For Hiring Managers

This project demonstrates:

### Full-Stack Development
- **Flutter** for cross-platform mobile development
- **Django** for robust backend REST APIs
- **PostgreSQL** for data persistence
- **SQLite** for offline client storage

### Software Engineering Excellence
- **SOLID Principles** – Well-organized, maintainable code
- **Design Patterns** – Service layer, repository pattern, dependency injection
- **Error Handling** – Comprehensive try-catch with logging
- **Testing** – Unit tests, widget tests, integration tests
- **Type Safety** – Dart's strong type system prevents runtime errors

### Product Thinking
- **User-Centric Design** – Intuitive UX for complex financial data
- **Accessibility** – Clear labels, sufficient color contrast
- **Offline-First** – Works in real-world conditions without internet
- **Extensibility** – SMS parsing patterns, custom categories, multiple interest models

### DevOps & Deployment Readiness
- **Multi-Environment Support** – Development, staging, production
- **KMS Integration** – Secure key management with AWS Secrets Manager or Vault
- **Database Migrations** – Django migrations for schema evolution
- **Batch Processing** – Efficient sync operations for scale

### Open Source & Documentation
- Clear code comments explaining complex logic
- Architecture documentation in `/docs`
- README files in each major directory
- Connection guides for backend setup

---

## 📚 Documentation

- **[Architecture Overview](docs/summaries/ARCHITECTURE.md)** – System design and data flow
- **[Connection Guide](docs/summaries/CONNECTION_GUIDE.md)** – Backend setup instructions
- **[Offline Features](docs/summaries/OFFLINE_FEATURES.md)** – Feature availability matrix
- **[SQL Schema](backend/schema.sql)** – Database structure

---

## 📄 License

This project is licensed under the MIT License – see [LICENSE](docs/LICENSE) for details.

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Test your changes: `flutter test`
4. Commit with clear messages: `git commit -m 'Add amazing feature'`
5. Push to your branch and create a Pull Request

---

## 📞 Support & Community

- **Issues** – Found a bug? [Report it on GitHub](https://github.com/moffat-kagiri/fedha/issues)
- **Discussions** – Have questions? Use [GitHub Discussions](https://github.com/moffat-kagiri/fedha/discussions)
- **Documentation** – Check `/docs` for guides and references

---

## 🚀 Roadmap

### Q2 2026
- [ ] Invoice generation and PDF export
- [ ] Multi-user shared budgets
- [ ] Advanced analytics with ML predictions
- [ ] Cryptocurrency transaction support

### Q3 2026
- [ ] Desktop app (Windows, macOS, Linux)
- [ ] Cloud sync with end-to-end encryption
- [ ] API for third-party integrations
- [ ] Advanced reporting and tax exports

---

## 📊 Tech Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.19+ | Cross-platform UI |
| **State Mgmt** | Provider 6.1+ | Reactive state |
| **Database** | Drift + SQLite | Local data persistence |
| **Sync** | UnifiedSyncService | Offline-first sync |
| **Auth** | JWT + Biometric | Secure authentication |
| **Backend** | Django 6.0 | REST API |
| **Storage** | PostgreSQL | Server data |
| **Deployment** | Gunicorn + WhiteNoise | Production serving |
| **Charts** | FL Chart, Syncfusion | Data visualization |

---

**Built with ❤️ by Moffat Kagiri**

*"Intelligent personal finance management, offline-first."*
