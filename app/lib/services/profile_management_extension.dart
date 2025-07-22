import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../models/profile.dart';

/// Extension to add profile management methods to AuthService
extension ProfileManagementExtension on AuthService {
  // Property references
  ApiClient get _apiClient => ApiClient();
  Profile? get _currentProfile => currentProfile;
  
  /// Update the user's profile information
  Future<bool> updateProfile({
    required Map<String, dynamic> profileData,
  }) async {
    try {
      if (_currentProfile == null) {
        return false;
      }
      
      final userId = _currentProfile!.id;
      final sessionToken = _currentProfile!.sessionToken ?? '';
      
      // Update the local profile data first
      final updatedProfile = _currentProfile!.copyWith(
        email: profileData['email'] ?? _currentProfile!.email,
        name: profileData['name'] ?? _currentProfile!.name,
        phoneNumber: profileData['phoneNumber'] ?? _currentProfile!.phoneNumber,
        photoUrl: profileData['photoUrl'] ?? _currentProfile!.photoUrl,
        updatedAt: DateTime.now(),
      );
      
      // Save locally
      await updateLocalProfile(updatedProfile);
      
      // Try to sync with server if online
      try {
        await _apiClient.updateProfile(
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
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      return false;
    }
  }
  
  /// Update the local profile data
  Future<void> updateLocalProfile(Profile updatedProfile) async {
    try {
      final profileBox = await getProfileBox();
      await profileBox.put(updatedProfile.id, updatedProfile);
      
      // Update the current profile if it's the one being edited
      if (profile?.id == updatedProfile.id) {
        setCurrentProfile(updatedProfile);
      }
      
      // Notify listeners of the update
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating local profile: $e');
      }
    }
  }
  
  /// Change the user's password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentProfile == null) {
        return false;
      }
      
      final userId = _currentProfile!.id;
      final sessionToken = _currentProfile!.sessionToken ?? '';
      
      final apiClient = ApiClient();
      final result = await apiClient.updatePassword(
        userId: userId,
        sessionToken: sessionToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      return result['error'] == null;
    } catch (e) {
      if (kDebugMode) {
        print('Error changing password: $e');
      }
      return false;
    }
  }
  
  /// Request password reset
  Future<bool> requestPasswordReset({required String email}) async {
    try {
      final apiClient = ApiClient();
      final result = await apiClient.requestPasswordReset(email: email);
      
      return result['error'] == null;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting password reset: $e');
      }
      return false;
    }
  }
}
