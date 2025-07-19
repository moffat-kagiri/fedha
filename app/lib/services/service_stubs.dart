// Stub services for missing functionality

import 'offline_data_service.dart';

class TextRecognitionService {
  final OfflineDataService _offlineService;
  
  TextRecognitionService(this._offlineService);
  
  Future<String?> extractTextFromImage(String imagePath) async {
    // Placeholder
    return null;
  }
}

class CSVUploadService {
  final OfflineDataService _offlineService;
  
  CSVUploadService(this._offlineService);
  
  Future<List<Map<String, dynamic>>> parseCSV(String filePath) async {
    // Placeholder
    return [];
  }
}

class SmsTransactionExtractor {
  final OfflineDataService _offlineService;
  
  SmsTransactionExtractor(this._offlineService);
  
  Map<String, dynamic>? extractTransactionFromSms(String smsText) {
    // Placeholder
    return null;
  }
}

class SmsListenerService {
  final OfflineDataService _offlineService;
  final SmsTransactionExtractor _extractor;
  
  SmsListenerService(this._offlineService, this._extractor);
  
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

class GoalTransactionService {
  final OfflineDataService _offlineService;
  
  GoalTransactionService(this._offlineService);
  
  Future<void> createSavingsTransaction(String goalId, double amount) async {
    // Placeholder
  }

  List<Map<String, dynamic>> getSuggestedGoals() {
    // Placeholder
    return [];
  }

  Map<String, dynamic> getGoalProgressSummary(String goalId) {
    // Placeholder
    return {};
  }
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();
  
  Future<void> initialize() async {
    // Placeholder
  }
  
  Future<void> showNotification(String title, String body) async {
    // Placeholder
  }
}

class ThemeService {
  dynamic getLightTheme() {
    // Placeholder
    return null;
  }
  
  dynamic getDarkTheme() {
    // Placeholder  
    return null;
  }
  
  dynamic get themeMode {
    // Placeholder
    return null;
  }
  
  Future<void> initialize() async {
    // Placeholder
  }
}

class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();
  
  NavigationService._();
  
  static dynamic get navigatorKey {
    // Placeholder
    return null;
  }
}

class SenderManagementService {
  static SenderManagementService? _instance;
  static SenderManagementService get instance => _instance ??= SenderManagementService._();
  
  SenderManagementService._();
}

class OfflineManager {
  Future<void> initialize() async {
    // Placeholder
  }
}

class BackgroundTransactionMonitor {
  final OfflineDataService _offlineService;
  final SmsTransactionExtractor _extractor;
  
  BackgroundTransactionMonitor(this._offlineService, this._extractor);
  
  Future<void> start() async {
    // Placeholder
  }

  Future<void> initialize() async {
    // Placeholder
  }
}

class GoogleAuthService {
  static GoogleAuthService? _instance;
  static GoogleAuthService get instance => _instance ??= GoogleAuthService._();
  
  GoogleAuthService._();

  Future<bool> saveCredentialsToGoogle({required String email, required String name}) async {
    // Placeholder
    return false;
  }

  Future<void> clearSavedCredentials() async {
    // Placeholder
  }
}

class CurrencyService {
  static String formatCurrency(double amount, {String? currency}) {
    final curr = currency ?? 'KES';
    return '$curr ${amount.toStringAsFixed(2)}';
  }
}
