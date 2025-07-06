# Fedha App Tests

This directory contains clean, minimal tests for the Fedha app after the Firebase cleanup and test file reorganization.

## Test Structure

### Current Test Files
- `widget_test.dart` - Basic Flutter widget tests
- `hive_storage_test.dart` - Placeholder for local storage tests  
- `services_test.dart` - Placeholder for service layer tests

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

## Test Status

✅ **All tests passing** - The current test suite consists of placeholder tests that verify the testing infrastructure works correctly.

## Next Steps

Once the main app compilation issues are resolved, these placeholder tests can be expanded to include:

### Unit Tests
- Service layer functionality
- Model validation
- Utility functions
- Hive storage operations

### Widget Tests  
- Screen rendering
- User interaction
- Navigation flow
- Form validation

### Integration Tests
- End-to-end workflows
- Data persistence
- Service integration

## Writing New Tests

When adding new tests:

1. **Unit tests**: Test individual functions/classes in isolation
2. **Widget tests**: Test UI components and user interactions
3. **Integration tests**: Test complete user workflows

### Test Naming Convention
- Use descriptive test names that explain what is being tested
- Group related tests using `group()` blocks
- Use `setUp()` and `tearDown()` for test initialization and cleanup

### Best Practices
- Keep tests focused and independent
- Use proper mocking for external dependencies
- Test both success and failure scenarios
- Maintain good test coverage without over-testing

## Test Dependencies

The current test setup uses:
- `flutter_test` - Flutter testing framework
- Future additions may include:
  - `mockito` or `mocktail` for mocking
  - `integration_test` for end-to-end testing
  - `golden_toolkit` for golden file testing
- Use descriptive test names: `'Should save profile data to Hive storage'`
- Group related tests with `group()` 
- Use `setUp()` and `tearDown()` for test initialization/cleanup

### Hive Testing
For tests involving Hive storage:
```dart
setUpAll(() async {
  await Hive.initFlutter();
  // Register required adapters
});

tearDownAll(() async {
  await Hive.deleteFromDisk();
});
```

## Test Dependencies

The tests use:
- `flutter_test` - Core testing framework
- `hive_flutter` - For storage testing
- Standard Flutter testing utilities

No Firebase or external service dependencies - all tests run locally.
