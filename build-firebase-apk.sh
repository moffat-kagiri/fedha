#!/bin/bash

# Firebase APK Build and Distribution Script for Fedha
# Usage: ./build-firebase-apk.sh [debug|release]

set -e

# Configuration
FIREBASE_APP_ID="1:862134647621:android:e13263930355dde2cb1c2c"
PROJECT_DIR="$(dirname "$0")/app"
BUILD_TYPE="${1:-release}"
TESTER_GROUPS="testers,internal"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Fedha Firebase APK Build Script${NC}"
echo -e "${BLUE}=====================================${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Install with: npm install -g firebase-tools${NC}"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter SDK${NC}"
    exit 1
fi

# Check if logged into Firebase
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}🔐 Please login to Firebase...${NC}"
    firebase login
fi

echo -e "${GREEN}✅ Prerequisites checked${NC}"

# Navigate to app directory
cd "$PROJECT_DIR"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean

# Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Run code analysis
echo -e "${YELLOW}🔍 Running code analysis...${NC}"
flutter analyze --no-pub

# Build APK
echo -e "${YELLOW}🔨 Building $BUILD_TYPE APK...${NC}"
case $BUILD_TYPE in
    "debug")
        flutter build apk --debug --build-name=1.0.$(date +%Y%m%d%H%M) --build-number=$(date +%Y%m%d%H%M)
        APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
        ;;
    "release")
        flutter build apk --release --build-name=1.0.$(date +%Y%m%d%H%M) --build-number=$(date +%Y%m%d%H%M)
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        ;;
    *)
        echo -e "${RED}❌ Invalid build type. Use 'debug' or 'release'${NC}"
        exit 1
        ;;
esac

# Check if APK was built successfully
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ APK build failed. File not found: $APK_PATH${NC}"
    exit 1
fi

# Get APK info
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "${GREEN}✅ APK built successfully!${NC}"
echo -e "${BLUE}📱 APK Size: $APK_SIZE${NC}"
echo -e "${BLUE}📍 Location: $APK_PATH${NC}"

# Generate release notes
RELEASE_NOTES="🚀 Fedha APK Build - $BUILD_TYPE

📅 Build Date: $(date)
🏗️  Build Type: $BUILD_TYPE
📱 APK Size: $APK_SIZE
🔧 Flutter Version: $(flutter --version | head -1)

Recent Changes:
$(git log --oneline -5 2>/dev/null || echo "No git history available")

Built from branch: $(git branch --show-current 2>/dev/null || echo "unknown")
Commit: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"

# Distribute via Firebase
echo -e "${YELLOW}🚀 Distributing APK via Firebase App Distribution...${NC}"

firebase appdistribution:distribute "$APK_PATH" \
    --app "$FIREBASE_APP_ID" \
    --groups "$TESTER_GROUPS" \
    --release-notes "$RELEASE_NOTES" || {
    echo -e "${RED}❌ Firebase distribution failed${NC}"
    echo -e "${YELLOW}💡 You can still use the APK locally: $APK_PATH${NC}"
    exit 1
}

echo -e "${GREEN}🎉 APK successfully distributed via Firebase!${NC}"
echo -e "${BLUE}📧 Testers in groups '$TESTER_GROUPS' will receive notification emails${NC}"
echo -e "${BLUE}🌐 Check Firebase Console for distribution details${NC}"

# Optional: Open Firebase Console
read -p "Open Firebase Console? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v xdg-open &> /dev/null; then
        xdg-open "https://console.firebase.google.com/project/fedha-tracker/appdistribution"
    elif command -v open &> /dev/null; then
        open "https://console.firebase.google.com/project/fedha-tracker/appdistribution"
    else
        echo -e "${BLUE}🌐 Open: https://console.firebase.google.com/project/fedha-tracker/appdistribution${NC}"
    fi
fi

echo -e "${GREEN}✨ Build and distribution complete!${NC}"
