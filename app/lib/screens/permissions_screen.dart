import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../services/permissions_service.dart';

class PermissionsScreen extends StatefulWidget {
  final void Function(BuildContext) onPermissionsSet;
  
  const PermissionsScreen({
    Key? key,
    required this.onPermissionsSet,
  }) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionsService _permissionsService = PermissionsService.instance;
  bool _isRequestingPermissions = false;
  
  Map<Permission, bool> _permissionStatus = {};
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    final Map<Permission, bool> status = {};
    
    // Check each permission
    status[Permission.notification] = await Permission.notification.isGranted;
    
    if (Platform.isAndroid) {
      status[Permission.sms] = await Permission.sms.isGranted;
    }
    
    status[Permission.storage] = await Permission.storage.isGranted;
    status[Permission.camera] = await Permission.camera.isGranted;
    
    if (mounted) {
      setState(() {
        _permissionStatus = status;
      });
    }
  }
  
  Future<void> _requestPermissions() async {
    if (_isRequestingPermissions) return;
    
    setState(() {
      _isRequestingPermissions = true;
    });
    
    try {
      // Request all permissions
      await _permissionsService.requestAllPermissions();
      
      // Update status
      await _checkPermissions();
      
  // Mark as done
  widget.onPermissionsSet(context);
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermissions = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Icon(
                  Icons.security,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'App Permissions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Fedha needs the following permissions to provide you with the best experience:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Permissions list
              ..._buildPermissionItems(),
              
              const Spacer(),
              ElevatedButton(
                onPressed: _isRequestingPermissions ? null : _requestPermissions,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRequestingPermissions
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Grant Permissions'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  widget.onPermissionsSet(context);
                },
                child: Text(
                  'Skip for Now',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildPermissionItems() {
    final items = <Widget>[];
    
    // SMS Permission (Android only)
    if (Platform.isAndroid) {
      items.add(
        _PermissionItem(
          icon: Icons.sms,
          title: 'SMS',
          description: 'To automatically detect transactions from SMS notifications',
          isGranted: _permissionStatus[Permission.sms] ?? false,
        ),
      );
    }
    
    // Notifications
    items.add(
      _PermissionItem(
        icon: Icons.notifications,
        title: 'Notifications',
        description: 'For important alerts about your finances',
        isGranted: _permissionStatus[Permission.notification] ?? false,
      ),
    );
    
    // Storage
    items.add(
      _PermissionItem(
        icon: Icons.folder,
        title: 'Storage',
        description: 'To save and access your financial data and receipts',
        isGranted: _permissionStatus[Permission.storage] ?? false,
      ),
    );
    
    // Camera
    items.add(
      _PermissionItem(
        icon: Icons.camera_alt,
        title: 'Camera',
        description: 'To scan receipts and documents',
        isGranted: _permissionStatus[Permission.camera] ?? false,
      ),
    );
    
    return items;
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isGranted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isGranted ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
}
