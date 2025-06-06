// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/enhanced_auth_service.dart';
import '../models/enhanced_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<EnhancedAuthService>(context);
    final currentProfile = authService.currentProfile;

    if (currentProfile == null) {
      return const Scaffold(
        body: Center(child: Text('No profile found. Please sign in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Profile Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Name
                    if (currentProfile.name != null &&
                        currentProfile.name!.isNotEmpty)
                      Text(
                        currentProfile.name!,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // User Email
                    if (currentProfile.email != null &&
                        currentProfile.email!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            currentProfile.email!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // User ID (Emphasized)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fingerprint,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'User ID: ',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            currentProfile.userId,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Profile Type
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Type: ${currentProfile.type.toString().split('.').last.toUpperCase()}',
                          style: TextStyle(
                            color:
                                currentProfile.type == ProfileType.business
                                    ? Colors.blue
                                    : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Security Section
            const Text(
              'SECURITY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change PIN'),
              onTap: () => _showChangePinDialog(context),
            ),
            const Divider(),

            // Support Section
            const Text(
              'SUPPORT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Contact Support'),
              onTap: () => _contactSupport(context),
            ),
            const Divider(),

            // Logout Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                ),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Change PIN'),
            content: const Text(
              'This feature will be available in the next update.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Contact Support'),
            content: const Text(
              'Email: support@fedha.app\nPhone: +1 (555) 123-4567',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _logout(BuildContext context) async {
    final authService = Provider.of<EnhancedAuthService>(
      context,
      listen: false,
    );
    await authService.logout();

    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/signin', (route) => false);
    }
  }
}
