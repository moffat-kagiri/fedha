# Fedha Budget Tracker

A privacy-focused cross-platform budget tracker for SMEs and personal finance, offering advanced financial calculators, goal tracking, and cash flow analysis. Built with **Flutter (Android)**, **React.js (Web)**, **Django (Backend)**, and **Python (Financial Microservice)**.

---

## **Project Structure**

```bash
Fedha-Budget-Tracker/
├── app/ # Flutter Mobile App (Android)
│ ├── lib/
│ │ ├── models/ # Data classes (Transaction, Loan, Goal)
│ │ ├── services/ # Business logic & utilities
│ │ │ ├── auth_service.dart # UUID/PIN management
│ │ │ ├── local_db.dart # Hive (offline storage)
│ │ │ └── api_client.dart # Backend communication
│ │ ├── widgets/ # Reusable UI components
│ │ ├── screens/ # App screens (Dashboard, Transactions, etc.)
│ │ └── main.dart # App entry point
│ ├── assets/ # Icons, fonts, localization files
│ └── pubspec.yaml # Flutter dependencies
│
├── web/ # React.js Web App
│ ├── src/
│ │ ├── components/ # React components (Dashboard, Forms)
│ │ ├── contexts/ # State management (Auth, Data)
│ │ ├── hooks/ # Custom hooks (e.g., useLoans)
│ │ ├── utils/ # Calculators, UUID generator, formatters
│ │ └── App.js # Main router
│ ├── public/ # Static assets
│ └── package.json # Web dependencies
│
├── backend/ # Django Backend
│ ├── fedha/
│ │ ├── settings.py # Django config
│ │ ├── urls.py # API routes
│ │ └── wsgi.py
│ ├── api/
│ │ ├── models.py # Database schemas
│ │ ├── serializers.py # Data serialization
│ │ ├── views.py # API controllers
│ │ └── utils/ # Data sync, error handling
│ ├── manage.py
│ └── requirements.txt # Python dependencies
│
├── calculators-microservice/ # Python Financial Logic
│ ├── interest_calculator.py # Loan/interest solvers
│ └── requirements.txt # numpy, scipy
│
└── docs/ # Project documentation
├── roadmap.md # Development checklist
└── api-reference.md # Backend endpoints
```

---

## **Setup Guide**

### **1. Flutter Mobile App**
**Prerequisites**:
- Flutter 3.19+ and Dart 3.3+
- Android Studio/Xcode

**Steps**:
```bash
cd app
flutter pub get  # Install dependencies
flutter run      # Launch app
```

### **2. React Web App**
**Prerequisites**:

Node.js 18+

Steps:

```bash
cd web
npm install      # Install packages
npm start        # Start dev server
```

### **3. Django Backend**
Prerequisites:

-- Python 3.11+

-- PostgreSQL

Steps:

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Linux/macOS) or venv\Scripts\activate (Windows)
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

### **4. Python Calculators Microservice**

```bash
cd calculators-microservice
pip install -r requirements.txt
# Integrate via API (see backend/api/services/calculator_service.py)
```

## **Key Features**

**UUID Authentication**: Randomized user/business IDs (e.g., biz_8a7d2f).

**Offline Support**: Hive database for mobile app.

**Loan Calculators**:

Total repayment schedule from principal/rate.

Interest rate reverse-calculation from repayments.

Sync: Real-time updates between app and web via Django REST API.

## **Environment Variables**
Create .env files as needed:

``` bash
ini
# backend/.env
DATABASE_URL=postgres://user:pass@localhost:5432/fedha
SECRET_KEY=django-secret-key
```

## **Dependencies**

**Flutter**: hive, flutter_bloc, http, syncfusion_flutter_charts

**React**: axios, recharts, react-query, zustand

**Django**: djangorestframework, django-cors-headers, psycopg2

**Python**: numpy, scipy (for numerical solvers)
