import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fedha/data/app_database.dart';

class BudgetSummaryCard extends StatelessWidget {
  final Budget budget;
  
  const BudgetSummaryCard({super.key, required this.budget});
  
  @override
  Widget build(BuildContext context) {
    final spentAmount = budget.spentAmount ?? 0;
    final progress = budget.limitMinor > 0 ? spentAmount / budget.limitMinor : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              budget.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1.0 ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(spentAmount / 100).toStringAsFixed(2)} / ${(budget.limitMinor / 100).toStringAsFixed(2)} ${budget.currency}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}