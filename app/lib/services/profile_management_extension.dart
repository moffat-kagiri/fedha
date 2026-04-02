// lib/services/profile_management_extension.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../models/profile.dart';

/// Extension to add profile management methods to AuthService
extension ProfileManagementExtension on AuthService {
  /// Update the user's profile information (offline-only mode)
  Future<bool> updateProfile({
    required Map<String, dynamic> profileData,
  }) async {
    try {
      if (currentProfile == null) {
        return false;
      }
      
      // Update the local profile data only
      final updatedProfile = currentProfile!.copyWith(
        email: profileData['email'] ?? currentProfile!.email,
        name: profileData['name'] ?? currentProfile!.name,
        phoneNumber: profileData['phoneNumber'] ?? currentProfile!.phoneNumber,
        photoUrl: profileData['photoUrl'] ?? currentProfile!.photoUrl,
        updatedAt: DateTime.now(),
      );
      
      // Save updated profile using secure storage
      await const FlutterSecureStorage().write(
        key: 'profile_${updatedProfile.id}',
        value: jsonEncode(updatedProfile.toJson()),
      );
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update profile: $e');
      }
      return false;
    }
  }
}