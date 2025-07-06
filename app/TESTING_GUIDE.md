// Testing guide for Fedha Financial Management App

# Testing Guide

## Running Tests

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
dart run test_integration_final.dart
```

### SMS Extraction Tests
```bash
dart run test_sms_extraction.dart
```

## Test Categories

### 1. SMS Processing Tests
- M-PESA message parsing
- Bank SMS parsing
- Transaction extraction accuracy
- Confidence scoring validation

### 2. Financial Calculation Tests
- Loan calculations
- Interest computations
- Investment projections
- Goal progress tracking

### 3. Data Management Tests
- Local database operations
- CSV import/export
- Data backup and restore
- Transaction CRUD operations

### 4. User Interface Tests
- Screen navigation
- Form validation
- Widget rendering
- Cross-platform compatibility

## Test Data

The testing framework includes sample data for:
- M-PESA transactions
- Bank transactions
- User profiles
- Financial goals
- Budget categories

## Continuous Integration

Tests are automatically run on:
- Pull requests
- Main branch commits
- Release preparations

## Manual Testing

For manual testing, use the test files:
- `test_connectivity.dart` - API connectivity
- `test_biometric_flow.dart` - Authentication flow
- `test_transaction_editing.dart` - Transaction management
- `test_goal_updates.dart` - Goal tracking

## Debugging

Enable debug mode for detailed logging:
```bash
flutter run --debug
```

## Coverage

Target code coverage: 80%
Current coverage: Run `flutter test --coverage` to check.