import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class ConnectivityTestScreen extends StatefulWidget {
  const ConnectivityTestScreen({Key? key}) : super(key: key);

  @override
  _ConnectivityTestScreenState createState() => _ConnectivityTestScreenState();
}

class _ConnectivityTestScreenState extends State<ConnectivityTestScreen> {
  final ApiClient _apiClient = ApiClient(config: ApiConfig.development());
  String _statusMessage = 'Press a button to test connectivity';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  Future<void> _testPrimaryServer() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing primary server...';
    });
    
    try {
      _apiClient.resetToPrimaryServer();
      final success = await _apiClient.testConnection();
      
      setState(() {
        _isLoading = false;
        _statusMessage = success 
            ? 'Primary server connection successful!'
            : 'Primary server connection failed';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  Future<void> _testFallbackServer() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing fallback server...';
    });
    
    try {
      _apiClient.switchToFallbackServer();
      final success = await _apiClient.testConnection();
      
      setState(() {
        _isLoading = false;
        _statusMessage = success 
            ? 'Fallback server connection successful!'
            : 'Fallback server connection failed';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  Future<void> _testHealthCheck() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking server health...';
    });
    
    try {
      final healthData = await _apiClient.checkServerHealth();
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Health check result: ${healthData.toString()}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivity Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Current API URL:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                _apiClient.baseUrl,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _testPrimaryServer,
                child: const Text('Test Primary Server'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _testFallbackServer,
                child: const Text('Test Fallback Server'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _testHealthCheck,
                child: const Text('Check Server Health'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
