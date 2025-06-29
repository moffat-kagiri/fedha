#!/bin/bash
# Firebase Manual Deployment Script
# This script replicates the GitHub Actions workflow for local testing

set -e  # Exit on any error

echo "🚀 Starting Firebase Manual Deployment..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function for colored output
log() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    error "Please run this script from the app directory (where pubspec.yaml is located)"
    exit 1
fi

# Step 1: Verify versions
echo ""
info "Step 1: Verifying Flutter and Dart versions..."
echo "Flutter version:"
flutter --version
echo ""
echo "Dart version:"
dart --version
echo ""

# Step 2: Clean and get dependencies
echo ""
info "Step 2: Resolving Flutter dependencies..."
echo "📦 Cleaning previous build..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get
log "Dependencies resolved successfully!"

echo "📋 Dependency tree:"
flutter pub deps --style=compact

# Step 3: Check for Firebase CLI
echo ""
info "Step 3: Checking Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    warn "Firebase CLI not found. Installing..."
    npm install -g firebase-tools
else
    log "Firebase CLI found: $(firebase --version)"
fi

# Step 4: Deploy Firestore Rules
echo ""
info "Step 4: Deploying Firestore security rules..."
if [ -z "$FIREBASE_TOKEN" ]; then
    warn "FIREBASE_TOKEN environment variable not set."
    echo "Please run: firebase login:ci"
    echo "Then set: export FIREBASE_TOKEN=your_token"
    echo ""
    echo "Attempting to deploy with login authentication..."
    firebase deploy --only firestore:rules --project fedha-tracker
else
    log "Using FIREBASE_TOKEN for authentication..."
    firebase deploy --only firestore:rules --project fedha-tracker --token $FIREBASE_TOKEN
fi

# Step 5: Run tests
echo ""
info "Step 5: Running Flutter tests..."
flutter test
log "All tests passed!"

# Step 6: Build APK
echo ""
info "Step 6: Building release APK..."
flutter build apk --release
log "APK built successfully!"

# Show APK location
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    log "APK location: $APK_PATH"
    echo "File size: $(ls -lh $APK_PATH | awk '{print $5}')"
else
    error "APK not found at expected location: $APK_PATH"
fi

# Step 7: Optional Firebase App Distribution
echo ""
info "Step 7: Firebase App Distribution (Optional)..."
if [ -z "$FIREBASE_APP_ID" ] || [ -z "$FIREBASE_SERVICE_ACCOUNT_KEY" ]; then
    warn "Firebase App Distribution secrets not configured."
    echo "To enable automatic distribution, set:"
    echo "  FIREBASE_APP_ID"
    echo "  FIREBASE_SERVICE_ACCOUNT_KEY"
    echo ""
    echo "Manual upload: https://console.firebase.google.com/project/fedha-tracker/appdistribution"
else
    info "Uploading to Firebase App Distribution..."
    # You can add firebase appdistribution:distribute command here
    echo "Use Firebase Console or CLI to distribute: $APK_PATH"
fi

echo ""
echo "=============================================="
log "🎉 Manual deployment completed successfully!"
echo ""
info "Next steps:"
echo "  1. Test the APK: $APK_PATH"
echo "  2. Upload to Firebase App Distribution (if not automated)"
echo "  3. Monitor Firebase Console for Firestore rules deployment"
echo "  4. Test authentication flow in the app"
echo ""
