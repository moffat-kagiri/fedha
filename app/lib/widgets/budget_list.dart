import 'package:flutter/material.dart';
import '../data/app_database.dart';
import 'budget_card.dart';

class BudgetList extends StatelessWidget {
  final List<Budget> budgets;

  const BudgetList({
    Key? key,
    required this.budgets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return const Center(
        child: Text('No budgets found. Tap + to create one.'),
      );
    }

    return ListView.builder(
      itemCount: budgets.length,
      itemBuilder: (context, index) => BudgetCard(
        budget: budgets[index],
      ),
    );
  }
}
