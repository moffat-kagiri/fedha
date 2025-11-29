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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Icon(
                  Icons.security_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'App Permissions',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Fedha needs the following permissions to provide you with the best experience:',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
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
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isRequestingPermissions
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Grant Permissions'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isRequestingPermissions ? null : () async {
                  // Mark prompt as shown and skip requesting permissions
                  await _permissionsService.markPermissionsPromptShown();
                  widget.onPermissionsSet(context);
                },
                child: Text(
                  'Skip for Now',
                  style: TextStyle(
                    color: colorScheme.primary.withOpacity(0.8),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final items = <Widget>[];
    
    // SMS Permission (Android only)
    if (Platform.isAndroid) {
      items.add(
        _PermissionItem(
          icon: Icons.sms_rounded,
          title: 'SMS',
          description: 'To automatically detect transactions from SMS notifications',
          isGranted: _permissionStatus[Permission.sms] ?? false,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      );
    }
    
    // Notifications
    items.add(
      _PermissionItem(
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        description: 'For important alerts about your finances',
        isGranted: _permissionStatus[Permission.notification] ?? false,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
    );
    
    // Storage
    items.add(
      _PermissionItem(
        icon: Icons.folder_rounded,
        title: 'Storage',
        description: 'To save and access your financial data and receipts',
        isGranted: _permissionStatus[Permission.storage] ?? false,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
    );
    
    // Camera
    items.add(
      _PermissionItem(
        icon: Icons.camera_alt_rounded,
        title: 'Camera',
        description: 'To scan receipts and documents',
        isGranted: _permissionStatus[Permission.camera] ?? false,
        colorScheme: colorScheme,
        textTheme: textTheme,
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
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  
  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.colorScheme,
    required this.textTheme,
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
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isGranted ? colorScheme.primary : colorScheme.outline,
          ),
        ],
      ),
    );
  }
}