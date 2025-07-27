// A standalone tool to create test profiles in the Fedha app
// Run this script with `flutter run test_profiles_tool.dart`

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fedha/models/profile.dart';
import 'package:fedha/models/enums.dart';
import 'package:fedha/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  AppLogger.init();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  try {
    Hive.registerAdapter(ProfileAdapter());
    Hive.registerAdapter(ProfileTypeAdapter());
  } catch (e) {
    print('Adapters might already be registered: $e');
    // Continue execution
  }
  
  // Open profiles box
  final profilesBox = await Hive.openBox<Profile>('profiles');
  
  print('===== CREATING TEST PROFILES =====');
  
  // Create personal profile
  final personalResult = await createPersonalProfile(profilesBox);
  print('Personal profile created: ${personalResult ? "Success" : "Failed"}');
  
  // Create business profile
  final businessResult = await createBusinessProfile(profilesBox);
  print('Business profile created: ${businessResult ? "Success" : "Failed"}');
  
  // Print all profiles
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
  
  // Close Hive
  await Hive.close();
  
  // Show UI to confirm profiles were created
  runApp(const EmptyApp());
}

Future<bool> createPersonalProfile(Box<Profile> profilesBox) async {
  try {
    final uuid = const Uuid();
    final userId = uuid.v4();
    final sessionToken = uuid.v4();
    
    final profile = Profile(
      id: userId,
      name: 'John Doe',
      email: 'john.doe@example.com',
      type: ProfileType.personal,
      pin: '1234',
      baseCurrency: 'KES',
      timezone: 'Africa/Nairobi',
      createdAt: DateTime.now(),
      isActive: true,
      lastLogin: DateTime.now(),
      sessionToken: sessionToken,
      preferences: {
        'darkMode': false,
        'notifications': true,
        'biometricAuth': true,
        'language': 'en',
      },
      phoneNumber: '+254712345678',
    );
    
    await profilesBox.put(userId, profile);
    print("Created personal profile with ID: $userId");
    
    return true;
  } catch (e) {
    print("Error creating personal profile: $e");
    return false;
  }
}

Future<bool> createBusinessProfile(Box<Profile> profilesBox) async {
  try {
    final uuid = const Uuid();
    final userId = uuid.v4();
    final sessionToken = uuid.v4();
    
    final profile = Profile(
      id: userId,
      name: 'Acme Corporation',
      email: 'business@acme.com',
      type: ProfileType.business,
      pin: '5678',
      baseCurrency: 'KES',
      timezone: 'Africa/Nairobi',
      createdAt: DateTime.now(),
      isActive: true,
      lastLogin: DateTime.now(),
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
    
    await profilesBox.put(userId, profile);
    print("Created business profile with ID: $userId");
    
    return true;
  } catch (e) {
    print("Error creating business profile: $e");
    return false;
  }
}

// Exit application with success code after execution
class EmptyApp extends StatelessWidget {
  const EmptyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Test profiles created successfully!'),
              Text('You can now close this window.'),
            ],
          ),
        ),
      ),
    );
  }
}
