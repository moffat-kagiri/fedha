# 🧪 Firebase Integration Testing Checklist

## Pre-Testing Setup
- [ ] Firestore database created in `africa-south1` region
- [ ] Firebase Auth enabled (Email/Password provider)
- [ ] Firestore security rules deployed
- [ ] App rebuilt with latest code

## Test Scenarios

### 1. Account Registration
- [ ] **Email Registration**: Register with valid email + password
- [ ] **Local Registration**: Register with name + PIN only
- [ ] **Profile Creation**: Verify profile appears in Firestore `/profiles` collection
- [ ] **Auth User**: Verify user appears in Firebase Auth console

### 2. Authentication
- [ ] **Email Login**: Login with email + password
- [ ] **Local Login**: Login with profile ID + PIN
- [ ] **Session Persistence**: App remembers login state
- [ ] **Logout**: Successfully logout and clear session

### 3. Password Reset
- [ ] **Reset Email**: Request password reset via email
- [ ] **Email Received**: Verify reset email arrives
- [ ] **Reset Complete**: Successfully reset password

### 4. Data Security
- [ ] **Profile Access**: User can only access their own profile
- [ ] **Transaction Access**: User can only see their transactions
- [ ] **Unauthorized Access**: Cannot access other users' data

### 5. Error Handling
- [ ] **Duplicate Email**: Proper error for existing email
- [ ] **Invalid Login**: Clear error for wrong credentials
- [ ] **Network Issues**: Graceful handling of connection errors
- [ ] **Validation Errors**: Clear messages for invalid input

## Testing Commands

### Build and Test
```bash
# Navigate to app directory
cd "c:\GitHub\fedha\app"

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug

# Run tests
flutter test

# Install and test on device
flutter install
```

### Check Firebase Rules Deployment
```bash
# Navigate to app directory
cd "c:\GitHub\fedha\app"

# Deploy rules manually (if needed)
npx firebase deploy --only firestore:rules --project fedha-tracker
```

### Monitor Firestore
1. Open Firebase Console
2. Go to Firestore Database
3. Monitor `/profiles` and `/transactions` collections
4. Verify data is being written correctly

## Expected Results

### Successful Registration
- New document in `/profiles/{userId}` with:
  ```json
  {
    "id": "generated-profile-id",
    "name": "User Name",
    "profileType": "PERS",
    "email": "user@example.com",
    "passwordHash": "hashed-value",
    "baseCurrency": "ZAR",
    "timezone": "GMT+2",
    "createdAt": "timestamp",
    "isActive": true,
    "firebaseUid": "firebase-user-id"
  }
  ```

### Successful Login
- User authenticated in Firebase Auth
- Access to profile data in Firestore
- Ability to create transactions, budgets, goals

## Troubleshooting

### Common Issues
1. **"Missing or insufficient permissions"**: Check Firestore rules deployment
2. **"User not found"**: Verify Firebase Auth configuration
3. **"Network error"**: Check internet connection and Firebase project status
4. **"Invalid project"**: Verify `.firebaserc` and `firebase.json` configuration

### Debug Steps
1. Check Firebase Console for error logs
2. Enable Flutter debug mode for detailed logs
3. Verify Firestore rules in Firebase Console
4. Test with Firebase Auth emulator locally

## Success Criteria
- ✅ Users can register with email or locally
- ✅ User profiles are stored in Firestore
- ✅ Authentication works for login/logout
- ✅ Password reset emails are sent
- ✅ Data access is properly restricted
- ✅ App is ready for deployment testing
