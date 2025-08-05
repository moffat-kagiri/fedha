import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const DeviceInfoApp());
}

class DeviceInfoApp extends StatelessWidget {
  const DeviceInfoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Network Info',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DeviceInfoScreen(),
    );
  }
}

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<NetworkInterfaceInfo> _networkInfo = [];

  @override
  void initState() {
    super.initState();
    _getNetworkInfo();
  }

  Future<void> _getNetworkInfo() async {
    try {
      final interfaces = await NetworkInterface.list();
      final networkInfo = <NetworkInterfaceInfo>[];

      for (var interface in interfaces) {
        final addresses = <AddressInfo>[];
        
        for (var addr in interface.addresses) {
          addresses.add(AddressInfo(
            address: addr.address,
            type: addr.type.name,
          ));
        }
        
        networkInfo.add(NetworkInterfaceInfo(
          name: interface.name,
          index: interface.index,
          addresses: addresses,
        ));
      }
      
      setState(() {
        _networkInfo = networkInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting network information: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Device Network Info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: _networkInfo.length,
                  itemBuilder: (context, index) {
                    final interface = _networkInfo[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text('${interface.name} (Index: ${interface.index})'),
                        children: interface.addresses.map((addr) {
                          return ListTile(
                            title: Text(
                              addr.address,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            subtitle: Text('Type: ${addr.type}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                // Implement clipboard copy
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied ${addr.address} to clipboard')),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            _isLoading = true;
            _errorMessage = '';
          });
          
          await _getNetworkInfo();
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class NetworkInterfaceInfo {
  final String name;
  final int index;
  final List<AddressInfo> addresses;

  NetworkInterfaceInfo({
    required this.name,
    required this.index,
    required this.addresses,
  });
}

class AddressInfo {
  final String address;
  final String type;

  AddressInfo({
    required this.address,
    required this.type,
  });
}
