import 'package:flutter/material.dart';
import '../utils/connection_manager.dart';
import '../utils/logger.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectionDiagnosticsScreen extends StatefulWidget {
  final ApiClient apiClient;
  
  const ConnectionDiagnosticsScreen({
    Key? key,
    required this.apiClient,
  }) : super(key: key);

  @override
  State<ConnectionDiagnosticsScreen> createState() => _ConnectionDiagnosticsScreenState();
}

class _ConnectionDiagnosticsScreenState extends State<ConnectionDiagnosticsScreen> {
  final _logger = AppLogger.getLogger('ConnectionDiagnostics');
  bool _isLoading = false;
  Map<String, ConnectionTestResult> _results = {};
  String _currentApiUrl = '';
  String _systemInfo = '';
  bool _isServerHealthy = false;

  @override
  void initState() {
    super.initState();
    _getCurrentApiUrl();
    _getSystemInfo();
  }

  Future<void> _getCurrentApiUrl() async {
    setState(() {
      _currentApiUrl = widget.apiClient.config.primaryApiUrl;
    });
    
    // Check if the server is healthy
    try {
      final isHealthy = await widget.apiClient.checkServerHealth();
      setState(() {
        _isServerHealthy = isHealthy;
      });
    } catch (e) {
      _logger.severe('Error checking server health: $e');
      setState(() {
        _isServerHealthy = false;
      });
    }
  }

  Future<void> _getSystemInfo() async {
    String info = 'Platform: ';
    
    if (kIsWeb) {
      info += 'Web';
    } else {
      info += Platform.operatingSystem;
      info += ' ${Platform.operatingSystemVersion}';
    }
    
    setState(() {
      _systemInfo = info;
    });
  }

  Future<void> _testAllConnections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await ConnectionManager.testAllConnections();
      
      setState(() {
        _results = results;
      });
    } catch (e) {
      _logger.severe('Error testing connections: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setActiveConnection(String url) async {
    final Uri uri = Uri.parse(url);
    final scheme = uri.scheme;
    final host = uri.host;
    final port = uri.port;
    
    String apiUrl = host;
    if (port != 80 && port != 443) {
      apiUrl += ':$port';
    }
    
    final useSecure = (scheme == 'https');
    
    // Create a new API config with the selected URL
    final newConfig = widget.apiClient.config.copyWith(
      primaryApiUrl: apiUrl,
      useSecureConnections: useSecure,
    );
    
    // Show dialog to confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change API Connection'),
        content: Text('Are you sure you want to change the API connection to $url?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _logger.info('Changing API config to $apiUrl (secure: $useSecure)');
      
      try {
        // Apply the new configuration to the API client
        // Note: This is a simplified approach - in a real app, you might want to
        // update shared preferences or other persistent storage
        widget.apiClient.updateConfig(newConfig);
        
        // Test the new connection
        final isHealthy = await widget.apiClient.checkServerHealth();
        
        setState(() {
          _currentApiUrl = apiUrl;
          _isServerHealthy = isHealthy;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHealthy 
                ? 'Connection successfully changed to $url' 
                : 'Connection changed to $url but server health check failed'
            ),
            backgroundColor: isHealthy ? Colors.green : Colors.orange,
          ),
        );
      } catch (e) {
        _logger.severe('Error changing connection: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change connection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Diagnostics'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Connection Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current API Connection', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      Text('URL: $_currentApiUrl'),
                      const SizedBox(height: 8),
                      Text('System: $_systemInfo'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Status: '),
                          _isServerHealthy
                              ? const Chip(
                                  label: Text('Healthy'),
                                  backgroundColor: Colors.green,
                                  labelStyle: TextStyle(color: Colors.white),
                                )
                              : const Chip(
                                  label: Text('Unhealthy'),
                                  backgroundColor: Colors.red,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Connection Testing
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Connection Testing', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testAllConnections,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Test All Connections'),
                      ),
                      const SizedBox(height: 16),
                      _results.isEmpty && !_isLoading
                          ? const Text('Click "Test All Connections" to begin testing')
                          : _buildResultsList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _results.entries.map((entry) {
        final url = entry.key;
        final result = entry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(url),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${result.statusCode} (${result.responseTime}ms)'),
                if (result.errorMessage != null) Text('Error: ${result.errorMessage}'),
              ],
            ),
            trailing: result.isSuccessful
                ? IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _setActiveConnection(url),
                  )
                : const Icon(Icons.error, color: Colors.red),
            onTap: result.isSuccessful
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Response Details'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Response Body:'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatJson(result.responseBody ?? ''),
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _setActiveConnection(url);
                            },
                            child: const Text('Use This Connection'),
                          ),
                        ],
                      ),
                    );
                  }
                : null,
          ),
        );
      }).toList(),
    );
  }

  String _formatJson(String jsonString) {
    try {
      final object = json.decode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(object);
    } catch (e) {
      return jsonString;
    }
  }
}
