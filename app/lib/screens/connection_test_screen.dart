// lib/screens/connection_test_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool _isLoading = false;
  String _status = 'Not tested';
  Color _statusColor = Colors.grey;
  String? _serverUrl;
  Map<String, dynamic>? _healthData;

  @override
  void initState() {
    super.initState();
    _serverUrl = ApiClient.instance.baseUrl;
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
      _statusColor = Colors.orange;
      _healthData = null;
    });

    try {
      final apiClient = ApiClient.instance;
      final isHealthy = await apiClient.checkServerHealth();

      if (isHealthy) {
        setState(() {
          _status = '✅ Connected Successfully!';
          _statusColor = Colors.green;
        });
      } else {
        setState(() {
          _status = '❌ Connection Failed';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: ${e.toString()}';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Connection Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Server URL Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Server URL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _serverUrl ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Environment: ${ApiClient.instance.config.toString()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Card
            Card(
              color: _statusColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _statusColor == Colors.green
                          ? Icons.check_circle
                          : _statusColor == Colors.red
                              ? Icons.error
                              : Icons.info,
                      size: 64,
                      color: _statusColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(_isLoading ? 'Testing...' : 'Test Connection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // Troubleshooting Tips
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Troubleshooting Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTip('1. Phone and computer on same WiFi'),
            _buildTip('2. Django server running on 0.0.0.0:8000'),
            _buildTip('3. Firewall allows port 8000'),
            _buildTip('4. IP address in api_config.dart is correct'),
            const SizedBox(height: 24),

            // Quick Actions
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigate to settings to change server
                    Navigator.pushNamed(context, '/ip_settings');
                  },
                  child: const Text('Change Server'),
                ),
                OutlinedButton(
                  onPressed: () {
                    // Go to device info
                    Navigator.pushNamed(context, '/device_network_info');
                  },
                  child: const Text('Network Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}