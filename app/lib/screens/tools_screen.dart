import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tools = [
      {'title': 'Investment Calculator', 'icon': Icons.show_chart, 'route': '/investment_calculator'},
      {'title': 'Emergency Fund', 'icon': Icons.sos, 'route': '/emergency-fund'},
      {'title': 'Debt Planner', 'icon': Icons.account_balance, 'route': '/debt_repayment_planner'},
  {'title': 'Asset Protection', 'icon': Icons.umbrella, 'route': '/asset_protection'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: FedhaColors.primaryGreen,
        title: Text(
          'Financial Tools',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: Colors.white),
        ),
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
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(context, tool['route'] as String),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(tool['icon'] as IconData, size: 40, color: FedhaColors.primaryGreen),
                            const SizedBox(height: 12),
                            Text(
                              tool['title'] as String,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'More features coming soon! Stay tuned for updates.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
