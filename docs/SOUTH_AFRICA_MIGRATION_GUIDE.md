# Firebase South Africa Migration Guide

## Overview
This guide helps migrate the Fedha app from US Central region to Africa South region for better performance and compliance.

## Current Configuration
- **Old Region**: `us-central1` (United States)
- **New Region**: `africa-south1` (South Africa)
- **Project ID**: `fedha-tracker`

## Migration Steps

### 1. Firebase Functions Migration
✅ **COMPLETED**: Updated Functions to use `africa-south1` region
- Updated `functions/src/index.ts` to set region in `setGlobalOptions`
- Updated `AuthApiClient` base URL to use South Africa endpoints

### 2. Firestore Database Migration
⚠️ **MANUAL STEP REQUIRED**: 
Firebase doesn't support automatic region migration for Firestore. You need to:

1. **Export existing data** (if you have data in US region):
   ```bash
   gcloud firestore export gs://fedha-tracker.appspot.com/firestore-backup
   ```

2. **Create new Firestore database in Africa South**:
   - Go to Firebase Console → Firestore Database
   - Create new database in `africa-south1` region
   - Set security rules

3. **Import data to new region** (if needed):
   ```bash
   gcloud firestore import gs://fedha-tracker.appspot.com/firestore-backup
   ```

### 3. Firebase Storage Migration
⚠️ **MANUAL STEP REQUIRED**:
1. Create new Storage bucket in Africa South region
2. Copy existing files (if any) to new bucket
3. Update storage rules

### 4. Firebase Authentication
✅ **NO ACTION NEEDED**: 
Firebase Auth is global and doesn't require region migration.

### 5. Application Configuration Updates
✅ **COMPLETED**:
- [x] Updated Firebase Functions region
- [x] Updated AuthApiClient base URL
- [x] Firebase config files remain the same (project-level)

## Configuration Changes Made

### Functions (functions/src/index.ts)
```typescript
setGlobalOptions({ 
  maxInstances: 10,
  region: "africa-south1" // South Africa region
});
```

### AuthApiClient (lib/services/auth_api_client.dart)
```dart
static const String baseUrl =
    "https://africa-south1-fedha-tracker.cloudfunctions.net";
```

## Testing the Migration

### 1. Deploy Functions to South Africa
```bash
cd app/functions
npm run build
firebase deploy --only functions
```

### 2. Test Authentication Flow
- Registration
- Login  
- Password reset

### 3. Verify Firestore Operations
- Create profile
- Read/write data
- Query operations

## Rollback Plan
If issues occur, revert by:
1. Changing region back to `us-central1` in `index.ts`
2. Updating base URL back to `us-central1` in `AuthApiClient`
3. Redeploying functions

## Performance Benefits
- **Reduced Latency**: ~200-500ms improvement for South African users
- **Data Residency**: Data stored in South Africa for compliance
- **Better User Experience**: Faster app response times

## Costs Consideration
- Africa South region may have different pricing
- Functions cold starts might be similar
- Firestore operations charged per region

## Next Steps
1. ✅ Update function region configuration
2. ✅ Update client-side URLs
3. ⏳ Deploy functions to South Africa region
4. ⏳ Test authentication flow
5. ⏳ Create Firestore database in Africa South (if needed)
6. ⏳ Migrate existing data (if any)

## Support
For issues during migration:
- Check Firebase Console for region-specific errors
- Monitor function logs in Africa South region
- Test with Firebase Auth emulator if needed
