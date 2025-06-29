# Firebase APK Building Setup Guide

This guide explains how to build and distribute your Fedha Android APK using Firebase App Distribution.

## Prerequisites

1. **Firebase Project Setup**
2. **Firebase App Distribution enabled**
3. **GitHub repository with Actions enabled**
4. **Service Account with proper permissions**

## Step 1: Enable Firebase App Distribution

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Fedha project
3. Navigate to **App Distribution** in the left sidebar
4. If not enabled, click **Get Started**

## Step 2: Get Firebase App ID

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click on your Android app
3. Copy the **App ID** (format: `1:123456789:android:abcdef123456`)
4. Save this for GitHub Secrets

## Step 3: Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to **IAM & Admin** > **Service Accounts**
4. Click **Create Service Account**
5. Name: `firebase-app-distribution`
6. Grant these roles:
   - **Firebase App Distribution Admin**
   - **Firebase Quality Admin**
7. Click **Create Key** > **JSON**
8. Download the JSON file (save for GitHub Secrets)

## Step 4: Setup GitHub Secrets

In your GitHub repository:

1. Go to **Settings** > **Secrets and variables** > **Actions**
2. Add these repository secrets:

### Required Secrets:

```
FIREBASE_APP_ID
Value: Your Firebase App ID (from Step 2)

FIREBASE_SERVICE_ACCOUNT
Value: Complete contents of the JSON file (from Step 3)
```

### Example Service Account JSON:
```json
{
  "type": "service_account",
  "project_id": "fedha-app-12345",
  "private_key_id": "abcd1234...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-app-distribution@fedha-app-12345.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs"
}
```

## Step 5: Configure Tester Groups (Optional)

1. In Firebase Console > **App Distribution**
2. Go to **Testers & Groups** tab
3. Create groups:
   - **internal** (for development team)
   - **testers** (for beta testers)
   - **external** (for external stakeholders)

## Step 6: Trigger Build

### Automatic Triggers:
- Push to `main` branch → Release build
- Push to `develop` branch → Debug build
- Pull Request → Test build

### Manual Trigger:
1. Go to **Actions** tab in GitHub
2. Select **Build and Distribute APK via Firebase**
3. Click **Run workflow**
4. Choose branch and click **Run workflow**

## Step 7: Monitor Build

1. **GitHub Actions**: Monitor build progress
2. **Firebase Console**: Check distribution status
3. **Email Notifications**: Testers receive download links

## Build Artifacts

The workflow creates:
- **Debug APK**: For development testing
- **Release APK**: For production distribution
- **Build logs**: For troubleshooting

## Distribution Flow

```mermaid
graph LR
    A[Code Push] --> B[GitHub Actions]
    B --> C[Flutter Build]
    C --> D[Firebase Distribution]
    D --> E[Testers Notified]
    E --> F[APK Download]
```

## Troubleshooting

### Common Issues:

1. **Build Fails**
   - Check Flutter version compatibility
   - Verify dependencies in pubspec.yaml
   - Review build logs in Actions tab

2. **Firebase Upload Fails**
   - Verify FIREBASE_APP_ID is correct
   - Check service account permissions
   - Ensure App Distribution is enabled

3. **Testers Not Notified**
   - Verify tester group names match workflow
   - Check tester email addresses
   - Review Firebase App Distribution logs

### Debug Commands:

```bash
# Test local build
cd app
flutter clean
flutter pub get
flutter build apk --debug

# Validate Firebase setup
firebase projects:list
firebase apps:list
```

## Security Notes

- **Never commit** service account JSON to repository
- **Use GitHub Secrets** for all sensitive data
- **Rotate service accounts** periodically
- **Limit tester groups** to necessary personnel

## Alternative: Manual Firebase CLI Build

If you prefer manual builds:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Build and upload
cd app
flutter build apk --release
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:123456789:android:abcdef123456 \
  --groups "testers,internal" \
  --release-notes "Manual build $(date)"
```

This setup provides automated APK building and distribution through Firebase whenever you push code changes!
