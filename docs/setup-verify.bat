@echo off
REM Fedha Setup Verification Script for Windows
REM Run this after cloning to verify everything is properly configured

echo 🚀 Fedha Setup Verification
echo ================================

REM Check Flutter
echo 📱 Checking Flutter...
where flutter >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ Flutter found
    flutter --version | findstr "Flutter"
    cd app
    echo 📦 Installing Flutter dependencies...
    flutter pub get
    echo 🔧 Generating Hive adapters...
    flutter pub run build_runner build --delete-conflicting-outputs
    echo 🔍 Running Flutter analysis...
    flutter analyze --no-fatal-infos
    echo ✅ Flutter setup complete
    cd ..
) else (
    echo ❌ Flutter not found. Please install Flutter SDK.
)

REM Check Python
echo 🐍 Checking Python...
where python >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ Python found
    python --version
    cd backend
    if not exist ".venv" (
        echo 📦 Creating virtual environment...
        python -m venv .venv
    )
    echo 📦 Installing Python dependencies...
    call .venv\Scripts\activate.bat
    pip install -r requirements.txt
    echo 🗄️ Setting up database...
    python manage.py migrate
    echo ✅ Backend setup complete
    cd ..
) else (
    echo ❌ Python not found. Please install Python 3.8+.
)

REM Check Node.js
echo 🌐 Checking Node.js...
where node >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ Node.js found
    node --version
    if exist "web" (
        cd web
        echo 📦 Installing Node.js dependencies...
        npm install
        echo ✅ Web setup complete
        cd ..
    )
) else (
    echo ⚠️ Node.js not found. Web frontend will not be available.
)

echo ================================
echo 🎉 Setup verification complete!
echo.
echo Next steps:
echo 1. Run 'flutter run' in the app/ directory
echo 2. Run 'python manage.py runserver' in the backend/ directory  
echo 3. Run 'npm start' in the web/ directory (if using web frontend)
pause
