// lib/services/profile_management_extension.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../models/profile.dart';

/// Extension to add profile management methods to AuthService
extension ProfileManagementExtension on AuthService {
  /// Update the user's profile information
  Future<bool> updateProfile({
    required Map<String, dynamic> profileData,
  }) async {
    try {
      if (currentProfile == null) {
        return false;
      }
      
      final userId = currentProfile!.id;
      final sessionToken = currentProfile!.sessionToken ?? '';
      
      // Update the local profile data first
      final updatedProfile = currentProfile!.copyWith(
        email: profileData['email'] ?? currentProfile!.email,
        name: profileData['name'] ?? currentProfile!.name,
        phoneNumber: profileData['phoneNumber'] ?? currentProfile!.phoneNumber,
        photoUrl: profileData['photoUrl'] ?? currentProfile!.photoUrl,
        updatedAt: DateTime.now(),
      );
      
      // Save locally
      await updateLocalProfile(updatedProfile);
      
      // Try to sync with server if online
      try {
        await ApiClient.instance.updateProfile(
          userId: userId,
          sessionToken: sessionToken,
          profileData: profileData,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync profile update: $e');
        }
        // Continue since we already updated locally
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update profile: $e');
      }
      return false;
    }
  }
  
  /// Save an updated profile to local storage only
  Future<bool> updateLocalProfile(Profile updatedProfile) async {
    try {
      await const FlutterSecureStorage().write(
        key: 'current_profile_data',
        value: jsonEncode(updatedProfile.toJson()),
      );
      // Fixed: Call setCurrentProfile with the profile object directly
      await setCurrentProfile(updatedProfile.id);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update local profile: $e');
      }
      return false;
    }
  }
}