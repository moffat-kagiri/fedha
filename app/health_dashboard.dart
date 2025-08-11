import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Health Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HealthDashboard(),
    );
  }
}

class ConnectionOption {
  final String name;
  final String baseUrl;
  final String healthEndpoint;
  bool isHealthy = false;
  String responseTime = '';
  String statusMessage = 'Not tested';
  String fullResponse = '';

  ConnectionOption({
    required this.name,
    required this.baseUrl,
    this.healthEndpoint = '/api/health/',
  });

  String get fullUrl => '$baseUrl$healthEndpoint';
  
  Future<void> checkHealth() async {
    statusMessage = 'Testing...';
    isHealthy = false;
    responseTime = '';
    fullResponse = '';
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      responseTime = '${stopwatch.elapsedMilliseconds}ms';
      
      if (response.statusCode == 200) {
        isHealthy = true;
        statusMessage = 'Healthy';
        try {
          final jsonResponse = jsonDecode(response.body);
          fullResponse = const JsonEncoder.withIndent('  ').convert(jsonResponse);
        } catch (e) {
          fullResponse = response.body;
        }
      } else {
        statusMessage = 'Unhealthy (${response.statusCode})';
        fullResponse = response.body;
      }
    } on SocketException {
      statusMessage = 'Connection refused';
    } on TimeoutException {
      statusMessage = 'Connection timeout';
    } catch (e) {
      statusMessage = 'Error: ${e.toString()}';
    }
  }
}

class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final List<ConnectionOption> connections = [
    ConnectionOption(
      name: 'Local Direct',
      baseUrl: 'http://localhost:8000',
    ),
    ConnectionOption(
      name: 'Local Network',
      baseUrl: 'http://192.168.100.6:8000',
    ),
    ConnectionOption(
      name: 'Cloudflare Tunnel',
      baseUrl: 'https://lake-consistently-affects-applications.trycloudflare.com', // Cloudflare Tunnel
    ),
    // Add any other connection options here
  ];

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('API Health Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: isLoading 
                      ? null 
                      : () async {
                          setState(() {
                            isLoading = true;
                          });
                          
                          for (var connection in connections) {
                            setState(() {
                              connection.statusMessage = 'Testing...';
                            });
                            await connection.checkHealth();
                            setState(() {});
                          }
                          
                          setState(() {
                            isLoading = false;
                          });
                        },
                  child: Text(isLoading ? 'Testing...' : 'Test All Connections'),
                ),
                const SizedBox(width: 16),
                if (isLoading)
                  const CircularProgressIndicator(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: connections.length,
                itemBuilder: (context, index) {
                  final connection = connections[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(
                        connection.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(connection.fullUrl),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (connection.responseTime.isNotEmpty)
                            Chip(
                              label: Text(connection.responseTime),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(connection.statusMessage),
                            backgroundColor: connection.isHealthy
                                ? Colors.green.shade100
                                : connection.statusMessage == 'Testing...'
                                    ? Colors.orange.shade100
                                    : Colors.red.shade100,
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Response:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SelectableText(
                                  connection.fullResponse.isNotEmpty
                                      ? connection.fullResponse
                                      : 'No response data',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() {
                                    connection.statusMessage = 'Testing...';
                                  });
                                  await connection.checkHealth();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retest Connection'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
