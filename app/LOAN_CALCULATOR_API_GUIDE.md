# Fedha Loan Calculator API Usage Guide

## Overview
The Fedha Loan Calculator API provides comprehensive financial calculation capabilities for loan payments, interest rates, amortization schedules, and investment analysis. This guide demonstrates how to use the enhanced API client in your Flutter application.

## API Client Setup

### Import the API Client
```dart
import 'package:fedha/services/api_client.dart';
```

### Initialize the Client
```dart
final apiClient = ApiClient();
```

## Available Methods

### 1. Health Check
Verify API connectivity before making calculations.

```dart
try {
  final isHealthy = await apiClient.healthCheck();
  if (isHealthy) {
    print('API is ready for calculations');
  }
} catch (e) {
  print('API connection failed: $e');
}
```

### 2. Basic Loan Payment Calculation
Calculate monthly payments for loans with different interest types.

```dart
try {
  final result = await apiClient.calculateLoanPayment(
    principal: 200000.00,        // Loan amount
    annualRate: 4.5,            // Annual interest rate (%)
    termYears: 30,              // Loan term in years
    interestType: 'REDUCING',    // Interest calculation method
    paymentFrequency: 'MONTHLY', // Payment frequency
  );

  print('Monthly Payment: \$${result['monthly_payment']}');
  print('Total Amount: \$${result['total_amount']}');
  print('Total Interest: \$${result['total_interest']}');
  print('Number of Payments: ${result['total_payments']}');
} catch (e) {
  print('Calculation error: $e');
}
```

**Interest Types:**
- `SIMPLE` - Simple interest calculation
- `COMPOUND` - Compound interest calculation  
- `REDUCING` - Reducing balance (most common for loans)
- `FLAT` - Flat rate calculation

**Payment Frequencies:**
- `MONTHLY` - 12 payments per year
- `QUARTERLY` - 4 payments per year
- `SEMI_ANNUALLY` - 2 payments per year
- `ANNUALLY` - 1 payment per year

### 3. Interest Rate Solver
Calculate the interest rate given loan amount, payment, and term.

```dart
try {
  final result = await apiClient.solveInterestRate(
    principal: 200000.00,        // Loan amount
    payment: 1013.37,           // Monthly payment amount
    termYears: 30,              // Loan term
    paymentFrequency: 'MONTHLY', // Payment frequency
    tolerance: 0.00001,         // Calculation precision (optional)
    maxIterations: 100,         // Maximum iterations (optional)
  );

  print('Calculated Rate: ${result['annual_rate']}%');
  print('Iterations: ${result['iterations']}');
  print('Converged: ${result['converged']}');
} catch (e) {
  print('Rate calculation error: $e');
}
```

### 4. Amortization Schedule
Generate a complete payment schedule showing principal and interest breakdown.

```dart
try {
  final result = await apiClient.generateAmortizationSchedule(
    principal: 200000.00,
    annualRate: 4.5,
    termYears: 30,
    paymentFrequency: 'MONTHLY',
  );

  print('Total Payments: ${result['total_payments']}');
  print('Monthly Payment: \$${result['payment_amount']}');
  
  // Access individual payment details
  final schedule = result['schedule'] as List;
  for (int i = 0; i < 12; i++) { // First year
    final payment = schedule[i];
    print('Payment ${payment['payment_number']}: '
          'Principal: \$${payment['principal_payment']}, '
          'Interest: \$${payment['interest_payment']}, '
          'Balance: \$${payment['remaining_balance']}');
  }
} catch (e) {
  print('Schedule generation error: $e');
}
```

### 5. Early Payment Savings
Calculate savings from making extra payments on your loan.

```dart
try {
  final result = await apiClient.calculateEarlyPaymentSavings(
    principal: 200000.00,
    annualRate: 4.5,
    termYears: 30,
    extraPayment: 200.00,       // Extra payment amount
    paymentFrequency: 'MONTHLY',
    extraPaymentType: 'MONTHLY', // 'MONTHLY' or 'ONE_TIME'
  );

  print('Interest Savings: \$${result['interest_savings']}');
  print('Time Savings: ${result['time_savings_months']} months');
  print('New Term: ${result['new_term_months']} months');
  print('Original Interest: \$${result['original_total_interest']}');
  print('New Interest: \$${result['new_total_interest']}');
} catch (e) {
  print('Early payment calculation error: $e');
}
```

### 6. Return on Investment (ROI)
Calculate investment returns and annualized performance.

```dart
try {
  final result = await apiClient.calculateROI(
    initialInvestment: 10000.00, // Initial investment amount
    finalValue: 15000.00,        // Final value after time period
    timeYears: 3.0,             // Investment period (optional)
  );

  print('ROI: ${result['roi_percentage']}%');
  print('Total Return: \$${result['total_return']}');
  if (result['annualized_return'] != null) {
    print('Annualized Return: ${result['annualized_return']}%');
  }
} catch (e) {
  print('ROI calculation error: $e');
}
```

### 7. Compound Interest with Contributions
Calculate compound interest with regular contributions.

