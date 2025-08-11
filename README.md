# Fedha - Personal Finance Tracker

A comprehensive personal finance management application built with Flutter, Django, and modern web technologies.

## 🚀 Quick Start

This repository contains everything needed to compile and run Fedha on any machine. Follow the setup instructions below.

## 📋 Prerequisites

### Required Software
- **Flutter SDK** (≥3.7.0): [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Python** (≥3.8): [Install Python](https://python.org/downloads/)
- **Node.js** (≥16): [Install Node.js](https://nodejs.org/) (for web frontend)
- **Git**: [Install Git](https://git-scm.com/downloads)

### Platform-Specific Requirements
- **Android**: Android Studio or Android SDK
- **iOS**: Xcode (macOS only)
- **Web**: Any modern browser

## 🛠️ Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/moffat-kagiri/fedha.git
cd fedha
```

### 2. Setup Flutter App
```bash
cd app

# Install dependencies
flutter pub get

# Generate required Hive adapter files
flutter pub run build_runner build

# Verify setup
flutter doctor
flutter analyze

# Run on your preferred platform
flutter run                    # Default platform
flutter run -d chrome         # Web
flutter run -d android        # Android
flutter run -d ios           # iOS (macOS only)
```

### 3. Setup Django Backend
```bash
cd ../backend

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Setup environment variables
cp .env.example .env
# Edit .env file with your settings

# Setup database
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser

# Run development server
python manage.py runserver
```

### 4. Setup Web Frontend (Optional)
```bash
cd ../web

# Install dependencies
npm install

# Start development server
npm start
```

## 📁 Project Structure

```
fedha/
├── app/                    # Flutter mobile application
│   ├── lib/               # Dart source code
│   ├── assets/            # Images, fonts, icons
│   ├── android/           # Android platform code
│   ├── ios/               # iOS platform code
│   └── web/               # Web platform code
├── backend/               # Django REST API
│   ├── api/               # API endpoints
│   ├── fedha/             # Django project settings
│   └── requirements.txt   # Python dependencies
├── web/                   # React web frontend
│   ├── src/               # React source code
│   └── package.json       # Node.js dependencies
└── docs/                  # Documentation
```

## 🔧 Key Features

- **Multi-platform**: iOS, Android, Web, Desktop
- **Offline Support**: Hive local database with sync
- **Biometric Authentication**: Secure app access
- **SMS Transaction Import**: Auto-import M-PESA/bank transactions
- **Loan Calculator**: Advanced interest calculations
- **Budget Tracking**: 50/30/20 methodology
- **Goal Management**: SMART financial goals
- **Multi-currency**: Support for various currencies

## 🗄️ Database & Storage

### Local Storage (Flutter)
- **Hive**: NoSQL local database for offline functionality
- **Generated Files**: `.g.dart` files are included for compilation stability

### Backend Database (Django)
- **Default**: SQLite (for development)
- **Production**: PostgreSQL/MySQL (configure in .env)

## 🔐 Security & Configuration

### Environment Variables
1. Copy `.env.example` to `.env` in the backend directory
2. Update with your specific settings:
   - `SECRET_KEY`: Django secret key
   - `DEBUG`: Set to False in production
   - `DATABASE_URL`: Database connection (if not using SQLite)
   - `ALLOWED_HOSTS`: Comma-separated list of allowed hosts

### API Keys & Secrets
- Store sensitive data in `.env` files (not tracked in git)
- Use environment variables for production deployment

### Cloudflare Tunnel Setup
For development and testing with mobile devices:

1. Install Cloudflared:
   ```bash
   # Windows
   choco install cloudflared

   # macOS
   brew install cloudflared
   
   # Linux
   curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
   chmod +x cloudflared
   ```

2. Start your Django backend server:
   ```bash
   cd backend
   python manage.py runserver
   ```

3. Create a tunnel to expose your local server:
   ```bash
   # In a new terminal
   cloudflared tunnel --url http://localhost:8000
   ```
   
4. Update the app to use the tunnel URL:
   ```powershell
   # Windows
   .\update_tunnel.ps1 "your-tunnel-name.trycloudflare.com"
   
   # Linux/macOS
   ./update_tunnel.sh "your-tunnel-name.trycloudflare.com"
   ```

This enables testing your app on physical devices without exposing your development machine to the internet.

## 🚨 Troubleshooting

### Common Issues

**Flutter Build Errors:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Missing .g.dart files:**
```bash
# Generate Hive adapters
flutter pub run build_runner build
```

**Backend Database Issues:**
```bash
# Reset database
python manage.py migrate --run-syncdb
```

**Dependency Conflicts:**
```bash
# Flutter
flutter pub deps
flutter pub upgrade

# Python
pip install --upgrade -r requirements.txt

# Node.js
npm update
```

**Cloudflare Tunnel Issues:**
```powershell
# When your tunnel URL changes (they expire after terminal sessions end)
# Windows
.\update_tunnel.ps1 "new-tunnel-name.trycloudflare.com"

# Linux/macOS
./update_tunnel.sh "new-tunnel-name.trycloudflare.com"
```

## 📱 Supported Platforms

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Web** (Modern browsers)
- ✅ **Windows** (Desktop)
- ✅ **macOS** (Desktop)
- ✅ **Linux** (Desktop)

## 🔄 Development Workflow

1. **Code Changes**: Make changes in respective directories
2. **Testing**: Run `flutter test` and `python manage.py test`
3. **Code Generation**: Run build_runner for Hive models
4. **Linting**: `flutter analyze` and `pylint`
5. **Build**: Platform-specific builds for deployment

## 📄 License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## 📞 Support

- **Documentation**: Check the `docs/` directory
- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Use GitHub Discussions for questions

---

**Note**: This codebase is designed to be stable and compilable out of the box. All necessary generated files and dependencies are properly configured for cross-machine compatibility.
