import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tools = [
      {
        'title': 'Loan Calculator',
        'icon': Icons.calculate,
        'route': '/loan_calculator',
      },
      {
        'title': 'Emergency Fund',
        'icon': Icons.sos,
        'route': '/emergency-fund',
      },
      {
        'title': 'Debt Planner',
        'icon': Icons.account_balance,
        'route': '/debt_repayment_planner',
      },
      {
        'title': 'Asset Protection',
        'icon': Icons.umbrella,
        'route': '/asset_protection',
      },
    ];

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Financial Tools',
          style: textTheme.headline6?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: tools.map((tool) {
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, tool['route'] as String),
                    child: Card(
                      color: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tool['icon'] as IconData,
                              size: 40,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tool['title'] as String,
                              style: textTheme.subtitle1?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'More tools coming soon...',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
