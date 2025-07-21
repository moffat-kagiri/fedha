# Fedha App Features Guide

This document provides implementation details and guidance for key features in the Fedha app.

## Table of Contents

1. [First Login Prompts](#first-login-prompts)
   - [Overview](#overview)
   - [Implementation](#implementation)
   - [Important Methods](#important-methods)
   - [Best Practices](#best-practices)

2. [Offline-First Authentication](#offline-first-authentication)
   - [Overview](#offline-first-overview)
   - [Implementation](#offline-first-implementation)
   - [Synchronization](#synchronization)

3. [Biometric Authentication](#biometric-authentication)
   - [Overview](#biometric-overview)
   - [Implementation](#biometric-implementation)
   - [Security Considerations](#security-considerations)

---

## First Login Prompts

### Overview

When a user logs in for the first time or creates a new account, we show two important prompts:

1. **Biometric Authentication Setup** - Encourage users to enable fingerprint or face recognition for easy and secure login.
2. **App Permissions** - Request permissions for SMS (to track financial transactions), phone calls (for support features), and notifications.

### Implementation

#### 1. Check Login Result

After a successful login, check if it's the user's first login:

```dart
final result = await authService.enhancedLogin(email, pin);

if (result.success) {
  // Navigate to home screen
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const HomeScreen()),
  );
  
  // Show first login prompts if needed
  if (result.isFirstLogin) {
    final firstLoginHandler = FirstLoginHandler(context, authService);
    await firstLoginHandler.handleFirstLogin();
  }
}
```

#### 2. Using FirstLoginHandler

The `FirstLoginHandler` class handles showing the prompts in sequence:

```dart
import 'package:fedha/utils/first_login_handler.dart';

// Create an instance with current context and auth service
final firstLoginHandler = FirstLoginHandler(context, authService);

// This will show all required prompts and mark them as shown
await firstLoginHandler.handleFirstLogin();
```

#### 3. Custom Prompt Handling

If you need more control over when and how prompts are shown:

```dart
// Check if prompts should be shown
if (await authService.shouldShowBiometricPrompt()) {
  // Show your custom biometric setup UI
  // ...
  
  // Mark as shown when done
  await authService.markBiometricPromptShown();
}

if (await authService.shouldShowPermissionsPrompt()) {
  // Show your custom permissions UI
  // ...
  
  // Mark as shown when done
  await authService.markPermissionsPromptShown();
}
```

### Important Methods

#### AuthService

- `isFirstLogin()` - Checks if this is the user's first login
- `markFirstLoginCompleted()` - Marks first login as completed
- `shouldShowBiometricPrompt()` - Checks if biometric prompt should be shown
- `markBiometricPromptShown()` - Marks biometric prompt as shown
- `shouldShowPermissionsPrompt()` - Checks if permissions prompt should be shown
- `markPermissionsPromptShown()` - Marks permissions prompt as shown
- `enableBiometricAuth()` - Sets up biometric authentication

#### FirstLoginHandler

- `handleFirstLogin()` - Shows all required prompts in sequence
- `_showBiometricSetupPrompt()` - Shows the biometric setup dialog
- `_showPermissionsPrompt()` - Shows the permissions request dialog
- `_requestAppPermissions()` - Requests SMS, phone, and notification permissions

### Best Practices

1. Show prompts after navigating to the home screen so users can see their dashboard first.
2. Always provide "Skip" or "Later" options for each prompt.
3. Explain the benefits of each permission to encourage opt-in.
4. Don't show all prompts at once - spread them out if possible.
5. Never block the app's functionality if users decline permissions.

---

## Offline-First Authentication
<a id="offline-first-overview"></a>

### Overview

Fedha uses an offline-first approach to authentication, allowing users to access their data even without an internet connection while still providing synchronization when online.

Key features:
- Persistent login across app sessions
- Secure local data storage
- Intelligent synchronization strategies
- Conflict resolution for data modified in multiple places

<a id="offline-first-implementation"></a>

### Implementation

#### 1. AuthSession Management

The `AuthSession` class manages persistent login sessions:

```dart
// Create and save auth session
final authSession = AuthSession(
  userId: profile.id,
  sessionToken: _createSessionToken(),
  deviceId: deviceId,
);

// Save session to storage
await settingsBox.put('auth_session', authSession.toJson());
```

#### 2. Automatic Login

The `tryAutoLogin` method attempts to restore a session:

```dart
Future<LoginResult> tryAutoLogin() async {
  // Check if persistent login is enabled
  if (!persistentLoginEnabled) {
    return LoginResult.error('Persistent login is disabled');
  }
  
  // Get and validate saved session
  final session = AuthSession.fromJson(Map<String, dynamic>.from(sessionJson));
  if (!session.isValid) {
    return LoginResult.error('Session expired');
  }
  
  // Get profile and restore session
  // ...
}
```

<a id="synchronization"></a>

### Synchronization

The `SyncManager` class handles data synchronization with configurable strategies:

```dart
// Create sync manager and perform sync based on settings
final syncManager = SyncManager(apiClient: _apiClient, profile: _currentProfile!);
await syncManager.syncEssentialData(); // Always sync essential data

// Conditional syncing based on user preferences
if (syncSettings.syncGoals) {
  syncManager.syncGoals();
}
```

Users can control what data gets synced with `SyncSettings`:

- Transactions (with privacy levels)
- Budgets
- Goals
- Profile data

---

## Biometric Authentication
<a id="biometric-overview"></a>

### Overview

Fedha supports fingerprint and face recognition authentication for quick and secure access to the app.

<a id="biometric-implementation"></a>

### Implementation

#### 1. Check Biometric Availability

```dart
final biometricService = BiometricAuthService.instance;
final isSupported = await biometricService.isDeviceSupported();
final isFingerprintAvailable = await biometricService.isFingerPrintAvailable();
```

#### 2. Authenticate with Biometrics

```dart
final authenticated = await biometricService.authenticateWithBiometric(
  'Please verify your identity to access your account'
);

if (authenticated) {
  // Proceed with automatic login
}
```

<a id="security-considerations"></a>

### Security Considerations

1. Biometric authentication is tied to individual profiles
2. User can enable/disable biometric login at any time
3. Biometric sessions expire after a configurable period
4. PIN/password remains as a fallback option
