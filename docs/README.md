# Fedha Budget Tracker

**Your Personal Finance Companion** 🏦

[![Firebase Deploy](https://github.com/YOUR_USERNAME/fedha/actions/workflows/firebase-deploy.yml/badge.svg)](https://github.com/YOUR_USERNAME/fedha/actions/workflows/firebase-deploy.yml)
[![Firebase Rules](https://img.shields.io/badge/Firestore%20Rules-Deployed-green)](https://console.firebase.google.com/project/fedha-tracker/firestore/rules)
[![Firebase Auth](https://img.shields.io/badge/Firebase%20Auth-Enabled-blue)](https://console.firebase.google.com/project/fedha-tracker/authentication)

A privacy-focused, cross-platform personal and business finance management application designed for individuals and SMEs. Fedha combines advanced financial calculations, intelligent transaction tracking, and comprehensive budget management in a beautiful, offline-first mobile experience.

**Current Status:** 90% Complete - Advanced Development Phase  
**Last Updated:** June 15, 2025

---

## 🎯 Project Overview

Fedha is an advanced financial management platform that prioritizes user privacy while delivering professional-grade features. Built with Flutter for mobile-first experience, the app operates entirely offline with optional cloud synchronization.

### 🚀 Recent Major Achievement

✅ **Transaction Ingestion System Completed** - Smart SMS text recognition and progressive CSV upload capabilities with complete privacy protection.

---

## 📁 Documentation Structure

### Core Documentation

- [`roadmap.md`](roadmap.md) - Development roadmap and project phases (90% complete)
- [`README.md`](README.md) - This comprehensive project guide

### 📖 Implementation Guides

Professional technical documentation in [`guides/`](guides/):

- [`TRANSACTION_INGESTION_IMPLEMENTATION.md`](guides/TRANSACTION_INGESTION_IMPLEMENTATION.md) - Complete SMS & CSV system implementation
- [`TRANSACTION_INGESTION_ARCHITECTURE.md`](guides/TRANSACTION_INGESTION_ARCHITECTURE.md) - Privacy-first system architecture
- [`TRANSACTION_INGESTION_ALTERNATIVES.md`](guides/TRANSACTION_INGESTION_ALTERNATIVES.md) - Alternative implementation approaches
- [`api-reference.md`](guides/api-reference.md) - API endpoints and integration guide
- [`PRIVACY_POLICY.md`](guides/PRIVACY_POLICY.md) - Data protection and privacy guidelines

### 📊 Status Reports & Summaries

Project progress documentation in [`summaries/`](summaries/):

- [`PROJECT_FINAL_STATUS_JUNE_2025.md`](summaries/PROJECT_FINAL_STATUS_JUNE_2025.md) - **Current project status overview**
- [`TRANSACTION_INGESTION_FINAL_COMPLETION.md`](summaries/TRANSACTION_INGESTION_FINAL_COMPLETION.md) - **Latest feature completion report**
- [`SESSION_COMPLETION_JUNE_15_2025.md`](summaries/SESSION_COMPLETION_JUNE_15_2025.md) - Recent development session summary
- [`SMART_GOALS_COMPLETION_REPORT.md`](summaries/SMART_GOALS_COMPLETION_REPORT.md) - Goals system implementation
- [`GOAL_TRANSACTION_INTEGRATION_REPORT.md`](summaries/GOAL_TRANSACTION_INTEGRATION_REPORT.md) - Feature integration summary

---

## 🏦 About Fedha Budget Tracker

### Core Philosophy

- **Privacy-First Design**: All sensitive processing happens on-device
- **Offline-Capable**: Full functionality without internet connectivity
- **User-Centric**: Intuitive interfaces with comprehensive feedback
- **Business-Ready**: Professional features for SME financial management

### Technology Stack

**Frontend:**

- **Flutter 3.7+** - Cross-platform mobile development with Dart
- **Material Design 3** - Modern, accessible user interface

**Backend:**

- **Django REST Framework** - Robust API development
- **Python 3.11+** - Financial calculations and business logic

**Database:**

- **Hive** - Local offline storage for mobile app
- **SQLite/PostgreSQL** - Backend data persistence

**Key Dependencies:**

- **Flutter**: `hive_flutter`, `provider`, `syncfusion_flutter_charts`, `permission_handler`, `file_picker`, `csv`
- **Python**: `django`, `djangorestframework`, `numpy`, `scipy`

---

## ✨ Key Features

### Core Financial Management

- **UUID-based Authentication**: Complete privacy with randomized profile IDs
- **Offline-First Design**: Hive database ensures functionality without internet
- **Multi-Profile Support**: Separate business and personal financial tracking
- **Real-time Analytics**: Live financial health indicators and insights

### Advanced Financial Tools

- **Loan Calculators**:
  - Total cost of credit calculation with multiple interest models
  - Reverse interest rate calculation from known repayment amounts
  - Amortization schedule generation
  - API-based complex financial calculations
- **Investment Tracking**: ROI calculations and portfolio performance monitoring
- **Goal Setting**: Financial targets with progress tracking and projections

### Transaction Management

- **Smart Text Recognition**: On-device SMS analysis for transaction detection
- **Progressive CSV Upload**: Bulk import with real-time validation
- **Intelligent Categorization**: Auto-assignment based on merchant patterns
- **Duplicate Detection**: Automatic identification and handling of duplicate transactions

### Business Features

- **Invoice Management**:
  - Professional invoice generation
  - Payment tracking and reminders
  - Client management system
- **Cash Flow Analysis**: SME-focused financial reporting
- **Tax Preparation**: Transaction categorization for compliance

### Privacy & Security

- **On-Device Processing**: SMS and sensitive data never leave the device
- **PIN-based Authentication**: Secure 4-digit PIN with salted hashing
- **Encrypted Local Storage**: All data encrypted at rest
- **No Cloud Dependency**: Full functionality offline

---

## 📂 Project Structure

```bash
fedha/
├── app/                          # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart            # Application entry point
│   │   ├── models/              # Data models with Hive adapters
│   │   │   ├── profile.dart     # User profile model
│   │   │   ├── transaction.dart # Transaction model
│   │   │   ├── goal.dart        # Financial goal model
│   │   │   ├── loan.dart        # Loan tracking model
│   │   │   └── csv_upload_result.dart # CSV processing models
│   │   ├── screens/             # Application screens
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── transaction_screen.dart
│   │   │   ├── text_recognition_setup_screen.dart
│   │   │   ├── csv_upload_screen.dart
│   │   │   └── calculator_screen.dart
│   │   ├── services/            # Business logic services
│   │   │   ├── hive_service.dart # Local database management
│   │   │   ├── transaction_service.dart # Transaction operations
│   │   │   ├── text_recognition_service.dart # SMS processing
│   │   │   └── csv_upload_service.dart # CSV import handling
│   │   ├── widgets/             # Reusable UI components
│   │   └── utils/               # Utility functions and themes
│   ├── assets/                  # Application assets
│   │   ├── icons/              # SVG icons and logos
│   │   ├── images/             # Image assets
│   │   └── fonts/              # Custom fonts
│   └── pubspec.yaml            # Flutter dependencies
│
├── backend/                     # Django REST API Backend
│   ├── manage.py               # Django management script
│   ├── requirements.txt        # Python dependencies
│   ├── api/                    # Main API application
│   │   ├── models.py          # Database models
│   │   ├── serializers.py     # API serializers
│   │   ├── views.py           # API endpoints
│   │   └── migrations/        # Database migrations
│   └── backend/               # Django project settings
│
├── calculators-microservice/   # Financial Calculation Engine
│   ├── interest_calculator.py # Loan and interest calculations
│   └── requirements.txt       # Scientific computing dependencies
│
├── web/                       # React.js Web Application (Planned)
│   ├── src/                   # React source code
│   └── package.json          # Node.js dependencies
│
└── docs/                      # Project Documentation
    ├── roadmap.md            # Development roadmap
    ├── guides/               # Technical implementation guides
    └── summaries/            # Status reports and completion summaries
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK 3.7+** with Dart 3.7+
- **Android Studio** or **VS Code** with Flutter extension
- **Python 3.11+** for backend development
- **Git** for version control

### Quick Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/your-username/fedha.git
cd fedha
```

#### 2. Mobile App Setup (Flutter)

```bash
cd app
flutter pub get
flutter doctor        # Verify setup
flutter run           # Launch on connected device/emulator
```

#### 3. Backend Setup (Django) - Optional

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate    # Windows
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 8000
```

#### 4. Generate Required Files

```bash
cd app
flutter packages pub run build_runner build    # Generate Hive adapters
```

### Development Environment

- **Primary Platform**: Android (Flutter)
- **Development IDE**: Android Studio or VS Code
- **Testing**: Flutter test framework with device emulators
- **Database**: Hive for local storage, SQLite for backend testing

---

## 📱 App Features Overview

### Dashboard

- Financial overview with charts and insights
- Recent transactions and budget status
- Quick access to calculators and tools
- Goal progress tracking

### Transaction Management

- Manual transaction entry with smart categorization
- SMS-based automatic transaction detection
- CSV bulk import with validation
- Advanced search and filtering

### Tools & Calculators

- Comprehensive loan calculators
- Interest rate solvers
- Investment return calculators
- Goal planning tools

### Settings & Privacy

- Profile management (business/personal)
- Privacy controls and permissions
- Data export and backup options
- Security settings

---

## 🔒 Privacy & Security

### Privacy-First Architecture

- **On-Device Processing**: All SMS analysis happens locally
- **No Cloud Transmission**: Sensitive data never leaves your device
- **UUID-Based IDs**: No personal information in identifiers
- **Permission-Based**: Explicit user consent for all data access

### Security Features

- **Encrypted Storage**: All local data encrypted with device security
- **PIN Authentication**: Secure 4-digit PIN with salt + hash
- **Session Management**: Automatic logout for security
- **Data Isolation**: Business and personal profiles completely separate

---

## 📈 Development Roadmap

### ✅ Completed Phases (90% Overall)

- **Phase 1**: Foundation & Core Infrastructure (100%)
- **Phase 2**: Core Financial Features (100%)
- **Phase 3**: Transaction Ingestion Pipeline (100%)

### 🔄 Current Phase

- **Phase 4**: Enhanced Analytics & Intelligence
  - Machine learning for spending patterns
  - Predictive analytics for budget optimization
  - Advanced reporting and insights

### 🔮 Future Enhancements

- iOS platform support
- Web application for business users
- Third-party bank integrations (with user consent)
- Advanced security features (biometric authentication)

---

## 🤝 Contributing

We welcome contributions to make Fedha even better!

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines

- Follow Flutter best practices and conventions
- Maintain privacy-first architecture principles
- Include comprehensive tests for new features
- Update documentation for significant changes

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](../LICENSE) file for details.

---

## 📞 Support & Contact

### Getting Help

- **Documentation**: Check the [`guides/`](guides/) folder for technical documentation
- **Issues**: Open an issue on GitHub for bug reports or feature requests
- **Status**: Check [`summaries/`](summaries/) for current project status

### Project Status

- **Current Version**: 1.0.0+1
- **Development Stage**: Advanced (90% complete)
- **Production Readiness**: Core features ready for deployment
- **Next Milestone**: Enhanced Analytics & Intelligence features

---

**Built with ❤️ for privacy-conscious users who demand professional-grade financial management tools.**
