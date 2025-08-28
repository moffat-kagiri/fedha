# Fedha – Personal Finance Tracker

Fedha is a cross-platform (iOS, Android, Web, Desktop) personal finance app with:
- Offline-first storage (Hive)
- Secure authentication (password + biometric)
- SMS transaction ingestion (Android native + iOS fallback)
- Advanced loan & APR calculators
- Budget, goal, and multi-currency support

## 🚀 Quick Start

Prerequisites:
- Flutter SDK ≥3.7
- Dart SDK (bundled with Flutter)
- Python ≥3.8 for backend
- Node.js ≥16 for web (optional)
- Git

### 1. Clone & Setup
```bash
git clone https://github.com/moffat-kagiri/fedha.git
cd fedha/app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Android/iOS 
```bash
flutter run -d android   # or -d ios on macOS
```

### 3. Web (optional)
```bash
cd ../web && npm install && npm start
```

### 4. Backend (Django)
```bash
cd ../backend
python -m venv .venv && .venv/Scripts/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## Android Permissions

Be sure your AndroidManifest.xml includes:

```bash
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
```

## 🗂️ Project Structure

```txt
fedha/
├─ app/           Flutter mobile & desktop
├─ backend/       Django REST API
├─ web/           React web frontend
└─ docs/          Guides, [ROADMAP.md](http://_vscodecontentref_/3)
```

## ✔️ Current Status

 - Core features (auth, CRUD, sync, loan calculator) – ✅ Done
 - SMS ingestion (Android) – ✅ Done
 - SMS ingestion (iOS fallback UI) – ⚠️ Incomplete, needs wiring
 - Biometric auth flow – ✅ Done
 - Language-model SMS parsing – 🚧 In progress