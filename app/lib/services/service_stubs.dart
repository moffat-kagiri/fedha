// lib/services/service_stubs.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/enums.dart';
import 'offline_data_service.dart';
import '../utils/logger.dart';

// Note: TransactionCandidate model has issues with json_serializable
// Temporarily removed import until fixed

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
  
  /// New method to match the expected interface
  Future<Map<String, dynamic>?> extractTransaction(String smsText) async {
    return extractTransactionFromSms(smsText);
  }
}

/// Simple placeholder for TransactionCandidate until the model is fixed
class TransactionCandidate {
  String id;
  String? rawText;
  double amount;
  String? description;
  String? category;
  DateTime date;
  Type type;
  TransactionStatus status;
  double confidence;
  
  TransactionCandidate({
    required this.id,
    this.rawText,
    required this.amount,
    this.description,
    this.category,
    required this.date,
    required this.type,
    this.status = TransactionStatus.pending,
    this.confidence = 0.5,
  });
  
  TransactionCandidate copyWith({
    String? id,
    String? rawText,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    Type? type,
    TransactionStatus? status,
    double? confidence,
    String? transactionId,
  }) {
    return TransactionCandidate(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
    );
  }
  
  bool get isPending => status == TransactionStatus.pending;
}

/// Main SMS listener service
class SmsListenerService extends ChangeNotifier {
  static SmsListenerService? _instance;
  static SmsListenerService get instance => _instance ??= SmsListenerService._();
  
  final _logger = AppLogger.getLogger('SmsListenerService');
  late OfflineDataService _offlineService;
  late SmsTransactionExtractor _extractor;
  
  String? _currentProfileId;
  bool _isListening = false;
  StreamSubscription? _smsSubscription;
  
  final List<TransactionCandidate> _pendingCandidates = [];
  final StreamController<List<TransactionCandidate>> _candidatesController = 
      StreamController<List<TransactionCandidate>>.broadcast();
  
  SmsListenerService._() {
    _logger.info('SmsListenerService initialized');
  }
  
  factory SmsListenerService() => instance;
  
  /// Initialize with dependencies (call this before using)
  Future<void> initialize(OfflineDataService offlineService) async {
    _offlineService = offlineService;
    _extractor = SmsTransactionExtractor(_offlineService);
    _logger.info('SmsListenerService initialized with dependencies');
  }
  
  /// Stream of transaction candidates
  Stream<List<TransactionCandidate>> get candidatesStream => _candidatesController.stream;
  
  /// Get current pending candidates
  List<TransactionCandidate> get pendingCandidates => List.unmodifiable(_pendingCandidates);
  
  /// Check if service is actively listening
  bool get isListening => _isListening;
  
  /// Set current profile for transaction association
  void setCurrentProfile(String profileId) {
    if (_currentProfileId != profileId) {
      _currentProfileId = profileId;
      _logger.info('SMS listener profile set: $profileId');
      notifyListeners();
    }
  }
  
  /// Start listening for SMS messages
  Future<void> startListening() async {
    if (_isListening) {
      _logger.info('SMS listener already running');
      return;
    }
    
    try {
      _logger.info('Starting SMS listener...');
      
      // TODO: Implement actual SMS permission check
      // await _checkSmsPermissions();
      
      // TODO: Setup actual SMS listener
      // _smsSubscription = _setupSmsListener();
      
      _isListening = true;
      _logger.info('✅ SMS listener started');
      notifyListeners();
      
    } catch (e, stackTrace) {
      _logger.severe('Failed to start SMS listener', e, stackTrace);
      _isListening = false;
      rethrow;
    }
  }
  
  /// Stop listening for SMS messages
  Future<void> stopListening() async {
    if (!_isListening) {
      _logger.info('SMS listener already stopped');
      return;
    }
    
    try {
      _logger.info('Stopping SMS listener...');
      
      // Cancel subscription
      await _smsSubscription?.cancel();
      _smsSubscription = null;
      
      _isListening = false;
      _logger.info('✅ SMS listener stopped');
      notifyListeners();
      
    } catch (e, stackTrace) {
      _logger.severe('Failed to stop SMS listener', e, stackTrace);
      rethrow;
    }
  }
  
