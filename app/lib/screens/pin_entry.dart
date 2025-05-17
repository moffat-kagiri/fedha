// ignore_for_file: use_build_context_synchronously

import 'package:fedha/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:fedha/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';

class PinEntryScreen extends StatelessWidget {
  final bool isNewProfile;
  final String profileId; // For existing profiles

  const PinEntryScreen({super.key, required this.isNewProfile, this.profileId = ''});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final TextEditingController pinController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text(isNewProfile ? 'Set PIN' : 'Enter PIN')),
      body: Column(
        children: [
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
          ),
          ElevatedButton(
            onPressed: () async {
              if (isNewProfile) {
                await authService.createProfile(
                  isBusiness: true, // Or from previous screen
                  pin: pinController.text,
                );
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => DashboardScreen(),
                ));
              } else {
                final success = await authService.login(profileId, pinController.text);
                if (success) {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => DashboardScreen(),
                  ));
                }
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}