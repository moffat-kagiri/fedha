# Fedha Budget Tracker

A privacy-focused cross-platform business and personal finance management system designed for SMEs and individuals. 
Features advanced financial calculators, invoice management, tax preparation, cash flow analysis, and comprehensive budget tracking. 
Built with **Flutter (Android)**, **React.js (Web)**, **Django (Backend)**, and **Python (Financial Microservice)**.

---

## **Key Features**

### **Core Financial Management**
- **UUID-based Authentication**: Complete privacy with randomized business/personal profile IDs
- **Offline-First Design**: Hive database ensures functionality without internet connectivity
- **Cross-Platform Sync**: Real-time data synchronization between mobile and web platforms
- **Multi-Profile Support**: Separate business and personal financial tracking

### **Advanced Financial Tools**
- **Loan Calculators**: 
  - Total cost of credit calculation with multiple interest models (simple, reducing balance)
  - Reverse interest rate calculation from known repayment amounts
  - Amortization schedule generation
- **Investment Tracking**: ROI calculations and portfolio performance monitoring
- **Goal Setting**: Financial targets with progress tracking and projections

### **Business Features**
- **Invoice Management**: 
  - Professional invoice generation with customizable templates
  - Invoice tracking (sent, paid, overdue)
  - Client management and payment history
  - Automated payment reminders
- **Cash Flow Statements**: SME-focused operating, investing, and financing activity tracking
- **Tax Preparation**: 
  - Transaction categorization for tax compliance
  - Automated tax report generation
  - Deductible expense tracking
  - Multi-period tax summaries

### **Analytics & Reporting**
- **Financial Ratios**: Liquidity, profitability, and efficiency metrics for businesses
- **Trend Analysis**: Historical data visualization and forecasting
- **Export Capabilities**: CSV/PDF reports for accountants and stakeholders
- **Dashboard Analytics**: Real-time financial health indicators

---

## **Project Structure**

```bash
fedha/
├── app/                           # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart             # Application entry point
│   │   ├── models/               # Data models with Hive adapters
│   │   │   ├── profile.dart      # User profile model
│   │   │   ├── transaction.dart  # Transaction model
│   │   │   ├── invoice.dart      # Invoice model
│   │   │   ├── loan.dart         # Loan model
│   │   │   └── tax_record.dart   # Tax record model
│   │   ├── screens/              # Application screens
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── transaction_screen.dart
│   │   │   ├── invoice_screen.dart
│   │   │   ├── tax_screen.dart
│   │   │   └── calculator_screen.dart
│   │   ├── services/             # Business logic services
│   │   │   ├── hive_service.dart # Local database management
│   │   │   ├── api_service.dart  # Backend communication
│   │   │   ├── invoice_service.dart # Invoice operations
│   │   │   └── tax_service.dart  # Tax calculations
│   │   ├── widgets/              # Reusable UI components
│   │   └── utils/                # Utility functions
│   ├── assets/                   # Application assets
│   │   ├── fonts/               # Custom fonts
│   │   ├── icons/               # SVG icons
│   │   ├── images/              # Image assets
│   │   └── logos/               # Brand logos
│   ├── android/                 # Android platform configuration
│   ├── ios/                     # iOS platform configuration
│   └── pubspec.yaml            # Flutter dependencies
│
├── backend/                     # Django REST API Backend
│   ├── manage.py               # Django management script
│   ├── requirements.txt        # Python dependencies
│   ├── api/                    # Main API application
│   │   ├── models.py          # Database models
│   │   ├── serializers.py     # API serializers
│   │   ├── views.py           # API endpoints
│   │   ├── urls.py            # URL routing
│   │   ├── admin.py           # Admin interface
│   │   ├── migrations/        # Database migrations
│   │   └── utils/             # Utility functions
│   └── backend/               # Django project settings
│       ├── settings.py        # Application configuration
│       ├── urls.py           # Root URL configuration
│       └── wsgi.py           # WSGI application
│
├── web/                       # React.js Web Application
│   ├── src/
│   │   ├── App.js            # Main application component
│   │   ├── components/       # React components
│   │   │   ├── Dashboard/    # Dashboard components
│   │   │   ├── Invoices/     # Invoice management
│   │   │   ├── Transactions/ # Transaction components
│   │   │   └── Tax/          # Tax preparation components
│   │   ├── contexts/         # React context providers
│   │   ├── hooks/           # Custom React hooks
│   │   └── utils/           # Utility functions
│   ├── public/              # Static assets
│   └── package.json         # Node.js dependencies
│
├── calculators-microservice/ # Financial Calculation Engine
│   ├── interest_calculator.py # Loan and interest calculations
│   ├── tax_calculator.py     # Tax computation logic
│   └── requirements.txt      # Python scientific dependencies
│
├── test_flows/              # Testing framework
│   ├── api_tests/          # API integration tests
│   └── e2e/               # End-to-end testing
│
└── docs/                   # Project documentation
    ├── api-reference.md    # API documentation
    └── roadmap.md         # Development roadmap
```

