import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfileSelectorScreen extends StatelessWidget {
  const ProfileSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _createProfile(context, isBusiness: true),
              child: const Text('Create Business Profile')),
            ElevatedButton(
              onPressed: () => _createProfile(context, isBusiness: false),
              child: const Text('Create Personal Profile')),
          ],
        ),
      ),
    );
  }
  // Update the _createProfile method
void _createProfile(BuildContext context, {required bool isBusiness}) {
  final authService = Provider.of<AuthService>(context, listen: false);
  authService.generateProfileId(isBusiness: isBusiness);
  // Navigate to dashboard
}
}