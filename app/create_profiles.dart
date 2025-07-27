// A command-line tool to create test profiles in the Fedha app
// Run this with `dart run create_profiles.dart`

import 'dart:io';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

// Define Profile model inline for this script
class Profile {
  final String id;
  final String name;
  final String email;
  final int type; // 0 = personal, 1 = business
  final String pin;
  final String baseCurrency;
  final String timezone;
  final DateTime createdAt;
  final bool isActive;
  final DateTime lastLogin;
  final String? sessionToken;
  final Map<String, dynamic>? preferences;
  final String? phoneNumber;
  final String? displayName;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.pin,
    required this.baseCurrency,
    required this.timezone,
    required this.createdAt,
    required this.isActive,
    required this.lastLogin,
    this.sessionToken,
    this.preferences,
    this.phoneNumber,
    this.displayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type,
      'pin': pin,
      'baseCurrency': baseCurrency,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'lastLogin': lastLogin.toIso8601String(),
      'sessionToken': sessionToken,
      'preferences': preferences,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
    };
  }
}

Future<void> main() async {
  print('===== FEDHA TEST PROFILES CREATOR =====');
  print('Creating test profiles for the Fedha app...');
  
  // Get app document directory
  final appDocDir = Directory('app_data');
  if (!appDocDir.existsSync()) {
    appDocDir.createSync();
  }
  
  // Initialize Hive
  Hive.init(appDocDir.path);
  
  // Create box for storing profiles
  final profilesBox = await Hive.openBox('profiles');
  
  // Create personal profile
  final personalResult = await createPersonalProfile(profilesBox);
  print('Personal profile created: ${personalResult ? "Success" : "Failed"}');
  
  // Create business profile
  final businessResult = await createBusinessProfile(profilesBox);
  print('Business profile created: ${businessResult ? "Success" : "Failed"}');
  
  // List all profiles
  print('\n===== EXISTING PROFILES =====');
  for (var i = 0; i < profilesBox.length; i++) {
    final profile = profilesBox.getAt(i);
    print('\nProfile ${i + 1}:');
    print('ID: ${profile['id']}');
    print('Name: ${profile['name']}');
    print('Email: ${profile['email']}');
    print('Type: ${profile['type'] == 0 ? 'personal' : 'business'}');
    print('Created: ${profile['createdAt']}');
    print('Base Currency: ${profile['baseCurrency']}');
    print('------------------------');
  }
  
  // Close Hive
  await Hive.close();
  print('\nTest profiles created successfully!');
  
  // Write a simple file that the app can read
  File('app_data/test_profiles_created.txt').writeAsStringSync(
    'Test profiles created: ${DateTime.now().toIso8601String()}'
  );
}

Future<bool> createPersonalProfile(Box profilesBox) async {
  try {
    final uuid = Uuid();
    final userId = uuid.v4();
    final sessionToken = uuid.v4();
    final now = DateTime.now();
    
    final profile = Profile(
      id: userId,
      name: 'John Doe',
      email: 'john.doe@example.com',
      type: 0, // personal
      pin: '1234',
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
    
    await profilesBox.put(userId, profile.toJson());
    print("Created personal profile with ID: $userId");
    
    // Write to a file for the app to read later
    final file = File('app_data/personal_profile.txt');
    file.writeAsStringSync(userId);
    
    return true;
  } catch (e) {
    print("Error creating personal profile: $e");
    return false;
  }
}

Future<bool> createBusinessProfile(Box profilesBox) async {
  try {
    final uuid = Uuid();
    final userId = uuid.v4();
    final sessionToken = uuid.v4();
    final now = DateTime.now();
    
    final profile = Profile(
      id: userId,
      name: 'Acme Corporation',
      email: 'business@acme.com',
      type: 1, // business
      pin: '5678',
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
    
    await profilesBox.put(userId, profile.toJson());
    print("Created business profile with ID: $userId");
    
    // Write to a file for the app to read later
    final file = File('app_data/business_profile.txt');
    file.writeAsStringSync(userId);
    
    return true;
  } catch (e) {
    print("Error creating business profile: $e");
    return false;
  }
}
