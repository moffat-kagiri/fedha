# 🚀 Manual Firebase Deployment Guide

This directory contains scripts to manually run the same steps as the GitHub Actions workflow, useful for local testing and debugging.

## 📋 Available Scripts

### 1. **PowerShell Script (Recommended for Windows)**
```powershell
# Basic deployment
.\manual_deploy.ps1

# Skip tests for faster deployment
.\manual_deploy.ps1 -SkipTests

# Build debug APK instead of release
.\manual_deploy.ps1 -DebugBuild

# Combine options
.\manual_deploy.ps1 -SkipTests -DebugBuild
```

### 2. **Bash Script (Linux/macOS/WSL)**
```bash
# Make executable
chmod +x manual_deploy.sh

# Run deployment
./manual_deploy.sh
```

### 3. **Quick Batch Script (Windows - Simple)**
```batch
# Double-click or run from command prompt
quick_deploy.bat
```

### 4. **Deployment Status Check**
```powershell
# Check current Firebase deployment status
.\check_deployment_status.ps1   # Windows
./check_deployment_status.sh    # Linux/macOS
```

## 🔧 Prerequisites

### Required Tools
- **Flutter SDK**: Latest stable version
- **Dart SDK**: 3.7.0+ (comes with Flutter)
- **Firebase CLI**: `npm install -g firebase-tools`
- **Node.js**: For Firebase CLI
- **Git**: For version control

### Environment Variables (Optional)
Set these for automated Firebase App Distribution:

```powershell
# PowerShell
$env:FIREBASE_TOKEN="your_firebase_token"
$env:FIREBASE_APP_ID="your_app_id"
$env:FIREBASE_SERVICE_ACCOUNT_KEY="your_service_account_json"
```

```bash
# Bash
export FIREBASE_TOKEN="your_firebase_token"
export FIREBASE_APP_ID="your_app_id"
export FIREBASE_SERVICE_ACCOUNT_KEY="your_service_account_json"
```

## 🔑 Firebase Authentication Setup

### Get Firebase Token
```bash
# Login to Firebase
firebase login:ci

# Copy the token and set environment variable
```

### Firebase Project Configuration
- **Project ID**: `fedha-tracker`
- **Region**: `africa-south1`
- **Console**: https://console.firebase.google.com/project/fedha-tracker

## 📱 Deployment Steps

Each script performs these steps in order:

1. **Version Check**: Verify Flutter/Dart versions
2. **Clean Build**: Remove previous build artifacts
3. **Dependencies**: Install/update Flutter packages
4. **Firestore Rules**: Deploy security rules to Firebase
5. **Testing**: Run Flutter test suite
6. **Build APK**: Create release APK
7. **Optional**: Upload to Firebase App Distribution

## 🎯 Script Features

### PowerShell Script (`manual_deploy.ps1`)
- ✅ Colored output for easy reading
- ✅ Error handling and troubleshooting tips
- ✅ Optional flags (skip tests, debug build)
- ✅ Automatic Explorer opening to APK location
- ✅ Environment variable checking

### Bash Script (`manual_deploy.sh`)
- ✅ Cross-platform compatibility
- ✅ Colored terminal output
- ✅ Comprehensive error checking
- ✅ Dependency verification

### Batch Script (`quick_deploy.bat`)
- ✅ Simple one-click deployment
- ✅ No parameters needed
- ✅ Automatic APK location opening

## 🔍 Troubleshooting

### Common Issues

**1. "Flutter command not found"**
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

**2. "Firebase command not found"**
```bash
# Install Firebase CLI
npm install -g firebase-tools
```

**3. "Permission denied" (Linux/macOS)**
```bash
# Make script executable
chmod +x manual_deploy.sh
```

**4. "PowerShell execution policy" (Windows)**
```powershell
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**5. "Firebase authentication failed"**
```bash
# Re-authenticate
firebase logout
firebase login
firebase login:ci  # For token
```

### Debug Output

All scripts provide verbose output showing:
- Flutter and Dart versions
- Dependency resolution
- Test results
- Build progress
- APK location and size

## 🚀 Quick Start

1. **Navigate to app directory**:
   ```bash
   cd c:\GitHub\fedha\app
   ```

2. **Run deployment script**:
   ```powershell
   # Windows PowerShell (recommended)
   .\manual_deploy.ps1
   
   # Windows Batch (simple)
   quick_deploy.bat
   
   # Linux/macOS/WSL
   ./manual_deploy.sh
   ```

3. **Test the generated APK**:
   - Location: `build/app/outputs/flutter-apk/app-release.apk`
   - Install on Android device or emulator
   - Test Firebase authentication flow

## 📊 Expected Output

Successful deployment will show:
```
✅ Dependencies resolved successfully!
✅ Firestore rules deployed
✅ All tests passed!
✅ APK built successfully!
🎉 Manual deployment completed successfully!
```

## ✅ Deployment Verification

After running any deployment script, verify your setup using:

📖 **[Firebase Deployment Verification Guide](FIREBASE_DEPLOYMENT_VERIFICATION.md)**

This comprehensive guide shows you how to:
- ✅ Verify GitHub Actions deployment status
- 🔥 Check Firebase Console for correct configuration
- 🧪 Test authentication and Firestore integration
- 🚨 Troubleshoot common deployment issues

## 🔗 Related Files

- **GitHub Actions**: `.github/workflows/firebase-deploy.yml`
- **Firebase Config**: `firebase.json`, `.firebaserc`
- **App Config**: `pubspec.yaml`
- **Security Rules**: `firestore.rules`

---

💡 **Tip**: Use the manual scripts to test deployments locally before pushing to GitHub Actions!
