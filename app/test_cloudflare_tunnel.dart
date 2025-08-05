// Cloudflare Tunnel Test for Fedha App

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CloudflareTunnelTestApp());
}

class CloudflareTunnelTestApp extends StatelessWidget {
  const CloudflareTunnelTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cloudflare Tunnel Test",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TunnelTestScreen(),
    );
  }
}

class TunnelTestScreen extends StatefulWidget {
  const TunnelTestScreen({Key? key}) : super(key: key);

  @override
  _TunnelTestScreenState createState() => _TunnelTestScreenState();
}

class _TunnelTestScreenState extends State<TunnelTestScreen> {
  String _status = "Testing connection...";
  String _response = "";
  bool _isLoading = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = "Testing connection to Cloudflare tunnel...";
    });

    try {
      // Try to connect to the health endpoint
      final tunnelUrl = "place-jd-telecom-hi.trycloudflare.com";
      final healthEndpoint = "https://$tunnelUrl/api/health/";
      
      setState(() {
        _status = "Connecting to: $healthEndpoint";
      });
      
      final response = await http.get(Uri.parse(healthEndpoint))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isConnected = true;
          _status = "Connection successful!";
          _response = const JsonEncoder.withIndent("  ").convert(data);
        });
      } else {
        setState(() {
          _isConnected = false;
          _status = "Connection failed with status: ${response.statusCode}";
          _response = response.body;
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _status = "Connection error: $e";
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
        title: const Text("Cloudflare Tunnel Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: _isConnected ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected 
                              ? "Connected to Cloudflare Tunnel" 
                              : "Failed to connect to Cloudflare Tunnel",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_response.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Server Response:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(_response),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.refresh),
              label: const Text("Test Connection Again"),
            ),
          ],
        ),
      ),
    );
  }
}