  /// Process incoming SMS message
  Future<void> _processSms(String smsText) async {
    if (_currentProfileId == null) {
      _logger.warning('No profile set, skipping SMS processing');
      return;
    }
    
    try {
      _logger.info('Processing SMS (${smsText.length} chars)');
      
      // Extract transaction candidate from SMS
      final candidateData = await _extractor.extractTransaction(smsText);
      
      if (candidateData != null) {
        // Create a simple candidate from the data
        final candidate = TransactionCandidate(
          id: const Uuid().v4(),
          amount: candidateData['amount'] ?? 0.0,
          date: candidateData['date'] ?? DateTime.now(),
          type: candidateData['type'] ?? Type.expense,
          description: candidateData['description'],
          category: candidateData['category'],
        );
        await _addCandidate(candidate);
      } else {
        _logger.info('No transaction extracted from SMS');
      }
      
    } catch (e, stackTrace) {
      _logger.severe('Error processing SMS', e, stackTrace);
    }
  }
  
  /// Add a new transaction candidate
  Future<void> _addCandidate(TransactionCandidate candidate) async {
    try {
      // Add to pending list
      _pendingCandidates.add(candidate);
      
      // TODO: Save to offline storage when OfflineDataService supports it
      // await _offlineService.saveTransactionCandidate(candidate);
      
      // Notify listeners
      _candidatesController.add(List.unmodifiable(_pendingCandidates));
      notifyListeners();
      
      _logger.info('✅ Transaction candidate added: ${candidate.amount} ${candidate.type}');
      
    } catch (e, stackTrace) {
      _logger.severe('Error adding transaction candidate', e, stackTrace);
    }
  }
  
