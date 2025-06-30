# Firebase Manual Deployment Script
param([switch]$SkipTests, [switch]$DebugBuild)

Write-Host " Firebase Manual Deployment" -ForegroundColor Green

if (-not (Test-Path "pubspec.yaml")) {
    Write-Host " Run from app directory" -ForegroundColor Red
    exit 1
}

Write-Host "ℹ Verifying versions..." -ForegroundColor Cyan
flutter --version
dart --version

Write-Host "ℹ Getting dependencies..." -ForegroundColor Cyan  
flutter clean
flutter pub get

Write-Host "ℹ Deploying Firestore rules..." -ForegroundColor Cyan
npx firebase deploy --only firestore:rules --project fedha-tracker

if (-not $SkipTests) {
    Write-Host "ℹ Running tests..." -ForegroundColor Cyan
    flutter test
}

Write-Host "ℹ Building APK..." -ForegroundColor Cyan
if ($DebugBuild) {
    flutter build apk --debug
    $apk = "build\app\outputs\flutter-apk\app-debug.apk"
} else {
    flutter build apk --release
    $apk = "build\app\outputs\flutter-apk\app-release.apk"
}

Write-Host " Completed!" -ForegroundColor Green
Write-Host " APK: $apk" -ForegroundColor Yellow

if (Test-Path $apk) {
    Start-Process explorer.exe -ArgumentList "/select,$apk"
}
