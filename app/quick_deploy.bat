@echo off
REM Quick Firebase Deployment Script
REM Simple version for immediate testing

echo 🚀 Quick Firebase Deployment
echo ==============================

REM Check if in correct directory
if not exist "pubspec.yaml" (
    echo ❌ Please run from app directory ^(where pubspec.yaml is located^)
    pause
    exit /b 1
)

echo ℹ️ Step 1: Cleaning project...
flutter clean

echo ℹ️ Step 2: Getting dependencies...
flutter pub get

echo ℹ️ Step 3: Deploying Firestore rules...
firebase deploy --only firestore:rules --project fedha-tracker

echo ℹ️ Step 4: Running tests...
flutter test

echo ℹ️ Step 5: Building APK...
flutter build apk --release

echo ✅ Deployment complete!
echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk

echo.
echo Press any key to open APK location...
pause >nul
explorer /select,"build\app\outputs\flutter-apk\app-release.apk"
