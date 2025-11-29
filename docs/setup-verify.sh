#!/bin/bash
# Fedha Setup Verification Script
# Run this after cloning to verify everything is properly configured

echo "🚀 Fedha Setup Verification"
echo "================================"

# Check Flutter
echo "📱 Checking Flutter..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter found: $(flutter --version | head -n1)"
    cd app
    echo "📦 Installing Flutter dependencies..."
    flutter pub get
    echo "🔧 Generating Hive adapters..."
    flutter pub run build_runner build --delete-conflicting-outputs
    echo "🔍 Running Flutter analysis..."
    flutter analyze --no-fatal-infos
    echo "✅ Flutter setup complete"
    cd ..
else
    echo "❌ Flutter not found. Please install Flutter SDK."
fi

# Check Python
echo "🐍 Checking Python..."
if command -v python &> /dev/null || command -v python3 &> /dev/null; then
    PYTHON_CMD=$(command -v python3 || command -v python)
    echo "✅ Python found: $($PYTHON_CMD --version)"
    cd backend
    if [ ! -d ".venv" ]; then
        echo "📦 Creating virtual environment..."
        $PYTHON_CMD -m venv .venv
    fi
    echo "📦 Installing Python dependencies..."
    source .venv/bin/activate 2>/dev/null || .venv/Scripts/activate
    pip install -r requirements.txt
    echo "🗄️ Setting up database..."
    python manage.py migrate
    echo "✅ Backend setup complete"
    cd ..
else
    echo "❌ Python not found. Please install Python 3.8+."
fi

# Check Node.js (for web)
echo "🌐 Checking Node.js..."
if command -v node &> /dev/null; then
    echo "✅ Node.js found: $(node --version)"
    if [ -d "web" ]; then
        cd web
        echo "📦 Installing Node.js dependencies..."
        npm install
        echo "✅ Web setup complete"
        cd ..
    fi
else
    echo "⚠️ Node.js not found. Web frontend will not be available."
fi

echo "================================"
echo "🎉 Setup verification complete!"
echo ""
echo "Next steps:"
echo "1. Run 'flutter run' in the app/ directory"
echo "2. Run 'python manage.py runserver' in the backend/ directory"
echo "3. Run 'npm start' in the web/ directory (if using web frontend)"
