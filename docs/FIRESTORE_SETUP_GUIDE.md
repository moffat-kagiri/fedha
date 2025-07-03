# Firebase Firestore Database Setup Guide

## ✅ **Current Status: Rules Deployed Successfully!**

Your Firestore security rules have been deployed. Now you need to create the database.

## 🗄️ **Next Step: Create Database**

### Manual Database Creation Required
1. Go to [Firebase Console](https://console.firebase.google.com/project/fedha-tracker/firestore)
2. Click **"Create database"**
3. Choose **"Start in production mode"** (rules are already deployed)
4. **Important**: Select **africa-south1** region for South Africa
5. Click **"Done"**

### Step 2: Database Structure
Your database will automatically create collections when data is written, but here's the schema:

```
fedha-tracker (project)
├── profiles (collection)
│   └── {profileId} (document)
│       ├── id: string
│       ├── name: string
│       ├── profileType: "BIZ" | "PERS"
│       ├── passwordHash: string
│       ├── email: string | null
│       ├── baseCurrency: string (default: "KES")
│       ├── timezone: string (default: "GMT+3")
│       ├── firebaseUid: string (for Firebase Auth users)
│       ├── createdAt: timestamp
│       ├── lastLogin: timestamp | null
│       ├── isActive: boolean
│       ├── requirePasswordChange?: boolean
│       └── passwordResetAt?: timestamp
│
├── transactions (collection)
│   └── {transactionId} (document)
│       ├── profileId: string
│       ├── amount: number
│       ├── type: "income" | "expense"
│       ├── category: string
│       ├── description: string
│       ├── date: timestamp
│       └── createdAt: timestamp
│
├── budgets (collection)
│   └── {budgetId} (document)
│       ├── profileId: string
│       ├── name: string
│       ├── amount: number
│       ├── spent: number
│       ├── category: string
│       ├── period: "monthly" | "yearly"
│       ├── isActive: boolean
│       └── createdAt: timestamp
│
└── goals (collection)
    └── {goalId} (document)
        ├── profileId: string
        ├── name: string
        ├── targetAmount: number
        ├── currentAmount: number
        ├── targetDate: timestamp
        ├── isCompleted: boolean
        └── createdAt: timestamp
```

## 🔒 **Security Rules Setup**

The database needs proper security rules to work with your app.

## ⚡ **Testing Database Creation**

After setting up, you can test with:
```bash
# Test account creation
curl -X POST https://africa-south1-fedha-tracker.cloudfunctions.net/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","profileType":"personal","pin":"password123","email":"test@example.com"}'
```

## 🎯 **Next Steps**
1. Create the database in Firebase Console
2. Apply security rules (provided below)
3. Test account creation
4. Verify data appears in Firestore Console
