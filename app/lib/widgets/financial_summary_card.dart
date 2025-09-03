import 'package:flutter/material.dart';

class FinancialSummaryItem {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  FinancialSummaryItem({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

class FinancialSummaryCard extends StatelessWidget {
  final String title;
  final List<FinancialSummaryItem> items;
  final VoidCallback? onTap;

  const FinancialSummaryCard({
    super.key,
    required this.title,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (items.length <= 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: items.map((item) => _buildSummaryItem(item, context)).toList(),
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: items.map((item) => _buildSummaryItem(item, context)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(FinancialSummaryItem item, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(item.icon, color: item.color, size: 24),
          const SizedBox(height: 4),
        ],
        Text(
          item.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: item.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
