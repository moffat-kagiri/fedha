import 'package:flutter/foundation.dart';

class GoogleAuthService extends ChangeNotifier {
  static GoogleAuthService? _instance;
  static GoogleAuthService get instance => _instance ??= GoogleAuthService._();
  
  GoogleAuthService._();

  Future<bool> signIn() async {
    // Stub implementation
    return false;
  }

  Future<void> signOut() async {
    // Stub implementation
  }

  bool get isSignedIn => false;
  
  String? get userEmail => null;
  String? get userName => null;

  Future<bool> saveCredentialsToGoogle({required String email, required String name}) async {
    // Placeholder
    return false;
  }

  Future<void> clearSavedCredentials() async {
    // Placeholder
  }
}
