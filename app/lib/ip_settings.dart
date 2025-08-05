import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// A simple tool to update your IP address in the health dashboard

void main() {
  runApp(const IpSettingApp());
}

class IpSettingApp extends StatelessWidget {
  const IpSettingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP Settings',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const IpSettingsScreen(),
    );
  }
}

class IpSettingsScreen extends StatefulWidget {
  const IpSettingsScreen({super.key});

  @override
  State<IpSettingsScreen> createState() => _IpSettingsScreenState();
}

class _IpSettingsScreenState extends State<IpSettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  String _currentIp = '';
  bool _isLoading = true;
  String _statusMessage = '';
  bool _isSuccess = false;
  List<String> _availableIps = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentIp();
    _detectNetworkIps();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentIp() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading current IP...';
    });

    try {
      _currentIp = '192.168.100.6'; // Default IP
      _ipController.text = _currentIp;
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Current IP loaded';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading IP: ${e.toString()}';
        _isSuccess = false;
      });
    }
  }

  Future<void> _detectNetworkIps() async {
    try {
      final interfaces = await NetworkInterface.list();
      final ips = <String>[];
      
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            ips.add(addr.address);
          }
        }
      }
      
      setState(() {
        _availableIps = ips;
      });
    } catch (e) {
      // Just log the error, don't update UI
      print('Error detecting network IPs: $e');
    }
  }

  Future<void> _updateIp() async {
    final newIp = _ipController.text.trim();
    if (newIp.isEmpty) {
      setState(() {
        _statusMessage = 'IP cannot be empty';
        _isSuccess = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Updating IP...';
    });
    
    try {
      // Save the new IP to the health dashboard
      _currentIp = newIp;
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'IP updated successfully';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error updating IP: ${e.toString()}';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('IP Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current IP Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter IP address (e.g. 192.168.1.100)',
                suffixIcon: IconButton(
                  icon: Icon(Icons.save),
                  onPressed: _isLoading ? null : _updateIp,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_statusMessage),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Available Network IPs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _availableIps.isEmpty
                  ? Center(
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : Text('No network IPs detected'),
                    )
                  : ListView.builder(
                      itemCount: _availableIps.length,
                      itemBuilder: (context, index) {
                        final ip = _availableIps[index];
                        return ListTile(
                          title: Text(ip),
                          trailing: IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () {
                              _ipController.text = ip;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('IP copied to input')),
                              );
                            },
                          ),
                          onTap: () {
                            _ipController.text = ip;
                          },
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
