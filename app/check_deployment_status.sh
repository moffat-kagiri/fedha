#!/bin/bash
# Deployment Status Check Script for Fedha
# Checks Firebase project status, rules deployment, and app configuration

echo -e "\033[1;36m🔍 Fedha Firebase Deployment Status Check\033[0m"
echo -e "\033[1;36m=============================================\033[0m"

# Check if Firebase CLI is installed
echo -e "\n\033[1;33m📋 Checking Firebase CLI...\033[0m"
if command -v firebase &> /dev/null; then
    firebase_version=$(firebase --version)
    echo -e "\033[1;32m✅ Firebase CLI installed: $firebase_version\033[0m"
else
    echo -e "\033[1;31m❌ Firebase CLI not found. Please install: npm install -g firebase-tools\033[0m"
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "firebase.json" ]; then
    echo -e "\033[1;31m❌ firebase.json not found. Please run this script from the app/ directory.\033[0m"
    exit 1
fi

echo -e "\n\033[1;33m🎯 Project Configuration:\033[0m"
echo "  Project ID: fedha-tracker"
echo "  Region: southafrica-west1"

# Check Firebase project status
echo -e "\n\033[1;33m🔥 Firebase Project Status:\033[0m"
echo -e "\033[1;36m📋 Available projects:\033[0m"
firebase projects:list 2>&1

echo -e "\n\033[1;36m🎯 Current project status:\033[0m"
firebase use --project fedha-tracker 2>&1

# Check Firestore rules
echo -e "\n\033[1;33m🔐 Firestore Rules Status:\033[0m"
if [ -f "firestore.rules" ]; then
    rules_size=$(wc -c < firestore.rules)
    echo -e "\033[1;32m✅ Local rules file found (Size: $rules_size bytes)\033[0m"
    
    echo -e "\n\033[1;36m📄 Rules file preview:\033[0m"
    head -n 5 firestore.rules
    echo -e "\033[1;37m...\033[0m"
    
    echo -e "\n\033[1;36m🌐 Deployed rules:\033[0m"
    firebase firestore:rules get --project fedha-tracker 2>&1 || echo -e "\033[1;33m⚠️  Could not fetch deployed rules. May need authentication.\033[0m"
else
    echo -e "\033[1;31m❌ firestore.rules file not found!\033[0m"
fi

# Check Firebase configuration files
echo -e "\n\033[1;33m📱 App Configuration:\033[0m"

config_files=(
    "firebase.json"
    ".firebaserc"
    "android/app/google-services.json"
    "lib/firebase_options.dart"
)

for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "\033[1;32m✅ $file\033[0m"
    else
        echo -e "\033[1;31m❌ $file missing\033[0m"
    fi
done

# Check pubspec.yaml for Firebase dependencies
echo -e "\n\033[1;33m📦 Firebase Dependencies:\033[0m"
if [ -f "pubspec.yaml" ]; then
    firebase_deps=$(grep -i firebase pubspec.yaml)
    if [ -n "$firebase_deps" ]; then
        echo -e "\033[1;32m✅ Firebase dependencies found:\033[0m"
        echo "$firebase_deps" | while read line; do
            echo -e "\033[1;36m  $line\033[0m"
        done
    else
        echo -e "\033[1;33m⚠️  No Firebase dependencies found in pubspec.yaml\033[0m"
    fi
else
    echo -e "\033[1;31m❌ pubspec.yaml not found!\033[0m"
fi

echo -e "\n\033[1;33m🔗 Useful Links:\033[0m"
echo -e "\033[1;36m  Firebase Console: https://console.firebase.google.com/project/fedha-tracker\033[0m"
echo -e "\033[1;36m  Auth Users: https://console.firebase.google.com/project/fedha-tracker/authentication/users\033[0m"
echo -e "\033[1;36m  Firestore Database: https://console.firebase.google.com/project/fedha-tracker/firestore/data\033[0m"
echo -e "\033[1;36m  Security Rules: https://console.firebase.google.com/project/fedha-tracker/firestore/rules\033[0m"

echo -e "\n\033[1;32m✅ Status check completed!\033[0m"
echo -e "\033[1;34m💡 Tip: Run 'flutter test test/firebase_setup_test.dart' to test Firebase integration\033[0m"
