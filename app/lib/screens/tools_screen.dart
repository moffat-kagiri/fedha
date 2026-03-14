import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_service.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  // Routes that require an active server connection
  static const _onlineOnlyRoutes = {
    '/investment_calculator',
    '/asset_protection',
  };

  void _onToolTap(BuildContext context, String route) {
    if (_onlineOnlyRoutes.contains(route)) {
      final connectivity =
          Provider.of<ConnectivityService>(context, listen: false);
      if (connectivity.isOfflineMode) {
        _showOfflineDialog(context);
        return;
      }
    }
    Navigator.pushNamed(context, route);
  }

  void _showOfflineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Connection Required'),
        content: const Text(
          'This feature requires an active internet connection. '
          'Please check your network and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'title': 'Investment Calculator',
        'icon': Icons.show_chart,
        'route': '/investment_calculator',
        'requiresConnection': true,
      },
      {
        'title': 'Emergency Fund',
        'icon': Icons.sos,
        'route': '/emergency-fund',
        'requiresConnection': false,
      },
      {
        'title': 'Debt Planner',
        'icon': Icons.account_balance,
        'route': '/debt_repayment_planner',
        'requiresConnection': false,
      },
      {
        'title': 'Asset Protection',
        'icon': Icons.umbrella,
        'route': '/asset_protection',
        'requiresConnection': true,
      },
    ];

    // Read connectivity once for badge rendering — not for blocking
    final isOffline =
        context.watch<ConnectivityService>().isOfflineMode;

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
                  final requiresConnection =
                      tool['requiresConnection'] as bool;
                  final isUnavailable = requiresConnection && isOffline;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        _onToolTap(context, tool['route'] as String),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tool['icon'] as IconData,
                                  size: 40,
                                  color: isUnavailable
                                      ? Colors.grey
                                      : FedhaColors.primaryGreen,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  tool['title'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isUnavailable
                                            ? Colors.grey
                                            : null,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isUnavailable) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Requires connection',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                            // Offline badge in top-right corner
                            if (isUnavailable)
                              const Positioned(
                                top: 0,
                                right: 0,
                                child: Icon(Icons.cloud_off,
                                    size: 16, color: Colors.grey),
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
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}