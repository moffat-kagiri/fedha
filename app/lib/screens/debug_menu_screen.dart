import 'package:flutter/material.dart';
import '../config/environment_config.dart';
import 'connection_test_screen.dart';

class DebugMenuScreen extends StatelessWidget {
  final EnvironmentConfig envConfig;
  
  const DebugMenuScreen({
    Key? key,
    required this.envConfig,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Menu'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Environment Information'),
            subtitle: Text('Current: ${envConfig.environment}'),
            trailing: Icon(
              envConfig.isProduction ? Icons.warning : Icons.developer_mode,
              color: envConfig.isProduction ? Colors.red : Colors.green,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('Connectivity Test'),
            subtitle: const Text('Test API server connectivity'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConnectivityTestScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Force Sync'),
            subtitle: const Text('Force data synchronization'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync initiated')),
              );
              // Implement sync logic here
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Clear Local Data'),
            subtitle: const Text('Delete all local data'),
            onTap: () {
              _showClearDataDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Toggle Offline Mode'),
            subtitle: const Text('Force the app to work offline'),
            trailing: const Switch(value: false, onChanged: null),
            onTap: () {
              // Implement offline mode toggle
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Crash Reports'),
            subtitle: const Text('View recent crash reports'),
            onTap: () {
              // Implement crash report viewer
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('View Logs'),
            subtitle: const Text('View application logs'),
            onTap: () {
              // Implement log viewer
            },
          ),
        ],
      ),
    );
  }
  
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Local Data?'),
          content: const Text(
            'This will delete all local data including saved profiles, transactions, and settings. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local data cleared')),
                );
                // Implement data clearing logic
              },
            ),
          ],
        );
      },
    );
  }
}
