import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tools = [
      {
        'title': 'Investment Calculator',
        'icon': Icons.show_chart,
        'route': '/investment_calculator',
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
  backgroundColor: FedhaColors.primaryGreen,
  title: Text(
          'Financial Tools',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  // Single InkWell for the tool card
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final route = tool['route'] as String;
                      Navigator.pushNamed(context, route);
                      if (route == '/emergency-fund') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Emergency Fund Calculator...')),
                        );
                      }
                    },
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
                              style: textTheme.bodyLarge?.copyWith(
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
              ), // close GridView.count
            ), // close Expanded
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
