// test/integration/goal_transaction_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fedha/models/goal.dart';
import 'package:fedha/models/transaction.dart';
import 'package:fedha/services/offline_data_service.dart';
import 'package:fedha/services/goal_transaction_service.dart';

/// Integration tests for goal-transaction functionality
/// Tests automatic goal allocation and progress tracking
void main() {
  group('Goal-Transaction Integration', () {
    late OfflineDataService dataService;
    late GoalTransactionService goalService;
    late String testProfileId;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();

      // Register required adapters (minimal set for testing)
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TransactionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(GoalAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(GoalTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(GoalStatusAdapter());
      }
    });

    setUp(() async {
      // Open test boxes
      await Hive.openBox<Transaction>('test_transactions');
      await Hive.openBox<Goal>('test_goals');

      dataService = OfflineDataService();
      goalService = GoalTransactionService(dataService);
      testProfileId = 'test-profile-123';
    });

    tearDown(() async {
      // Clean up test data
      await Hive.box<Transaction>('test_transactions').clear();
      await Hive.box<Goal>('test_goals').clear();
    });

    test('should verify goal transaction API', () async {
      // This is a placeholder test that simply verifies that the API exists
      // and can be called without errors. The implementation details are tested
      // in the service tests.

      // Test getSuggestedGoals
      final suggestions = await goalService.getSuggestedGoals(
        testProfileId,
        'emergency fund',
      );
      expect(suggestions, isNotEmpty);

      // Test getGoalProgressSummary
      final summary = await goalService.getGoalProgressSummary('test-goal-id');
      expect(summary, isNotNull);
      expect(summary, isA<Map<String, dynamic>>());

      // Test recommended contribution
      final contribution = await goalService.calculateRecommendedContribution(
        'test-goal-id',
      );
      expect(contribution, isA<double>());
    });
  });
}
