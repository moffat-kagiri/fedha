// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../models/enhanced_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final currentProfile = authService.currentProfile;

    if (currentProfile == null) {
      return const Scaffold(
        body: Center(child: Text('No profile found. Please sign in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF007A39), Color(0xFF005A2B)],
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Profile Picture
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showEditProfilePictureDialog(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Color(0xFF007A39),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // User Name
                    if (currentProfile.name != null &&
                        currentProfile.name!.isNotEmpty)
                      Text(
                        currentProfile.name!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Email
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.email,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentProfile.email ?? 'No email set',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Profile Type
                    Chip(
                      label: Text(
                        currentProfile.type
                            .toString()
                            .split('.')
                            .last
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF007A39),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Personal Information Section
            _buildSectionHeader('Personal Information'),
            Card(
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.person_outline,
                    title: 'Edit Name',
                    subtitle: currentProfile.name ?? 'Not set',
                    onTap: () => _showEditNameDialog(context, currentProfile),
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.email_outlined,
                    title: 'Edit Email',
                    subtitle: currentProfile.email ?? 'Not set',
                    onTap: () => _showEditEmailDialog(context, currentProfile),
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.phone_outlined,
                    title: 'Contact Number',
                    subtitle: 'Add your phone number',
                    onTap: () => _showEditPhoneDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionHeader('App Settings'),
            Card(
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: themeService.getThemeModeDisplayName(),
                    trailing: Switch(
                      value: themeService.themeMode == ThemeMode.dark,
                      onChanged: (value) async {
                        if (value) {
                          await themeService.setThemeMode(ThemeMode.dark);
                        } else {
                          await themeService.setThemeMode(ThemeMode.light);
                        }
                        _showThemeChangeDialog(context, value);
                      },
                      activeColor: const Color(0xFF007A39),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English (Kenya)',
                    onTap: () => _showLanguageDialog(context),
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.currency_exchange_outlined,
                    title: 'Currency',
                    subtitle: 'Kenyan Shilling (Ksh)',
                    onTap: () => _showCurrencyDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security Section
            _buildSectionHeader('Security'),
            Card(
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.fingerprint,
                    title: 'Biometric Login',
                    subtitle: 'Use fingerprint or face ID',
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        _showBiometricDialog(context);
                      },
                      activeColor: const Color(0xFF007A39),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Support Section
            _buildSectionHeader('Support & About'),
            Card(
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help with your account',
                    onTap: () => _contactSupport(context),
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.info_outline,
                    title: 'About Fedha',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAboutDialog(context),
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                  onPressed: () => _logout(context),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF007A39).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF007A39), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Dialog Methods
  void _showEditProfilePictureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Profile Picture'),
            content: const Text(
              'Profile picture functionality will be available in the next update.\n\nYou will be able to:\n• Take a photo with camera\n• Choose from gallery\n• Use default avatars',
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

  void _showEditNameDialog(BuildContext context, EnhancedProfile profile) {
    final nameController = TextEditingController(text: profile.name);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Name'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name cannot be empty')),
                    );
                    return;
                  }

                  try {
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final success = await authService.updateProfileName(
                      newName,
                    );

                    if (success) {
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to update name. Please try again.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating name: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showEditEmailDialog(BuildContext context, EnhancedProfile profile) {
    final emailController = TextEditingController(text: profile.email);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                const Text(
                  'We\'ll send a verification email to confirm the change.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newEmail = emailController.text.trim();
                  if (newEmail.isEmpty || !newEmail.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid email address'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Show loading
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => const AlertDialog(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Updating email...'),
                            ],
                          ),
                        ),
                  );

                  try {
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    await authService.updateProfileEmail(newEmail);

                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update email: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showEditPhoneDialog(BuildContext context) {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Contact Number'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixText: '+254 ',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                const Text(
                  'We may use this for account security and SMS notifications.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Phone number management will be added in a future update!',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showThemeChangeDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Theme Changed'),
            content: Text(
              'Switched to ${isDark ? 'Dark' : 'Light'} mode.\n\nTheme has been applied successfully!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  // Offer to switch between Dark/Light/System modes
                  Navigator.pop(context);
                  _showThemeModeSelector(context);
                },
                child: const Text('More Options'),
              ),
            ],
          ),
    );
  }

  void _showThemeModeSelector(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Theme Mode'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_auto),
                  title: const Text('System Default'),
                  subtitle: const Text('Follow device settings'),
                  onTap: () async {
                    await themeService.setThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Light Mode'),
                  subtitle: const Text('Always use light theme'),
                  onTap: () async {
                    await themeService.setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Always use dark theme'),
                  onTap: () async {
                    await themeService.setThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Language Settings'),
            content: const Text(
              'Multiple language support coming soon!\n\nAvailable languages:\n• English (Kenya) - Current\n• Swahili - Coming Soon\n• French - Coming Soon',
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

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Currency Settings'),
            content: const Text(
              'Multi-currency support coming soon!\n\nSupported currencies:\n• Kenyan Shilling (Ksh) - Current\n• US Dollar (USD) - Coming Soon\n• Euro (EUR) - Coming Soon\n• British Pound (GBP) - Coming Soon',
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

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }

  void _showBiometricDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Biometric Authentication'),
            content: const Text(
              'Biometric login will be available in the next update.\n\nSupported methods:\n• Fingerprint\n• Face ID\n• Voice Recognition',
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
          (context) => AlertDialog(
            title: const Text('Contact Support'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get help with your Fedha account:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.email, color: Color(0xFF007A39)),
                    SizedBox(width: 8),
                    Text('support@fedha.app'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, color: Color(0xFF007A39)),
                    SizedBox(width: 8),
                    Text('+254 700 123 456'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Color(0xFF007A39)),
                    SizedBox(width: 8),
                    Text('Mon-Fri, 8AM-6PM EAT'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement direct email/call functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening email client...')),
                  );
                },
                child: const Text('Send Email'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About Fedha'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: Color(0xFF007A39),
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fedha',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007A39),
                          ),
                        ),
                        Text('Version 1.0.0'),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Your intelligent financial companion for managing money, tracking expenses, and achieving financial goals.',
                ),
                SizedBox(height: 12),
                Text(
                  'Built for the Kenyan market with SMS transaction ingestion, offline capabilities, and smart financial insights.',
                ),
              ],
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

  void _showPrivacyPolicy(BuildContext context) async {
    // Try to load the privacy policy from assets or show fallback
    String privacyContent = '''
# Privacy Policy for Fedha

## Data Protection
• We protect your financial data with bank-level encryption
• SMS data is processed locally on your device
• Personal information is never shared without consent

## Data Collection
• Transaction data for financial insights
• Usage analytics to improve the app
• Optional location data for merchant detection

## Your Rights
• Access your data anytime
• Request data deletion
• Opt out of data collection

## SMS Processing
• SMS reading happens entirely on your device
• No SMS content leaves your device
• You control which messages are processed

## Contact Us
For questions about this Privacy Policy, contact us through the in-app Help & Support section.

Last updated: June 22, 2025
''';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Privacy Policy'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      privacyContent,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/signin', (route) => false);
      }
    }
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool showOldPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;
  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: oldPasswordController,
            decoration: InputDecoration(
              labelText: 'Current Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  showOldPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    showOldPassword = !showOldPassword;
                  });
                },
              ),
            ),
            obscureText: !showOldPassword,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: newPasswordController,
            decoration: InputDecoration(
              labelText: 'New Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  showNewPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    showNewPassword = !showNewPassword;
                  });
                },
              ),
              helperText: 'Minimum 6 characters',
            ),
            obscureText: !showNewPassword,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    showConfirmPassword = !showConfirmPassword;
                  });
                },
              ),
            ),
            obscureText: !showConfirmPassword,
            enabled: !isLoading,
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : () => _changePasswordHandler(),
          child: const Text('Update Password'),
        ),
      ],
    );
  }

  Future<void> _changePasswordHandler() async {
    final currentPassword = oldPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Validation
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirmation do not match'),
        ),
      );
      return;
    }

    if (currentPassword == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be different from current password'),
        ),
      );
      return;
    }

    // Check password strength
    if (!_isPasswordStrong(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password should contain letters, numbers, and be at least 6 characters',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.changePassword(
        currentPassword,
        newPassword,
      );
      if (success) {
        if (mounted) {
          Navigator.pop(context);

          // Show success message and prompt for re-login
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  title: const Text('Password Changed Successfully'),
                  content: const Text(
                    'Your password has been updated successfully.\n\nFor security reasons, please sign in again with your new password.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _performReLogin(context);
                      },
                      child: const Text('Sign In Again'),
                    ),
                  ],
                ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to change password. Please check your current password.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isPasswordStrong(String password) {
    // Basic password strength check
    if (password.length < 6) return false;
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));

    return hasLetter && hasNumber;
  }

  void _performReLogin(BuildContext context) {
    // Sign out and navigate to login screen
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.logout();

    // Navigate to login screen (assuming it's the root route)
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
