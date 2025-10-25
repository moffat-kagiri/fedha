import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

import '../models/profile.dart';
import '../models/enums.dart';
import '../utils/logger.dart';
import '../services/auth_service.dart';

/// A utility class for creating test profiles in the Fedha app.
/// This can be called from anywhere in the app during development.
class TestProfileCreator {
  static final Logger _logger = AppLogger.getLogger('TestProfileCreator');
  static const uuid = Uuid();
  
  /// Create a test personal profile
  static Future<String?> createPersonalProfile() async {
    try {
      final userId = uuid.v4();
      final sessionToken = uuid.v4();
      final now = DateTime.now();
      
      final profile = Profile(
        id: userId,
        name: 'John Doe',
        email: 'john.doe@example.com',
        type: ProfileType.personal,
        password: 'Password123!',
        baseCurrency: 'KES',
        timezone: 'Africa/Nairobi',
        createdAt: now,
        isActive: true,
        lastLogin: now,
        sessionToken: sessionToken,
        preferences: {
          'darkMode': false,
          'notifications': true,
          'biometricAuth': true,
          'language': 'en',
        },
        phoneNumber: '+254712345678',
      );
      
      // Use AuthService instance
      final authService = AuthService.instance;
      await authService.signup(
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        password: 'Password123!',
        phone: '+254712345678',
      );
      
      _logger.info("Created personal profile with ID: $userId");
      debugPrint("Created personal profile: ${profile.name} (${profile.email})");
      
      return userId;
    } catch (e) {
      _logger.severe("Error creating personal profile: $e");
      debugPrint("Error creating personal profile: $e");
      return null;
    }
  }
  
  /// Create a test business profile
  static Future<String?> createBusinessProfile() async {
    try {
      final userId = uuid.v4();
      final sessionToken = uuid.v4();
      final now = DateTime.now();
      
      final profile = Profile(
        id: userId,
        name: 'Acme Corporation',
        email: 'business@acme.com',
        type: ProfileType.business,
        password: 'Password123!',
        baseCurrency: 'KES',
        timezone: 'Africa/Nairobi',
        createdAt: now,
        isActive: true,
        lastLogin: now,
        sessionToken: sessionToken,
        preferences: {
          'darkMode': true,
          'notifications': true,
          'biometricAuth': false,
          'language': 'en',
          'businessType': 'Limited Company',
          'businessId': 'BUS-12345',
          'taxId': 'TAX-98765',
        },
        phoneNumber: '+254787654321',
        displayName: 'Acme Corp',
      );
      
      // Use AuthService instance
      final authService = AuthService.instance;
      await authService.signup(
        firstName: 'Acme',
        lastName: 'Corporation',
        email: 'business@acme.com',
        password: 'Password123!',
        phone: '+254787654321',
      );
      
      _logger.info("Created business profile with ID: $userId");
      debugPrint("Created business profile: ${profile.name} (${profile.email})");
      
      return userId;
    } catch (e) {
      _logger.severe("Error creating business profile: $e");
      debugPrint("Error creating business profile: $e");
      return null;
    }
  }
  
  /// Create both personal and business profiles
  static Future<Map<String, String?>> createBothProfiles() async {
    final personalId = await createPersonalProfile();
    final businessId = await createBusinessProfile();
    
    return {
      'personal': personalId,
      'business': businessId,
    };
  }
  
  /// Show a list of all existing profiles
  static Future<List<Profile>> listAllProfiles() async {
    // Since we no longer have direct box access, we can only access the current profile
    final profiles = <Profile>[];
    
    final authService = AuthService.instance;
    await authService.initialize(); // Ensure profile is loaded
    
    if (authService.currentProfile != null) {
      profiles.add(authService.currentProfile!);
      debugPrint("Current profile: ${authService.currentProfile!.name} (${authService.currentProfile!.email}) - Type: ${authService.currentProfile!.type}");
    } else {
      debugPrint("No profiles found");
    }
    
    return profiles;
  }
  
  /// Show a dialog with the created profiles
  static Future<void> showProfilesCreatedDialog(BuildContext context) async {
    await createBothProfiles();
    final profiles = await listAllProfiles();
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Profiles Created'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ListTile(
                  title: Text(profile.name),
                  subtitle: Text(profile.email ?? 'no-email'),
                  trailing: Text(profile.type.toString().split('.').last),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}