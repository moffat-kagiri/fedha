import 'package:flutter/material.dart';

import 'offline_profile_setup_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LocalProfileSetupScreen(emphasizeSkip: true);
  }
}
