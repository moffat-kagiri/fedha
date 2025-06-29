# Firebase APK Build and Distribution Script for Fedha (PowerShell)
# Usage: .\build-firebase-apk.ps1 [-BuildType debug|release]

param(
    [string]$BuildType = "release"
)

# Configuration
$FIREBASE_APP_ID = "1:862134647621:android:e13263930355dde2cb1c2c"
$PROJECT_DIR = Join-Path $PSScriptRoot "app"
$TESTER_GROUPS = "testers,internal"

# Colors for output
$colors = @{
    Red = 'Red'
    Green = 'Green'
    Yellow = 'Yellow'
    Blue = 'Blue'
    Cyan = 'Cyan'
}

Write-Host "🚀 Fedha Firebase APK Build Script" -ForegroundColor $colors.Blue
Write-Host "=====================================" -ForegroundColor $colors.Blue

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor $colors.Yellow

# Check if Firebase CLI is installed
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Firebase CLI not found. Install with: npm install -g firebase-tools" -ForegroundColor $colors.Red
    exit 1
}

# Check if Flutter is installed
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter not found. Please install Flutter SDK" -ForegroundColor $colors.Red
    exit 1
}

# Check if logged into Firebase
try {
    firebase projects:list | Out-Null
}
catch {
    Write-Host "🔐 Please login to Firebase..." -ForegroundColor $colors.Yellow
    firebase login
}

Write-Host "✅ Prerequisites checked" -ForegroundColor $colors.Green

# Navigate to app directory
Set-Location $PROJECT_DIR

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor $colors.Yellow
flutter clean

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor $colors.Yellow
flutter pub get

# Run code analysis
Write-Host "🔍 Running code analysis..." -ForegroundColor $colors.Yellow
flutter analyze --no-pub

# Build APK
Write-Host "🔨 Building $BuildType APK..." -ForegroundColor $colors.Yellow

$timestamp = Get-Date -Format "yyyyMMddHHmm"
$buildName = "1.0.$timestamp"
$buildNumber = $timestamp

switch ($BuildType.ToLower()) {
    "debug" {
        flutter build apk --debug --build-name=$buildName --build-number=$buildNumber
        $APK_PATH = "build\app\outputs\flutter-apk\app-debug.apk"
    }
    "release" {
        flutter build apk --release --build-name=$buildName --build-number=$buildNumber
        $APK_PATH = "build\app\outputs\flutter-apk\app-release.apk"
    }
    default {
        Write-Host "❌ Invalid build type. Use 'debug' or 'release'" -ForegroundColor $colors.Red
        exit 1
    }
}

# Check if APK was built successfully
if (-not (Test-Path $APK_PATH)) {
    Write-Host "❌ APK build failed. File not found: $APK_PATH" -ForegroundColor $colors.Red
    exit 1
}

# Get APK info
$APK_SIZE = [math]::Round((Get-Item $APK_PATH).Length / 1MB, 2)
Write-Host "✅ APK built successfully!" -ForegroundColor $colors.Green
Write-Host "📱 APK Size: $APK_SIZE MB" -ForegroundColor $colors.Blue
Write-Host "📍 Location: $APK_PATH" -ForegroundColor $colors.Blue

# Generate release notes
$flutterVersion = (flutter --version | Select-Object -First 1)
$currentBranch = try { git branch --show-current 2>$null } catch { "unknown" }
$currentCommit = try { git rev-parse --short HEAD 2>$null } catch { "unknown" }
$recentCommits = try { git log --oneline -5 2>$null } catch { "No git history available" }

$releaseNotes = @"
🚀 Fedha APK Build - $BuildType

📅 Build Date: $(Get-Date)
🏗️  Build Type: $BuildType
📱 APK Size: $APK_SIZE MB
🔧 Flutter Version: $flutterVersion

Recent Changes:
$recentCommits

Built from branch: $currentBranch
Commit: $currentCommit
"@

# Distribute via Firebase
Write-Host "🚀 Distributing APK via Firebase App Distribution..." -ForegroundColor $colors.Yellow

try {
    firebase appdistribution:distribute $APK_PATH --app $FIREBASE_APP_ID --groups $TESTER_GROUPS --release-notes $releaseNotes
    
    Write-Host "🎉 APK successfully distributed via Firebase!" -ForegroundColor $colors.Green
    Write-Host "📧 Testers in groups '$TESTER_GROUPS' will receive notification emails" -ForegroundColor $colors.Blue
    Write-Host "🌐 Check Firebase Console for distribution details" -ForegroundColor $colors.Blue
}
catch {
    Write-Host "❌ Firebase distribution failed" -ForegroundColor $colors.Red
    Write-Host "💡 You can still use the APK locally: $APK_PATH" -ForegroundColor $colors.Yellow
    exit 1
}

# Optional: Open Firebase Console
$openConsole = Read-Host "Open Firebase Console? (y/n)"
if ($openConsole -match "^[Yy]") {
    Start-Process "https://console.firebase.google.com/project/fedha-tracker/appdistribution"
}

Write-Host "✨ Build and distribution complete!" -ForegroundColor $colors.Green
