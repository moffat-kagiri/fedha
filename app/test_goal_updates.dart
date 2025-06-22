// test_goal_updates.dart
// Simple test to verify goal updates don't create duplicates

import 'package:flutter/material.dart';
import 'lib/models/goal.dart';
import 'lib/services/offline_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test goal update functionality
  await testGoalUpdates();
}

Future<void> testGoalUpdates() async {
  print('Testing goal updates...');

  try {
    final dataService = OfflineDataService();
    await dataService.ensureBoxesOpen();

    // Create a test goal
    final testGoal = Goal(
      name: 'Test Goal',
      goalType: GoalType.savings,
      targetAmount: 1000.0,
      currentAmount: 100.0,
      targetDate: DateTime.now().add(const Duration(days: 30)),
      profileId: 'test_profile',
      currency: 'KES',
    );

    print('Created test goal with ID: ${testGoal.id}');
    print('Initial amount: ${testGoal.currentAmount}');

    // Save the goal
    await dataService.saveGoal(testGoal);

    // Get all goals before update
    final goalsBefore = await dataService.getAllGoals('test_profile');
    print('Goals before update: ${goalsBefore.length}');

    // Update the goal progress
    final updatedGoal = await dataService.updateGoalProgress(testGoal, 50.0);
    print('Updated goal amount: ${updatedGoal.currentAmount}');
    print('Updated goal ID: ${updatedGoal.id}');

    // Get all goals after update
    final goalsAfter = await dataService.getAllGoals('test_profile');
    print('Goals after update: ${goalsAfter.length}');

    // Check for duplicates
    final goalIds = goalsAfter.map((g) => g.id).toSet();
    if (goalIds.length != goalsAfter.length) {
      print('❌ ERROR: Duplicate goals detected!');
      print('Goals: ${goalsAfter.map((g) => '${g.id}: ${g.name}').join(', ')}');
    } else {
      print('✅ SUCCESS: No duplicate goals found');
    }

    // Check if the goal was updated, not duplicated
    final sameGoalCount = goalsAfter.where((g) => g.id == testGoal.id).length;
    if (sameGoalCount == 1) {
      print('✅ SUCCESS: Goal was updated in place');
    } else {
      print('❌ ERROR: Goal was duplicated (found $sameGoalCount instances)');
    }

    // Clean up
    await dataService.deleteGoal(testGoal.id);
  } catch (e) {
    print('❌ ERROR: Test failed with exception: $e');
  }
}
