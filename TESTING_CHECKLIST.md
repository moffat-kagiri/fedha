# Fedha App Testing Checklist

## Backend Setup
- [ ] Django server starts without errors
- [ ] Health endpoint responds at `/api/health/`
- [ ] CORS is properly configured
- [ ] Database migrations are applied

## Flutter App Core Features
- [ ] App launches without errors
- [ ] Sign-in/sign-up flow works
- [ ] Dashboard loads with profile icon
- [ ] Navigation between screens works

## Profile Management
- [ ] Profile screen opens from dashboard icon
- [ ] Username/name can be edited and saved
- [ ] Password change works with alphanumeric validation
- [ ] Re-login prompt appears after password change
- [ ] Dark theme toggle works and persists
- [ ] Profile picture edit dialog appears (UI only)

## Transaction Features
- [ ] Manual SMS input works (iOS fallback)
- [ ] Transaction candidates are extracted correctly
- [ ] Transaction editing popup shows "edit" button
- [ ] Transaction editing form works properly
- [ ] Amounts display in "Ksh" format
- [ ] Transactions save to local storage

## SMS Integration (Android)
- [ ] SMS permissions are requested
- [ ] Background SMS listener is active
- [ ] Transaction notifications appear
- [ ] SMS content becomes transaction description
- [ ] Category defaults to "Other" and is editable

## Server Connectivity
- [ ] In-app connection test works
- [ ] API calls succeed (sync, transactions, etc.)
- [ ] Network errors are handled gracefully
- [ ] Offline mode works when server unavailable

## Theme & UI
- [ ] Light theme displays correctly
- [ ] Dark theme displays correctly
- [ ] Theme persists across app restarts
- [ ] UI is responsive on different screen sizes
- [ ] Kenyan Shilling (Ksh) used throughout

## Error Handling
- [ ] Network errors show user-friendly messages
- [ ] Form validation works properly
- [ ] App doesn't crash on errors
- [ ] Loading states are shown appropriately

## Commands to Test

### Start Backend Server:
```bash
# For emulator testing
cd c:\GitHub\fedha\backend
python start_server.py

# For real device testing  
python start_server_network.py
```

### Test Flutter App:
```bash
cd c:\GitHub\fedha\app
flutter clean
flutter pub get
flutter run
```

### Run Connection Test (In-App):
- Open Tools screen
- Tap "Test Server Connection" 
- Review connectivity results

## Notes:
- Test on both Android emulator and real device if possible
- Check console logs for any errors or warnings
- Verify all user-facing text uses "Ksh" instead of "$"
- Ensure theme changes take effect immediately
