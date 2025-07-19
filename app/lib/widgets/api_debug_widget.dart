import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// Debug widget for testing API connectivity during development
/// Shows current server configuration and allows testing different endpoints
class ApiDebugWidget extends StatefulWidget {
  const ApiDebugWidget({Key? key}) : super(key: key);

  @override
  State<ApiDebugWidget> createState() => _ApiDebugWidgetState();
}

class _ApiDebugWidgetState extends State<ApiDebugWidget> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String _connectionStatus = 'Not tested';
  String _currentUrl = '';
  Map<String, String> _serverOptions = {};

  @override
  void initState() {
    super.initState();
    _currentUrl = ApiClient.getBaseUrl();
    _serverOptions = ApiClient.getServerOptions();
  }

  Future<void> _testConnection({String? customUrl}) async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing...';
    });

    try {
      final success = await ApiClient.testConnection(customUrl: customUrl);
      setState(() {
        _connectionStatus = success ? '✅ Connected' : '❌ Failed';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testHealthCheck() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing health check...';
    });

    try {
      final success = await _apiClient.healthCheck();
      setState(() {
        _connectionStatus = success ? '✅ Health check passed' : '❌ Health check failed';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Health check error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink(); // Hide in release mode
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 API Debug Panel',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Current configuration
            Text(
              'Current Server:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _currentUrl,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Connection status
            Row(
              children: [
                Text(
                  'Status: ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(_connectionStatus),
              ],
            ),
            const SizedBox(height: 16),
            
            // Test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _testConnection(),
                  icon: const Icon(Icons.wifi, size: 16),
                  label: const Text('Test Current'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testHealthCheck,
                  icon: const Icon(Icons.favorite, size: 16),
                  label: const Text('Health Check'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Server options for testing
            Text(
              'Test Different Servers:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._serverOptions.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading 
                        ? null 
                        : () => _testConnection(customUrl: entry.value),
                    child: const Text('Test'),
                  ),
                ],
              ),
            )).toList(),
            
            const SizedBox(height: 16),
            Text(
              '💡 For USB debugging: Ensure server is running on http://192.168.100.6:8002',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