```dart
try {
  final result = await apiClient.calculateCompoundInterest(
    principal: 5000.00,          // Initial amount
    annualRate: 7.0,            // Annual interest rate
    timeYears: 10.0,            // Investment period
    compoundingFrequency: 'MONTHLY', // How often interest compounds
    additionalPayment: 200.00,   // Regular contribution amount
    additionalFrequency: 'MONTHLY', // Contribution frequency
  );

  print('Future Value: \$${result['future_value']}');
  print('Total Interest: \$${result['total_interest']}');
  print('Total Contributions: \$${result['total_contributions']}');
  print('Principal Growth: \$${result['principal_growth']}');
} catch (e) {
  print('Compound interest calculation error: $e');
}
```

### 8. Portfolio Metrics
Analyze investment portfolio performance.

```dart
try {
  final investments = [
    {'weight': 0.6, 'return': 8.5}, // 60% allocation, 8.5% return
    {'weight': 0.3, 'return': 5.2}, // 30% allocation, 5.2% return
    {'weight': 0.1, 'return': 12.1}, // 10% allocation, 12.1% return
  ];

  final result = await apiClient.calculatePortfolioMetrics(
    investments: investments,
  );

  print('Portfolio Return: ${result['weighted_return']}%');
  print('Risk (Std Dev): ${result['portfolio_risk']}%');
  print('Sharpe Ratio: ${result['sharpe_ratio']}');
} catch (e) {
  print('Portfolio calculation error: $e');
}
```

### 9. Risk Assessment
Assess investment risk profile based on questionnaire responses.

```dart
try {
  final answers = [4, 3, 5, 2, 4]; // Risk questionnaire answers (1-5 scale)

  final result = await apiClient.assessRiskProfile(
    answers: answers,
  );

  print('Risk Score: ${result['risk_score']}');
  print('Risk Level: ${result['risk_level']}'); // Conservative, Moderate, Aggressive
  print('Recommended Allocation: ${result['recommended_allocation']}');
} catch (e) {
  print('Risk assessment error: $e');
}
```

## Error Handling

### Network Errors
```dart
try {
  final result = await apiClient.calculateLoanPayment(/* parameters */);
  // Use result
} on SocketException {
  // Handle network connectivity issues
  showErrorMessage('No internet connection. Please check your network.');
} on TimeoutException {
  // Handle request timeouts
  showErrorMessage('Request timed out. Please try again.');
} on HttpException catch (e) {
  // Handle HTTP errors
  showErrorMessage('Server error: ${e.message}');
} catch (e) {
  // Handle other errors
  showErrorMessage('Calculation error: ${e.toString()}');
}
```

### Validation Errors
```dart
try {
  final result = await apiClient.calculateLoanPayment(
    principal: -1000, // Invalid: negative principal
    annualRate: 4.5,
    termYears: 30,
    interestType: 'REDUCING',
    paymentFrequency: 'MONTHLY',
  );
} catch (e) {
  if (e.toString().contains('validation')) {
    showErrorMessage('Invalid input: Please check your values');
  }
}
```

## Integration Examples

### Loan Calculator Widget
```dart
class LoanCalculatorWidget extends StatefulWidget {
  @override
  _LoanCalculatorWidgetState createState() => _LoanCalculatorWidgetState();
}

class _LoanCalculatorWidgetState extends State<LoanCalculatorWidget> {
  final _apiClient = ApiClient();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculatePayment() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _apiClient.calculateLoanPayment(
        principal: double.parse(_principalController.text),
        annualRate: double.parse(_rateController.text),
        termYears: int.parse(_termController.text),
        interestType: 'REDUCING',
        paymentFrequency: 'MONTHLY',
      );
      
      setState(() => _result = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _principalController,
          decoration: InputDecoration(labelText: 'Loan Amount'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _rateController,
          decoration: InputDecoration(labelText: 'Interest Rate (%)'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _termController,
          decoration: InputDecoration(labelText: 'Term (Years)'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _calculatePayment,
          child: _isLoading 
            ? CircularProgressIndicator() 
            : Text('Calculate'),
        ),
        if (_result != null) ...[
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Monthly Payment: \$${_result!['monthly_payment']}'),
                  Text('Total Interest: \$${_result!['total_interest']}'),
                  Text('Total Amount: \$${_result!['total_amount']}'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
```

### Investment Tracking Widget
```dart
class InvestmentTracker extends StatefulWidget {
  @override
  _InvestmentTrackerState createState() => _InvestmentTrackerState();
}

class _InvestmentTrackerState extends State<InvestmentTracker> {
  final _apiClient = ApiClient();
  
  Future<void> _calculateCompoundGrowth() async {
    try {
      final result = await _apiClient.calculateCompoundInterest(
        principal: 10000,
        annualRate: 7.5,
        timeYears: 20,
        compoundingFrequency: 'MONTHLY',
        additionalPayment: 500,
        additionalFrequency: 'MONTHLY',
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Investment Projection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Future Value: \$${result['future_value']}'),
              Text('Total Interest: \$${result['total_interest']}'),
              Text('Total Contributions: \$${result['total_contributions']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _calculateCompoundGrowth,
      child: Text('Project Investment Growth'),
    );
  }
}
```