---

## **Setup Guide**

### **Prerequisites**
- **Flutter SDK 3.19+** with Dart 3.3+
- **Node.js 18+** for web development
- **Python 3.11+** with pip
- **PostgreSQL 14+** (or SQLite for development)
- **Android Studio** or **VS Code** with Flutter extension

### **1. Backend Setup (Django)**

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# Database setup
python manage.py migrate
python manage.py createsuperuser  # Optional: for admin access
python manage.py runserver 8000
```

### **2. Mobile App Setup (Flutter)**

```powershell
cd app
flutter pub get
flutter doctor  # Verify setup
flutter run     # Launch on connected device/emulator
```

### **3. Web App Setup (React.js)**

```powershell
cd web
npm install
npm start       # Starts development server on port 3000
```

### **4. Financial Calculators Microservice**

```powershell
cd calculators-microservice
pip install -r requirements.txt
# Integration handled via Django backend API calls
```

---

## **Database Schema Overview**

The application uses an enhanced database schema designed for comprehensive financial management:

### **Core Models**
- **Profile**: Business/Personal account management with UUID-based privacy
- **Transaction**: Income/expense tracking with advanced categorization
- **Invoice**: Professional invoice generation and management
- **Loan**: Complex loan tracking with multiple interest calculation models
- **TaxRecord**: Automated tax preparation and compliance tracking
- **Goal**: Financial target setting and progress monitoring

### **Advanced Features**
- **Hierarchical Categories**: Parent-child category relationships for detailed classification
- **Multi-Currency Support**: International business transaction handling
- **Recurring Transactions**: Automated transaction scheduling
- **Asset Management**: Depreciation tracking for business assets
- **Client Management**: Customer relationship tracking for invoicing

---

## **API Endpoints**

### **Authentication**
- `POST /api/profiles/` - Create new profile
- `POST /api/auth/verify-pin/` - PIN verification

### **Financial Management**
- `GET/POST /api/transactions/` - Transaction CRUD operations
- `GET/POST /api/invoices/` - Invoice management
- `GET/POST /api/loans/` - Loan tracking
- `GET /api/tax-reports/` - Tax preparation reports

### **Analytics**
- `GET /api/dashboard/summary/` - Financial overview
- `GET /api/reports/cash-flow/` - Cash flow statements
- `GET /api/analytics/trends/` - Financial trend analysis

---

## **Environment Configuration**

Create environment files for each component:

### **Backend (.env)**
```env
DEBUG=True
SECRET_KEY=your-django-secret-key
DATABASE_URL=postgresql://user:password@localhost:5432/fedha
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

### **Web (.env.local)**
```env
REACT_APP_API_BASE_URL=http://localhost:8000/api
REACT_APP_ENV=development
```

---

## **Technology Stack**

### **Frontend**
- **Flutter**: Cross-platform mobile development with Dart
- **React.js**: Modern web application with hooks and context
- **Material Design**: Consistent UI/UX across platforms

### **Backend**
- **Django REST Framework**: Robust API development
- **PostgreSQL**: Production-grade database with advanced features
- **Hive**: Local offline storage for mobile app

### **Financial Engine**
- **NumPy/SciPy**: Advanced mathematical calculations
- **Custom Algorithms**: Loan amortization and interest rate solving

### **Key Dependencies**
- **Flutter**: `hive_flutter`, `provider`, `http`, `syncfusion_flutter_charts`, `pdf`
- **React**: `axios`, `recharts`, `react-query`, `material-ui`, `jspdf`
- **Django**: `djangorestframework`, `django-cors-headers`, `psycopg2-binary`, `celery`
- **Python**: `numpy`, `scipy`, `pandas`, `reportlab`

---

## **Security & Privacy**

- **No Personal Data Collection**: Only UUID-based identification
- **PIN-based Authentication**: Secure 4-digit PIN with salted hashing
- **Offline-First Design**: Data remains on device until explicitly synced
- **Encrypted Local Storage**: Sensitive data protection on mobile devices
- **API Security**: JWT tokens and CSRF protection

---

## **Contributing**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## **License**

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## **Support**

For support, feature requests, or bug reports, please open an issue on GitHub or contact the development team.
