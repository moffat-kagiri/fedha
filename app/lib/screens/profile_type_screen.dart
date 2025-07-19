// lib/screens/profile_type_screen.dart
import 'package:fedha/models/enums.dart';
import 'package:flutter/material.dart';
import 'profile_creation_screen.dart';

class ProfileTypeScreen extends StatelessWidget {
  const ProfileTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Select Profile Type', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 40),
              _buildProfileTypeCard(
                context,
                'Business',
                Icons.business,
                Colors.blue,
                () => _navigateToLogin(context, isBusiness: true),
              ),
              const SizedBox(height: 20),
              _buildProfileTypeCard(
                context,
                'Personal',
                Icons.person,
                Colors.green,
                () => _navigateToLogin(context, isBusiness: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTypeCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 18, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, {required bool isBusiness}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ProfileCreationScreen(
              initialProfileType:
                  isBusiness ? ProfileType.business : ProfileType.personal,
            ),
      ),
    );
  }
}
