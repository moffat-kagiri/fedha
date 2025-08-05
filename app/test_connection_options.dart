// Connection Test Script for Fedha App

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import the necessary files from your project
import 'lib/config/api_config.dart';

void main() {
  runApp(const ConnectionTestApp());
}

class ConnectionTestApp extends StatelessWidget {
  const ConnectionTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Fedha Connection Test",
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ConnectionTestScreen(),
    );
  }
}

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({Key? key}) : super(key: key);

  @override
  _ConnectionTestScreenState createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final Map<String, ConnectionTestResult> _results = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runAllTests();
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
    });

    // Test development configuration
    await _testConnection('Development (Local)', ApiConfig.development());
    
    // Test cloudflare configuration
    await _testConnection('Cloudflare Tunnel', ApiConfig.cloudflare());
    
    // Test local configuration
    await _testConnection('Local', ApiConfig.local());
    
    // Test production configuration
    await _testConnection('Production', ApiConfig.production());

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testConnection(String name, ApiConfig config) async {
    setState(() {
      _results[name] = ConnectionTestResult(
        status: "Testing...",
        isConnected: false,
        apiUrl: config.primaryApiUrl,
        fallbackUrl: config.fallbackApiUrl ?? "None",
        useSecureConnections: config.useSecureConnections,
      );
    });

    try {
      // Try to connect to the health endpoint
      final scheme = config.useSecureConnections ? "https" : "http";
      final healthEndpoint = "$scheme://${config.primaryApiUrl}/${config.apiHealthEndpoint}";
      
      setState(() {
        _results[name] = _results[name]!.copyWith(
          status: "Connecting to: $healthEndpoint",
        );
      });
      
      final response = await http.get(Uri.parse(healthEndpoint))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _results[name] = _results[name]!.copyWith(
            status: "Connection successful!",
            isConnected: true,
            response: const JsonEncoder.withIndent("  ").convert(data),
          );
        });
      } else {
        setState(() {
          _results[name] = _results[name]!.copyWith(
            status: "Connection failed with status: ${response.statusCode}",
            response: response.body,
          );
        });
      }
    } catch (e) {
      // Try fallback if available
      if (config.fallbackApiUrl != null) {
        try {
          final scheme = config.useSecureConnections ? "https" : "http";
          final fallbackHealthEndpoint = "$scheme://${config.fallbackApiUrl}/${config.apiHealthEndpoint}";
          
          setState(() {
            _results[name] = _results[name]!.copyWith(
              status: "Trying fallback: $fallbackHealthEndpoint",
            );
          });
          
          final fallbackResponse = await http.get(Uri.parse(fallbackHealthEndpoint))
              .timeout(const Duration(seconds: 10));
          
          if (fallbackResponse.statusCode == 200) {
            final data = json.decode(fallbackResponse.body);
            setState(() {
              _results[name] = _results[name]!.copyWith(
                status: "Fallback connection successful!",
                isConnected: true,
                usedFallback: true,
                response: const JsonEncoder.withIndent("  ").convert(data),
              );
            });
            return;
          }
        } catch (fallbackError) {
          // Both primary and fallback failed
        }
      }
      
      setState(() {
        _results[name] = _results[name]!.copyWith(
          status: "Connection error: $e",
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fedha Connection Test"),
      ),
      body: _isLoading && _results.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Testing all connection configurations",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ..._results.entries.map((entry) => _buildConnectionCard(entry.key, entry.value)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runAllTests,
                    icon: const Icon(Icons.refresh),
                    label: Text(_isLoading ? "Testing..." : "Test All Connections Again"),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildConnectionCard(String name, ConnectionTestResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isConnected ? Icons.check_circle : Icons.error,
                  color: result.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        result.isConnected
                            ? result.usedFallback
                                ? "Connected via fallback URL"
                                : "Connected"
                            : "Not connected",
                        style: TextStyle(
                          color: result.isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow("Status", result.status),
            _buildInfoRow("API URL", result.apiUrl),
            _buildInfoRow("Fallback URL", result.fallbackUrl),
            _buildInfoRow("Secure Connection", result.useSecureConnections ? "Yes (HTTPS)" : "No (HTTP)"),
            if (result.response != null && result.response!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "Response:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.response!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class ConnectionTestResult {
  final String status;
  final bool isConnected;
  final bool usedFallback;
  final String apiUrl;
  final String fallbackUrl;
  final bool useSecureConnections;
  final String? response;

  ConnectionTestResult({
    required this.status,
    required this.isConnected,
    this.usedFallback = false,
    required this.apiUrl,
    required this.fallbackUrl,
    required this.useSecureConnections,
    this.response,
  });

  ConnectionTestResult copyWith({
    String? status,
    bool? isConnected,
    bool? usedFallback,
    String? apiUrl,
    String? fallbackUrl,
    bool? useSecureConnections,
    String? response,
  }) {
    return ConnectionTestResult(
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      usedFallback: usedFallback ?? this.usedFallback,
      apiUrl: apiUrl ?? this.apiUrl,
      fallbackUrl: fallbackUrl ?? this.fallbackUrl,
      useSecureConnections: useSecureConnections ?? this.useSecureConnections,
      response: response ?? this.response,
    );
  }
}
