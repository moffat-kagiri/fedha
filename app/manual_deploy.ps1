# Firebase Manual Deployment Script (PowerShell)
# This script replicates the GitHub Actions workflow for local testing

param(
    [switch]$SkipTests,
    [switch]$DebugBuild
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Firebase Manual Deployment..." -ForegroundColor Green
Write-Host "=============================================="

# Helper functions for colored output
function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "⚠️ $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "❌ $message" -ForegroundColor Red
}

function Write-Info($message) {
    Write-Host "ℹ️ $message" -ForegroundColor Cyan
}

# Check if we're in the right directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Error "Please run this script from the app directory (where pubspec.yaml is located)"
    exit 1
}

try {
    # Step 1: Verify versions
    Write-Host ""
    Write-Info "Step 1: Verifying Flutter and Dart versions..."
    Write-Host "Flutter version:"
    flutter --version
    Write-Host ""
    Write-Host "Dart version:"
    dart --version
    Write-Host ""

    # Step 2: Clean and get dependencies
    Write-Host ""
    Write-Info "Step 2: Resolving Flutter dependencies..."
    Write-Host "📦 Cleaning previous build..."
    flutter clean

    Write-Host "📦 Getting dependencies..."
    flutter pub get
    Write-Success "Dependencies resolved successfully!"

    Write-Host "📋 Dependency tree:"
    flutter pub deps --style=compact

    # Step 3: Check for Firebase CLI
    Write-Host ""
    Write-Info "Step 3: Checking Firebase CLI..."
    try {
        $firebaseVersion = firebase --version 2>$null
        Write-Success "Firebase CLI found: $firebaseVersion"
    }
    catch {
        Write-Warning "Firebase CLI not found. Please install with:"
        Write-Host "npm install -g firebase-tools"
        Write-Host "Or download from: https://firebase.google.com/docs/cli"
        throw "Firebase CLI required"
    }

    # Step 4: Deploy Firestore Rules
    Write-Host ""
    Write-Info "Step 4: Deploying Firestore security rules..."
    
    $firebaseToken = $env:FIREBASE_TOKEN
    if (-not $firebaseToken) {
        Write-Warning "FIREBASE_TOKEN environment variable not set."
        Write-Host "Please run: firebase login:ci"
        Write-Host "Then set: `$env:FIREBASE_TOKEN='your_token'"
        Write-Host ""
        Write-Host "Attempting to deploy with login authentication..."
        firebase deploy --only firestore:rules --project fedha-tracker
    }
    else {
        Write-Success "Using FIREBASE_TOKEN for authentication..."
        firebase deploy --only firestore:rules --project fedha-tracker --token $firebaseToken
    }

    # Step 5: Run tests (optional)
    if (-not $SkipTests) {
        Write-Host ""
        Write-Info "Step 5: Running Flutter tests..."
        flutter test
        Write-Success "All tests passed!"
    }
    else {
        Write-Warning "Skipping tests (--SkipTests flag provided)"
    }

    # Step 6: Build APK
    Write-Host ""
    Write-Info "Step 6: Building APK..."
    
    if ($DebugBuild) {
        Write-Info "Building debug APK..."
        flutter build apk --debug
        $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
    }
    else {
        Write-Info "Building release APK..."
        flutter build apk --release
        $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    }
    
    Write-Success "APK built successfully!"

    # Show APK location
    if (Test-Path $apkPath) {
        $apkSize = (Get-Item $apkPath).Length
        $apkSizeMB = [math]::Round($apkSize / 1MB, 2)
        Write-Success "APK location: $apkPath"
        Write-Host "File size: $apkSizeMB MB"
    }
    else {
        Write-Error "APK not found at expected location: $apkPath"
    }

    # Step 7: Optional Firebase App Distribution
    Write-Host ""
    Write-Info "Step 7: Firebase App Distribution (Optional)..."
    
    $firebaseAppId = $env:FIREBASE_APP_ID
    $firebaseServiceAccount = $env:FIREBASE_SERVICE_ACCOUNT_KEY
    
    if (-not $firebaseAppId -or -not $firebaseServiceAccount) {
        Write-Warning "Firebase App Distribution secrets not configured."
        Write-Host "To enable automatic distribution, set:"
        Write-Host "  `$env:FIREBASE_APP_ID='your_app_id'"
        Write-Host "  `$env:FIREBASE_SERVICE_ACCOUNT_KEY='your_service_account_json'"
        Write-Host ""
        Write-Host "Manual upload: https://console.firebase.google.com/project/fedha-tracker/appdistribution"
    }
    else {
        Write-Info "Firebase App Distribution configured."
        Write-Host "Use Firebase Console or CLI to distribute: $apkPath"
    }

    Write-Host ""
    Write-Host "=============================================="
    Write-Success "🎉 Manual deployment completed successfully!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Test the APK: $apkPath"
    Write-Host "  2. Upload to Firebase App Distribution (if not automated)"
    Write-Host "  3. Monitor Firebase Console for Firestore rules deployment"
    Write-Host "  4. Test authentication flow in the app"
    Write-Host ""
    
    # Open APK location in Explorer
    if (Test-Path $apkPath) {
        Write-Info "Opening APK location in Explorer..."
        Start-Process explorer.exe -ArgumentList "/select,`"$(Resolve-Path $apkPath)`""
    }
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Info "Troubleshooting tips:"
    Write-Host "  1. Ensure Flutter is installed and in PATH"
    Write-Host "  2. Check internet connection"
    Write-Host "  3. Verify Firebase project permissions"
    Write-Host "  4. Check pubspec.yaml dependencies"
    exit 1
}
