#!/usr/bin/env pwsh
# Deployment Status Check Script for Fedha
# Checks Firebase project status, rules deployment, and app configuration

Write-Host "🔍 Fedha Firebase Deployment Status Check" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Check if Firebase CLI is installed
Write-Host "`n📋 Checking Firebase CLI..." -ForegroundColor Yellow
if (Get-Command firebase -ErrorAction SilentlyContinue) {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI installed: $firebaseVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Firebase CLI not found. Please install: npm install -g firebase-tools" -ForegroundColor Red
    exit 1
}

# Check if we're in the correct directory
if (-Not (Test-Path "firebase.json")) {
    Write-Host "❌ firebase.json not found. Please run this script from the app/ directory." -ForegroundColor Red
    exit 1
}

Write-Host "`n🎯 Project Configuration:" -ForegroundColor Yellow
Write-Host "  Project ID: fedha-tracker"
Write-Host "  Region: southafrica-west1"

# Check Firebase project status
Write-Host "`n🔥 Firebase Project Status:" -ForegroundColor Yellow
Write-Host "📋 Available projects:" -ForegroundColor Cyan
firebase projects:list 2>&1

Write-Host "`n🎯 Current project status:" -ForegroundColor Cyan
firebase use --project fedha-tracker 2>&1

# Check Firestore rules
Write-Host "`n🔐 Firestore Rules Status:" -ForegroundColor Yellow
if (Test-Path "firestore.rules") {
    $rulesSize = (Get-Item "firestore.rules").Length
    Write-Host "✅ Local rules file found (Size: $rulesSize bytes)" -ForegroundColor Green
    
    Write-Host "`n📄 Rules file preview:" -ForegroundColor Cyan
    Get-Content "firestore.rules" | Select-Object -First 5
    Write-Host "..." -ForegroundColor Gray
    
    Write-Host "`n🌐 Deployed rules:" -ForegroundColor Cyan
    firebase firestore:rules get --project fedha-tracker 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Could not fetch deployed rules. May need authentication." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ firestore.rules file not found!" -ForegroundColor Red
}

# Check Firebase configuration files
Write-Host "`n📱 App Configuration:" -ForegroundColor Yellow

$configFiles = @(
    "firebase.json",
    ".firebaserc", 
    "android/app/google-services.json",
    "lib/firebase_options.dart"
)

foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file missing" -ForegroundColor Red
    }
}

# Check pubspec.yaml for Firebase dependencies
Write-Host "`n📦 Firebase Dependencies:" -ForegroundColor Yellow
if (Test-Path "pubspec.yaml") {
    $firebaseDeps = Get-Content "pubspec.yaml" | Select-String "firebase"
    if ($firebaseDeps) {
        Write-Host "✅ Firebase dependencies found:" -ForegroundColor Green
        $firebaseDeps | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
    } else {
        Write-Host "⚠️  No Firebase dependencies found in pubspec.yaml" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ pubspec.yaml not found!" -ForegroundColor Red
}

Write-Host "`n🔗 Useful Links:" -ForegroundColor Yellow
Write-Host "  Firebase Console: https://console.firebase.google.com/project/fedha-tracker" -ForegroundColor Cyan
Write-Host "  Auth Users: https://console.firebase.google.com/project/fedha-tracker/authentication/users" -ForegroundColor Cyan
Write-Host "  Firestore Database: https://console.firebase.google.com/project/fedha-tracker/firestore/data" -ForegroundColor Cyan
Write-Host "  Security Rules: https://console.firebase.google.com/project/fedha-tracker/firestore/rules" -ForegroundColor Cyan

Write-Host "`n✅ Status check completed!" -ForegroundColor Green
Write-Host "💡 Tip: Run 'flutter test test/firebase_setup_test.dart' to test Firebase integration" -ForegroundColor Blue
