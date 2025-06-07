import 'package:flutter/material.dart';

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
              child: const Text('Create Business Profile'),
            ),
            ElevatedButton(
              onPressed: () => _createProfile(context, isBusiness: false),
              child: const Text('Create Personal Profile'),
            ),
          ],
        ),
      ),
    );
  }
  // Navigate to profile creation screen
  void _createProfile(BuildContext context, {required bool isBusiness}) {
    Navigator.pushNamed(context, '/profile-creation', arguments: {
      'profileType': isBusiness ? 'business' : 'personal',
    });
  }
}
