# Firebase South Africa Deployment and Testing

## 1. Deploy Functions to South Africa Region

```bash
# Navigate to the app directory
cd c:\GitHub\fedha\app

# Build the functions
cd functions
npm install
npm run build

# Deploy functions to the new region
cd ..
npx firebase deploy --only functions

# You should see output indicating deployment to africa-south1
```

## 2. Test the Authentication Flow

### Test Registration
```bash
# You can test using curl or the app itself
curl -X POST https://africa-south1-fedha-tracker.cloudfunctions.net/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","profileType":"personal","pin":"password123","email":"test@example.com"}'
```

### Test Login  
```bash
curl -X POST https://africa-south1-fedha-tracker.cloudfunctions.net/login \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test@example.com","pin":"password123"}'
```

### Test Health Check
```bash
curl https://africa-south1-fedha-tracker.cloudfunctions.net/health
```

## 3. App Testing Checklist

- [ ] Account creation with email/password
- [ ] Login with email/password  
- [ ] Password reset functionality
- [ ] Profile data synchronization
- [ ] Firebase Auth fallback (if Functions are down)

## 4. Performance Verification

Before migration (US Central):
- Test response times from South Africa
- Note latency measurements

After migration (Africa South):
- Test response times again
- Compare improvements

## 5. Firestore Database Setup

If you need a new Firestore database in Africa South:

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Create Database
4. Choose "Start in production mode" 
5. Select "africa-south1" region
6. Update security rules if needed

## Troubleshooting

### Functions not deploying to correct region
- Check `functions/src/index.ts` has correct region setting
- Verify `.firebaserc` has correct project ID
- Try `npx firebase functions:config:get` to check config

### URLs not working
- Ensure AuthApiClient uses `africa-south1` base URL
- Check CORS headers in functions
- Verify Firebase project settings

### Authentication errors
- Test Firebase Auth directly (should work globally)
- Check Firebase Functions logs in console
- Verify API client fallback to Firebase Auth

## Expected Improvements

For South African users:
- **Functions**: 200-500ms faster response times
- **Firestore**: 300-800ms faster database operations  
- **Storage**: 200-400ms faster file uploads/downloads
- **Overall UX**: Noticeably snappier app performance