## Testing and Validation

### Unit Testing API Methods
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fedha/services/api_client.dart';

void main() {
  group('Loan Calculator API Tests', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    test('should calculate loan payment correctly', () async {
      final result = await apiClient.calculateLoanPayment(
        principal: 100000,
        annualRate: 5.0,
        termYears: 30,
        interestType: 'REDUCING',
        paymentFrequency: 'MONTHLY',
      );

      expect(result['monthly_payment'], isNotNull);
      expect(double.parse(result['monthly_payment']), greaterThan(0));
    });

    test('should handle invalid input gracefully', () async {
      expect(
        () => apiClient.calculateLoanPayment(
          principal: -1000, // Invalid
          annualRate: 5.0,
          termYears: 30,
          interestType: 'REDUCING',
          paymentFrequency: 'MONTHLY',
        ),
        throwsException,
      );
    });
  });
}
```

## Performance Optimization

### Caching Results
```dart
class CachedApiClient {
  final ApiClient _apiClient = ApiClient();
  final Map<String, dynamic> _cache = {};

  Future<Map<String, dynamic>> calculateLoanPayment({
    required double principal,
    required double annualRate,
    required int termYears,
    required String interestType,
    required String paymentFrequency,
  }) async {
    final key = '$principal-$annualRate-$termYears-$interestType-$paymentFrequency';
    
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    final result = await _apiClient.calculateLoanPayment(
      principal: principal,
      annualRate: annualRate,
      termYears: termYears,
      interestType: interestType,
      paymentFrequency: paymentFrequency,
    );

    _cache[key] = result;
    return result;
  }
}
```

### Debounced Calculations
```dart
import 'dart:async';

class DebouncedCalculator {
  final ApiClient _apiClient = ApiClient();
  Timer? _debounceTimer;

  void calculateWithDebounce({
    required double principal,
    required double annualRate,
    required int termYears,
    required Function(Map<String, dynamic>) onResult,
    required Function(String) onError,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      try {
        final result = await _apiClient.calculateLoanPayment(
          principal: principal,
          annualRate: annualRate,
          termYears: termYears,
          interestType: 'REDUCING',
          paymentFrequency: 'MONTHLY',
        );
        onResult(result);
      } catch (e) {
        onError(e.toString());
      }
    });
  }
}
```

## Security Considerations

### Input Validation
```dart
class ValidationHelper {
  static bool isValidPrincipal(double principal) {
    return principal > 0 && principal <= 10000000; // Max 10M
  }

  static bool isValidRate(double rate) {
    return rate >= 0 && rate <= 100;
  }

  static bool isValidTerm(int years) {
    return years > 0 && years <= 50;
  }

  static String? validateLoanInputs({
    required double principal,
    required double annualRate,
    required int termYears,
  }) {
    if (!isValidPrincipal(principal)) {
      return 'Principal must be between \$1 and \$10,000,000';
    }
    if (!isValidRate(annualRate)) {
      return 'Interest rate must be between 0% and 100%';
    }
    if (!isValidTerm(termYears)) {
      return 'Term must be between 1 and 50 years';
    }
    return null;
  }
}
```

## Troubleshooting

### Common Issues

1. **Network Connectivity**
   - Ensure Django server is running on `http://127.0.0.1:8000`
   - Check firewall settings
   - Verify API endpoints are accessible

2. **Invalid Parameters**
   - Validate all numeric inputs
   - Check enum values match API expectations
   - Ensure required fields are provided

3. **Calculation Errors**
   - Verify input ranges are reasonable
   - Check for division by zero scenarios
   - Ensure convergence criteria are met

### Debug Mode
```dart
class DebugApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> calculateLoanPayment({
    required double principal,
    required double annualRate,
    required int termYears,
    required String interestType,
    required String paymentFrequency,
  }) async {
    print('Debug: Calculating loan payment with:');
    print('  Principal: $principal');
    print('  Rate: $annualRate%');
    print('  Term: $termYears years');
    print('  Type: $interestType');
    print('  Frequency: $paymentFrequency');

    final result = await super.calculateLoanPayment(
      principal: principal,
      annualRate: annualRate,
      termYears: termYears,
      interestType: interestType,
      paymentFrequency: paymentFrequency,
    );

    print('Debug: Result = $result');
    return result;
  }
}
```

## API Response Formats

### Successful Response
```json
{
  "monthly_payment": "1013.37",
  "total_amount": "364813.42",
  "total_interest": "164813.42",
  "payment_amount": "1013.37",
  "total_payments": 360
}
```

### Error Response
```json
{
  "error": "Validation error: Principal must be positive",
  "details": {
    "principal": ["This field must be greater than 0"]
  }
}
```

---

This comprehensive guide covers all aspects of using the enhanced Fedha Loan Calculator API. For additional support, refer to the API documentation or contact the development team.
