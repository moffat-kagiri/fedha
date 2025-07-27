// Test file for creating sample profiles in the Fedha app
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'lib/models/profile.dart';
import 'lib/models/enums.dart';
import 'lib/services/auth_service.dart';
import 'lib/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging
  AppLogger.init();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register the adapters
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(ProfileTypeAdapter());
  
  // Open the profiles box
  await Hive.openBox<Profile>('profiles');
  
  final authService = AuthService();
  await authService.initialize();
  
  // Create personal profile
  final personalProfile = await createPersonalTestProfile(authService);
  print('Personal profile created: ${personalProfile ? "Success" : "Failed"}');
  
  // Create business profile
  final businessProfile = await createBusinessTestProfile(authService);
  print('Business profile created: ${businessProfile ? "Success" : "Failed"}');
  
  // Print all profiles
  await printAllProfiles();
}

Future<bool> createPersonalTestProfile(AuthService authService) async {
  final profileData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'pin': '1234',
    'phoneNumber': '+254712345678',
    'baseCurrency': 'KES',
    'timezone': 'Africa/Nairobi',
    'type': ProfileType.personal.index,
    'preferences': {
      'darkMode': false,
      'notifications': true,
      'biometricAuth': true,
      'language': 'en',
    }
  };
  
  return await authService.createProfile(profileData);
}

Future<bool> createBusinessTestProfile(AuthService authService) async {
  final profileData = {
    'name': 'Acme Corporation',
    'email': 'business@acme.com',
    'pin': '5678',
    'phoneNumber': '+254787654321',
    'baseCurrency': 'KES',
    'timezone': 'Africa/Nairobi',
    'type': ProfileType.business.index,
    'preferences': {
      'darkMode': true,
      'notifications': true,
      'biometricAuth': false,
      'language': 'en',
      'businessType': 'Limited Company',
      'businessId': 'BUS-12345',
      'taxId': 'TAX-98765',
    }
  };
  
  return await authService.createProfile(profileData);
}

Future<void> printAllProfiles() async {
  final profilesBox = Hive.box<Profile>('profiles');
  
  print('\n===== EXISTING PROFILES =====');
  for (var i = 0; i < profilesBox.length; i++) {
    final profile = profilesBox.getAt(i);
    print('\nProfile ${i + 1}:');
    print('ID: ${profile?.id}');
    print('Name: ${profile?.name}');
    print('Email: ${profile?.email}');
    print('Type: ${profile?.type.toString()}');
    print('Created: ${profile?.createdAt}');
    print('Base Currency: ${profile?.baseCurrency}');
    print('------------------------');
  }
}

// Alternative direct approach without using AuthService
Future<bool> createProfileDirectly(Map<String, dynamic> profileData) async {
  try {
    final profilesBox = Hive.box<Profile>('profiles');
    final uuid = Uuid();
    
    // Generate unique ID
    final userId = uuid.v4();
    
    final now = DateTime.now();
    
    // Create profile object
    final profile = Profile(
      id: userId,
      name: profileData['name'],
      email: profileData['email'],
      type: ProfileType.values[profileData['type'] as int],
      pin: profileData['pin'],
      baseCurrency: profileData['baseCurrency'] ?? 'KES',
      timezone: profileData['timezone'] ?? 'Africa/Nairobi',
      createdAt: now,
      isActive: true,
      lastLogin: now,
      preferences: profileData['preferences'],
      phoneNumber: profileData['phoneNumber'],
      displayName: profileData['displayName'] ?? profileData['name'],
    );
    
    // Save to Hive
    await profilesBox.put(userId, profile);
    
    print('Successfully created profile directly: ${profile.name}');
    return true;
  } catch (e) {
    print('Failed to create profile directly: $e');
    return false;
  }
}
