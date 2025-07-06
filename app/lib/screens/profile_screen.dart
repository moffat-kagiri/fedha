// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/enhanced_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profile = authService.currentProfile;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('No profile found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile ID: ${profile.id}'),
            const SizedBox(height: 8),
            Text('Name: ${profile.name ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Email: ${profile.email ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Account Type: ${profile.type.name.capitalize()}'),
            const Divider(height: 32),
            ListTile(
              title: const Text('Currency'),
              subtitle: Text(profile.baseCurrency),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final options = ['KSh', 'USD', 'EUR', 'GBP'];
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  builder:
                      (context) => ListView(
                        children:
                            options
                                .map(
                                  (c) => ListTile(
                                    title: Text(c),
                                    onTap: () => Navigator.pop(context, c),
                                  ),
                                )
                                .toList(),
                      ),
                );
                if (selected != null) {
                  await authService.updateCurrency(selected);
                }
              },
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await authService.signOut();
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
