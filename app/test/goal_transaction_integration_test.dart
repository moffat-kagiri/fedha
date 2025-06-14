// test/goal_transaction_integration_test.dart

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

    test('should create savings transaction and link to goal', () async {
      // Create a test goal
      final goal = Goal(
        name: 'Emergency Fund',
        description: 'Save for emergencies',
        targetAmount: 1000.0,
        currentAmount: 0.0,
        targetDate: DateTime.now().add(const Duration(days: 365)),
        goalType: GoalType.emergencyFund,
        status: GoalStatus.active,
        profileId: testProfileId,
      );

      await dataService.saveGoal(
        goal,
      ); // Create savings transaction using goal service
      final transaction = await goalService.createSavingsTransaction(
        profileId: testProfileId,
        amount: 100.0,
        category: TransactionCategory.other,
        date: DateTime.now(),
        description: 'Emergency fund contribution',
        goalId: goal.id,
      );

      // Verify transaction was created and linked to goal
      expect(transaction.goalId, equals(goal.id));
      expect(transaction.amount, equals(100.0));
      expect(transaction.type, equals(TransactionType.savings));

      // Verify goal progress was updated
      final updatedGoal = await dataService.getGoal(goal.id);
      expect(updatedGoal?.currentAmount, equals(100.0));
    });

    test(
      'should automatically match transactions to goals based on description',
      () async {
        // Create test goals
        final emergencyGoal = Goal(
          name: 'Emergency Fund',
          description: 'Emergency savings',
          targetAmount: 1000.0,
          currentAmount: 0.0,
          targetDate: DateTime.now().add(const Duration(days: 365)),
          goalType: GoalType.emergencyFund,
          status: GoalStatus.active,
          profileId: testProfileId,
        );

        final vacationGoal = Goal(
          name: 'Vacation Fund',
          description: 'Save for vacation',
          targetAmount: 2000.0,
          currentAmount: 0.0,
          targetDate: DateTime.now().add(const Duration(days: 365)),
          goalType: GoalType.savings,
          status: GoalStatus.active,
          profileId: testProfileId,
        );

        await dataService.saveGoal(emergencyGoal);
        await dataService.saveGoal(vacationGoal);

        // Test emergency fund matching
        final emergencyMatches = await goalService.getSuggestedGoals(
          testProfileId,
          'emergency fund contribution',
        );
        expect(emergencyMatches.length, greaterThan(0));
        expect(emergencyMatches.first.id, equals(emergencyGoal.id));

        // Test vacation fund matching
        final vacationMatches = await goalService.getSuggestedGoals(
          testProfileId,
          'vacation savings',
        );
        expect(vacationMatches.length, greaterThan(0));
        expect(vacationMatches.first.id, equals(vacationGoal.id));
      },
    );

    test('should calculate goal progress summary correctly', () async {
      // Create a test goal
      final goal = Goal(
        name: 'Test Goal',
        description: 'Test goal for progress calculation',
        targetAmount: 1000.0,
        currentAmount: 0.0,
        targetDate: DateTime.now().add(const Duration(days: 100)),
        goalType: GoalType.savings,
        status: GoalStatus.active,
        profileId: testProfileId,
      );

      await dataService.saveGoal(goal); // Create multiple savings transactions
      await goalService.createSavingsTransaction(
        profileId: testProfileId,
        amount: 100.0,
        category: TransactionCategory.other,
        date: DateTime.now(),
        description: 'First contribution',
        goalId: goal.id,
      );

      await goalService.createSavingsTransaction(
        profileId: testProfileId,
        amount: 200.0,
        category: TransactionCategory.other,
        date: DateTime.now(),
        description: 'Second contribution',
        goalId: goal.id,
      );

      // Get progress summary
      final summary = await goalService.getGoalProgressSummary(goal.id);

      expect(summary.totalContributions, equals(300.0));
      expect(summary.progressPercentage, equals(30.0));
      expect(summary.remainingAmount, equals(700.0));
      expect(summary.contributionTransactions.length, equals(2));
      expect(summary.isCompleted, isFalse);
    });

    test('should mark goal as completed when target is reached', () async {
      // Create a test goal
      final goal = Goal(
        name: 'Small Goal',
        description: 'Test goal completion',
        targetAmount: 100.0,
        currentAmount: 0.0,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        goalType: GoalType.savings,
        status: GoalStatus.active,
        profileId: testProfileId,
      );

      await dataService.saveGoal(
        goal,
      ); // Create savings transaction that completes the goal
      await goalService.createSavingsTransaction(
        profileId: testProfileId,
        amount: 100.0,
        category: TransactionCategory.other,
        date: DateTime.now(),
        description: 'Goal completion',
        goalId: goal.id,
      );

      // Verify goal is marked as completed
      final updatedGoal = await dataService.getGoal(goal.id);
      expect(updatedGoal?.status, equals(GoalStatus.completed));
      expect(updatedGoal?.currentAmount, equals(100.0));

      // Verify progress summary shows completion
      final summary = await goalService.getGoalProgressSummary(goal.id);
      expect(summary.isCompleted, isTrue);
      expect(summary.progressPercentage, equals(100.0));
    });
  });
}
