// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileBox = Provider.of<Box<Profile>>(context);
    final profile = profileBox.values.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile ID: ${profile.id}'),
            Text('Type: ${profile.type.toString().split('.').last}'),
            const SizedBox(height: 20),
            const Text('Settings:'),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
}