  /// Approve a transaction candidate and convert to actual transaction
  Future<Map<String, dynamic>?> approveCandidate(
    String candidateId, {
    String? category,
    String? description,
    String? goalId,
    String? budgetCategory,
  }) async {
    try {
      // Find candidate
      final candidateIndex = _pendingCandidates.indexWhere((c) => c.id == candidateId);
      if (candidateIndex == -1) {
        _logger.warning('Candidate not found: $candidateId');
        return null;
      }
      
      final candidate = _pendingCandidates[candidateIndex];
      
      // Create transaction data (not the actual model to avoid import issues)
      final transactionData = {
        'id': _generateTransactionId(),
        'profileId': _currentProfileId!,
        'amountMinor': (candidate.amount * 100).round(), // Convert to minor units
        'type': _mapTypeToString(candidate.type),
        'isExpense': candidate.type == Type.expense,
        'category': category ?? candidate.category ?? 'other',
        'description': description ?? candidate.description ?? 'SMS Transaction',
        'date': candidate.date,
        'goalId': goalId,
        'budgetCategory': budgetCategory,
        'currency': 'KES',
        'isSynced': false,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      
      // TODO: Save transaction when model is fixed
      // final transaction = Transaction.fromJson(transactionData);
      // await _offlineService.saveTransaction(transaction);
      
      // Update candidate status
      final updatedCandidate = candidate.copyWith(
        status: TransactionStatus.completed,
      );
      
      // Update in memory
      _pendingCandidates[candidateIndex] = updatedCandidate;
      
      // TODO: Update in storage when OfflineDataService supports it
      // await _offlineService.updateTransactionCandidate(updatedCandidate);
      
      // Notify listeners
      _candidatesController.add(List.unmodifiable(_pendingCandidates));
      notifyListeners();
      
      _logger.info('✅ Candidate approved and converted to transaction');
      
      return transactionData;
      
    } catch (e, stackTrace) {
      _logger.severe('Error approving candidate', e, stackTrace);
      return null;
    }
  }
  
  /// Reject a transaction candidate
  Future<bool> rejectCandidate(String candidateId, {String? reason}) async {
    try {
      final candidateIndex = _pendingCandidates.indexWhere((c) => c.id == candidateId);
      if (candidateIndex == -1) return false;
      
      final candidate = _pendingCandidates[candidateIndex];
      final updatedCandidate = candidate.copyWith(
        status: TransactionStatus.cancelled,
      );
      
      // Update in memory
      _pendingCandidates[candidateIndex] = updatedCandidate;
      
      // TODO: Update in storage when OfflineDataService supports it
      // await _offlineService.updateTransactionCandidate(updatedCandidate);
      
      // Notify listeners
      _candidatesController.add(List.unmodifiable(_pendingCandidates));
      notifyListeners();
      
      _logger.info('✅ Candidate rejected: $candidateId');
      
      return true;
      
    } catch (e, stackTrace) {
      _logger.severe('Error rejecting candidate', e, stackTrace);
      return false;
    }
  }
  
  /// Clear all pending candidates
  Future<void> clearCandidates() async {
    try {
      _pendingCandidates.clear();
      
      _candidatesController.add([]);
      notifyListeners();
      
      _logger.info('✅ All candidates cleared');
      
    } catch (e, stackTrace) {
      _logger.severe('Error clearing candidates', e, stackTrace);
    }
  }
  
  /// Load pending candidates from storage
  Future<void> loadCandidates() async {
    try {
      if (_currentProfileId == null) {
        _logger.warning('No profile set, cannot load candidates');
        return;
      }
      
      // TODO: Load candidates from storage when supported
      // final storedCandidates = await _offlineService.getTransactionCandidates(_currentProfileId!);
      // _pendingCandidates.clear();
      // _pendingCandidates.addAll(storedCandidates.where((c) => c.isPending));
      
      _candidatesController.add(List.unmodifiable(_pendingCandidates));
      notifyListeners();
      
      _logger.info('Loaded ${_pendingCandidates.length} pending candidates');
      
    } catch (e, stackTrace) {
      _logger.severe('Error loading candidates', e, stackTrace);
    }
  }
  
  /// Check SMS permissions (placeholder)
  Future<bool> _checkSmsPermissions() async {
    _logger.info('Checking SMS permissions...');
    
    // TODO: Implement actual permission checking
    // For Android: READ_SMS permission
    // For iOS: Not supported, need alternate approach
    
    return true; // Placeholder
  }
  
  /// Setup SMS listener (placeholder)
  StreamSubscription? _setupSmsListener() {
    _logger.info('Setting up SMS listener...');
    
    // TODO: Implement actual SMS listening
    // For Android: Use sms package or platform channels
    // For iOS: Not directly possible, need workarounds
    
    return null;
  }
  
  /// Generate transaction ID
  String _generateTransactionId() {
    return 'txn_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
  }
  
  /// Map Type enum to string
  String _mapTypeToString(Type type) {
    switch (type) {
      case Type.income:
        return 'income';
      case Type.savings:
        return 'savings';
      case Type.expense:
      default:
        return 'expense';
    }
  }
  
  // Helper for UUID generation
  static final _uuid = Uuid();
  
  @override
  void dispose() {
    _smsSubscription?.cancel();
    _candidatesController.close();
    super.dispose();
  }
}

// Remove the problematic GoalTransactionService for now
// class GoalTransactionService {
//   final OfflineDataService _offlineService;
//   
//   GoalTransactionService(this._offlineService);
//   
//   Future<void> createSavingsTransaction(String goalId, double amount) async {
//     // Temporarily removed due to Transaction model import issues
//   }
// 
//   Future<List<dynamic>> getSuggestedGoals() async {
//     // Return the user's goals from the DB
//     return [];
//   }
// 
//   Future<Map<String, dynamic>> getGoalProgressSummary(String goalId) async {
//     return {'progress': 0.0};
//   }
// }

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
