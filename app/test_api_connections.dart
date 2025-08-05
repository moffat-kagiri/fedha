import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Connection Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ConnectionTester(),
    );
  }
}

class ConnectionTester extends StatefulWidget {
  const ConnectionTester({super.key});

  @override
  State<ConnectionTester> createState() => _ConnectionTesterState();
}

class _ConnectionTesterState extends State<ConnectionTester> {
  bool _isLoading = false;
  String _results = '';
  
  final localIp = '192.168.100.6'; // Your confirmed IP from ipconfig
  final cloudflare = 'place-jd-telecom-hi.trycloudflare.com';
  
  Future<void> _testConnection(String url) async {
    setState(() {
      _results += '\nTesting $url...';
    });
    
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      stopwatch.stop();
      
      setState(() {
        _results += '\n✅ Success! Status: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)';
        _results += '\nResponse: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...';
      });
    } on SocketException {
      setState(() {
        _results += '\n❌ Connection refused';
      });
    } on TimeoutException {
      setState(() {
        _results += '\n❌ Connection timeout';
      });
    } catch (e) {
      setState(() {
        _results += '\n❌ Error: ${e.toString()}';
      });
    }
    
    setState(() {
      _results += '\n';
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _results = 'Starting tests...';
    });
    
    // Test localhost
    await _testConnection('http://localhost:8000/api/health/');
    
    // Test 127.0.0.1
    await _testConnection('http://127.0.0.1:8000/api/health/');
    
    // Test local IP
    await _testConnection('http://$localIp:8000/api/health/');
    
    // Test Cloudflare
    await _testConnection('https://$cloudflare/api/health/');
    
    setState(() {
      _isLoading = false;
      _results += '\nTests completed!';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('API Connection Tester'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fedha Backend Connection Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _runTests,
              child: _isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Test All Connections'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Results:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _results.isEmpty ? 'No results yet. Click "Test All Connections".' : _results,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
