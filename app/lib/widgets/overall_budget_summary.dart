import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../theme/app_theme.dart';

class OverallBudgetSummary extends StatelessWidget {
  final List<Budget> budgets;

  const OverallBudgetSummary({
    super.key,
    required this.budgets,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.budgetAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final remaining = totalBudget - totalSpent;
    final progress = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

    final color = progress > 0.9
        ? FedhaColors.errorRed
        : progress > 0.75
            ? FedhaColors.warningOrange
            : FedhaColors.successGreen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Budget', totalBudget, colorScheme.onSurface, textTheme),
                _buildSummaryItem('Spent', totalSpent, color, textTheme),
                _buildSummaryItem('Remaining', remaining, 
                    remaining >= 0 ? FedhaColors.successGreen : FedhaColors.errorRed, textTheme),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceVariant,
              color: color,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% used',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (progress < 1.0)
                  Text(
                    '${((1 - progress) * 100).toStringAsFixed(1)}% remaining',
                    style: textTheme.bodySmall?.copyWith(
                      color: FedhaColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, TextTheme textTheme) {
    return Column(
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          'KSh ${amount.toStringAsFixed(0)}',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
