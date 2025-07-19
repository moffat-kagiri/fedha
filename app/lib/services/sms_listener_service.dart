// Stub implementation for SMS listener service
import 'package:flutter/foundation.dart';

class SmsListenerService extends ChangeNotifier {
  static SmsListenerService? _instance;
  static SmsListenerService get instance => _instance ??= SmsListenerService._();
  
  SmsListenerService._();

  Future<void> startListening() async {
    // Placeholder
  }

  Future<void> stopListening() async {
    // Placeholder  
  }

  void setCurrentProfile(String profileId) {
    // Placeholder
  }
}
