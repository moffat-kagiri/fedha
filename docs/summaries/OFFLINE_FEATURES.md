# 📱 Fedha - Offline-First Personal Finance App

## 🌟 New Offline Capabilities

Fedha now works **90% offline** with only selective features requiring internet connectivity. This makes it perfect for users in areas with poor connectivity or those who want to minimize data usage.

### ✅ What Works Offline

#### 🔍 **SMS Transaction Detection**
- **Real-time SMS parsing** using local pattern matching
- Supports major Kenyan financial institutions:
  - M-Pesa (Safaricom)
  - Airtel Money
  - Equity Bank
  - KCB Bank
  - Co-operative Bank
  - Generic patterns for other providers
- **Intelligent categorization** based on transaction description
- **No internet required** for SMS extraction

#### 💰 **Loan Calculator**
- **Complete loan calculations** without internet:
  - Monthly payment calculation
  - Interest rate solving (given payment amount)
  - Amortization schedules
  - Early payment savings analysis
  - Multiple interest types (Reducing Balance, Flat Rate, Simple, Compound)
  - Multiple payment frequencies (Monthly, Quarterly, Semi-Annual, Annual)
- **Investment calculations**:
  - Compound interest growth
  - Return on Investment (ROI)
  - Portfolio metrics

#### 💾 **Data Management**
- **Local storage** for all transactions, categories, goals, and budgets
- **Instant data access** without network delays
- **Local search and filtering**
- **Offline data synchronization** when internet becomes available

#### 🎯 **Core App Features**
- Transaction management (add, edit, delete)
- Category management
- Goal tracking and progress
- Budget creation and monitoring
- Dashboard analytics
- Profile management (local changes)

### ❌ What Requires Internet

#### 🔄 **Profile Synchronization**
- Syncing profile changes across devices
- Email/phone number updates on server
- Password changes (requires server verification)

#### 📧 **Communication Features**
- Invoice PDF generation and email sending
- Support contact functionality
- Privacy policy updates

#### 🏦 **Advanced Financial Features**
- Tax calculation updates (requires latest tax tables)
- Real-time exchange rates
- Bank account integration (future feature)

## 📊 Technical Implementation

### SMS Parsing Engine
```dart
// Offline SMS parsing with pattern matching
TransactionCandidate? candidate = OfflineSmsParser.parseSms(smsContent);

// Supports patterns like:
// "QAB3X5Y2Z1 Confirmed. You have sent Ksh1,500.00 to JOHN DOE on 22/6/24"
// "Dear Customer, You have received KES 2,500.00 from JANE SMITH"
```

### Loan Calculator Engine
```dart
// Offline loan calculations
LoanCalculationResult result = OfflineLoanCalculator.calculateLoanPayment(
  principal: 1000000,
  annualRate: 12.0,
  termYears: 5,
  interestType: InterestType.reducing,
  paymentFrequency: PaymentFrequency.monthly,
);
```

### App Size Impact
- **Base App**: ~15-20 MB
- **SMS Parsing Patterns**: ~1 MB
- **Loan Calculator Logic**: ~2 MB
- **Total Estimated**: ~23-28 MB
- **Benefit**: 90% functionality works offline

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Android Studio / Xcode (for mobile)
- For backend features: Python + Django

### Installation
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

### Backend Setup (Optional)
The app works fully offline, but you can set up the backend for data synchronization:

1. Navigate to backend directory: `cd backend`
2. Install Python dependencies: `pip install -r requirements.txt`
3. Run the server: `python start_server.py`

## 📱 SMS Permission Setup

For automatic SMS transaction detection:

### Android
- App will request SMS permissions on first run
- Grant "Read SMS" permission for automatic detection
- Alternative: Use manual SMS input feature

### iOS
- Due to platform restrictions, use manual SMS input
- Copy SMS content and paste into the app

## 🎯 Usage Examples

### Automatic Transaction Detection
1. Receive an M-Pesa SMS: "QAB3X5Y2Z1 Confirmed. You have sent Ksh1,500.00 to SUPERMARKET on 22/6/24"
2. App automatically detects and categorizes as "Groceries" expense
3. User reviews and confirms the transaction
4. Transaction is saved locally (no internet required)

### Loan Calculation
1. Open loan calculator from tools menu
2. Enter loan amount (e.g., Ksh 1,000,000)
3. Set interest rate (e.g., 12% per annum)
4. Choose loan term (e.g., 5 years)
5. Get instant results: monthly payment, total interest, amortization schedule

### Offline Goal Tracking
1. Create savings goals (e.g., "Emergency Fund - Ksh 500,000")
2. Track progress with each transaction
3. View progress charts and statistics
4. All calculations done locally

## 🔧 Configuration

### SMS Parsing Customization
Add new SMS patterns in `lib/services/offline_sms_parser.dart`:

```dart
SmsPattern(
  provider: 'Your Bank',
  pattern: r'Your regex pattern here',
  type: TransactionType.expense,
  amountGroup: 1,
  descriptionGroup: 2,
),
```

### Loan Calculator Customization
Modify interest calculation methods in `lib/services/offline_loan_calculator.dart` for specific requirements.

## 🛠️ Development

### Project Structure
```
lib/
├── models/              # Data models
├── services/           
│   ├── offline_sms_parser.dart     # SMS parsing engine
│   ├── offline_loan_calculator.dart # Loan calculation engine
│   ├── offline_manager.dart        # Offline coordinator
│   └── ...
├── widgets/
│   ├── offline_loan_calculator_widget.dart # Loan calculator UI
│   └── ...
└── screens/            # App screens
```

### Adding New Offline Features
1. Implement core logic in `services/`
2. Add to `OfflineManager` for coordination
3. Create UI components in `widgets/`
4. Update feature flags in `getOfflineCapabilities()`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add offline-first functionality when possible
4. Test without internet connectivity
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎉 Benefits Summary

✅ **90% offline functionality**  
✅ **Instant SMS transaction detection**  
✅ **Complete loan calculations without internet**  
✅ **Works in poor connectivity areas**  
✅ **Reduces data usage significantly**  
✅ **Faster user experience**  
✅ **Privacy-focused (data stays local)**  
✅ **No dependency on server uptime for core features**

---

*Fedha: Making personal finance accessible everywhere, even offline! 🌍*
