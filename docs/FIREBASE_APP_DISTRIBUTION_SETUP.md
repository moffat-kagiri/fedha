# Firebase App Distribution Setup Guide

## Overview
This guide will help you set up Firebase App Distribution to automatically build and distribute your Fedha app APKs.

## Prerequisites
1. Firebase project with App Distribution enabled
2. Android app registered in Firebase Console
3. GitHub repository with Actions enabled

## Setup Steps

### 1. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Fedha project
3. Navigate to **App Distribution** in the left sidebar
4. If not enabled, click "Get started"

### 2. Get Firebase App ID
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to "Your apps" section
3. Find your Android app
4. Copy the **App ID** (format: `1:123456789:android:abcdef...`)

### 3. Create Service Account
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to **IAM & Admin > Service Accounts**
4. Click **"Create Service Account"**
5. Name: `fedha-app-distribution`
6. Grant roles:
   - Firebase App Distribution Admin
   - Firebase Authentication Admin
7. Create and download the JSON key file

### 4. Setup GitHub Secrets
In your GitHub repository, go to **Settings > Secrets and variables > Actions**

Add these secrets:
- `FIREBASE_APP_ID`: Your Android app ID from step 2
- `FIREBASE_SERVICE_ACCOUNT_KEY`: Copy the entire content of the JSON file from step 3

### 5. Add Testers
1. In Firebase Console > App Distribution
2. Click **"Testers & Groups"**
3. Create a group called "testers"
4. Add email addresses of people who should receive test builds

## Manual Build Commands

### Build and Upload Manually
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Build APK
cd app
flutter build apk --release

# Upload to App Distribution
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups "testers" \
  --release-notes "Manual test build"
```

### PowerShell Script (Windows)
```powershell
# File: build-and-distribute.ps1
cd app
flutter clean
flutter pub get
flutter build apk --release

firebase appdistribution:distribute `
  build/app/outputs/flutter-apk/app-release.apk `
  --app "1:123456789:android:abcdef..." `
  --groups "testers" `
  --release-notes "Test build from PowerShell"
```

## Automatic Triggers

The GitHub Action will automatically build and distribute when:
- Code is pushed to `main` or `develop` branches
- Pull requests are created to `main`
- Manually triggered from GitHub Actions tab

## Testing the Setup

1. Make a small change to your Flutter app
2. Commit and push to `main` branch
3. Check **GitHub Actions** tab to see build progress
4. Testers should receive email notification with download link

## Troubleshooting

### Common Issues:
1. **Build fails**: Check Flutter dependencies and Android setup
2. **Upload fails**: Verify service account permissions
3. **Testers don't receive emails**: Check tester group configuration

### Debug Commands:
```bash
# Test Firebase CLI login
firebase projects:list

# Test App Distribution access
firebase appdistribution:apps:list

# Validate service account
firebase auth:list
```

## Next Steps

Once working, you can:
1. Add iOS builds to the workflow
2. Set up different distribution groups (internal, beta, production)
3. Add automated testing before distribution
4. Configure release notes from commit messages

## Firebase CLI Alternative

If you prefer Firebase CLI over GitHub Actions:

```bash
# Install and setup
npm install -g firebase-tools
firebase login
firebase use --add  # Select your project

# Create firebase.json (if not exists)
firebase init hosting

# Add to firebase.json:
{
  "appDistribution": {
    "app": "your-app-id",
    "groups": ["testers"],
    "releaseNotesFile": "release-notes.txt"
  }
}
```
