// lib/services/sms_listener_service.dart
import 'dart:async';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as inbox;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import 'sms_transaction_extractor.dart';
import '../services/offline_data_service.dart';
import '../utils/logger.dart';

/// Internal SMS message model
class SmsMessage {
  final String sender;
  final String body;
  final DateTime timestamp;

  SmsMessage({
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'sender': sender,
        'body': body,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      sender: map['sender'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int? ?? 0),
    );
  }
}

class SmsListenerService extends ChangeNotifier {
  static SmsListenerService? _instance;
  static SmsListenerService get instance => _instance ??= SmsListenerService._();
  
  final _logger = AppLogger.getLogger('SmsListenerService');
  final inbox.SmsQuery _query = inbox.SmsQuery();
  Timer? _pollTimer;
  StreamController<SmsMessage>? _messageController;
  OfflineDataService? _offlineDataService;
  
  bool _isListening = false;
  List<SmsMessage> _recentMessages = [];
  String? _currentProfileId;
  
  // Track last processed SMS timestamp to avoid duplicates
  static const String _lastProcessedKey = 'last_processed_sms_timestamp';
  
  // Allow public constructor for background service
  factory SmsListenerService() => instance;
  
  SmsListenerService._();
  
  Stream<SmsMessage> get messageStream {
    _messageController ??= StreamController<SmsMessage>.broadcast();
    return _messageController!.stream;
  }
  
  List<SmsMessage> get recentMessages => List.unmodifiable(_recentMessages);
  bool get isListening => _isListening;
  
  /// Check for SMS permission and request it if needed
  Future<bool> checkAndRequestPermissions() async {
    try {
      var status = await Permission.sms.status;
      
      if (!status.isGranted) {
        status = await Permission.sms.request();
      }
      
      _logger.info('SMS permission status: ${status.name}');
      return status.isGranted;
    } catch (e) {
      _logger.severe('Error checking SMS permissions: $e');
      return false;
    }
  }
  
  /// Initialize the SMS listener service
  Future<bool> initialize({
    required OfflineDataService offlineDataService,
    required String profileId,
  }) async {
    try {
      _logger.info('Initializing SMS listener for profile: $profileId');
      
      if (!await checkAndRequestPermissions()) {
        _logger.warning('SMS permissions not granted');
        return false;
      }
      
      // Store dependencies
      _offlineDataService = offlineDataService;
      _currentProfileId = profileId;
      
      // Start foreground polling
      await _startForegroundPolling();
      
      _logger.info('✅ SMS listener initialized successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize SMS listener', e, stackTrace);
      return false;
    }
  }
  
  /// Start foreground polling (for when app is active)
  Future<void> _startForegroundPolling() async {
    if (_pollTimer != null) {
      _logger.info('Polling already active');
      return;
    }
    
    _logger.info('Starting foreground SMS polling...');
    
    // Process immediately on start
    await _processSmsMessages();
    
    // Then poll every 15 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _processSmsMessages();
    });
    
    _isListening = true;
    notifyListeners();
  }
  
  /// Process SMS messages from inbox
  Future<void> _processSmsMessages() async {
    try {
      if (_offlineDataService == null || _currentProfileId == null) {
        _logger.warning('Service not properly initialized');
        return;
      }
      
      // Get last processed timestamp
      final prefs = await SharedPreferences.getInstance();
      final lastProcessed = prefs.getInt(_lastProcessedKey) ?? 0;
      final lastProcessedDate = DateTime.fromMillisecondsSinceEpoch(lastProcessed);
      
      _logger.info('Processing SMS messages since: $lastProcessedDate');
      
      // Query recent SMS messages
      final List<inbox.SmsMessage> rawMessages = await _query.querySms(
        count: 50, // Increased to catch more messages
        sort: true,
      );
      
      int newMessagesProcessed = 0;
      DateTime? latestTimestamp;
      
      for (var nativeMsg in rawMessages) {
        final DateTime msgTime = nativeMsg.date is DateTime
            ? nativeMsg.date as DateTime
            : DateTime.fromMillisecondsSinceEpoch((nativeMsg.date as int?) ?? 0);
        
        // Skip if already processed
        if (msgTime.millisecondsSinceEpoch <= lastProcessed) {
          continue;
        }
        
        // Track latest timestamp
        if (latestTimestamp == null || msgTime.isAfter(latestTimestamp)) {
          latestTimestamp = msgTime;
        }
        
        final msg = SmsMessage(
          sender: nativeMsg.address ?? '',
          body: nativeMsg.body ?? '',
          timestamp: msgTime,
        );
        
        // Process if it's a financial transaction
        if (_isFinancialTransaction(msg)) {
          await _handleSmsReceived(msg.toMap());
          newMessagesProcessed++;
        }
      }
      
      // Update last processed timestamp
      if (latestTimestamp != null) {
        await prefs.setInt(_lastProcessedKey, latestTimestamp.millisecondsSinceEpoch);
        _logger.info('✅ Processed $newMessagesProcessed new SMS messages');
      } else if (newMessagesProcessed == 0) {
        _logger.info('No new SMS messages to process');
      }
      
    } catch (e, stackTrace) {
      _logger.severe('Error processing SMS messages', e, stackTrace);
    }
  }
  
  /// Start listening for SMS transactions
  Future<bool> startListening({
    required OfflineDataService offlineDataService,
    required String profileId,
  }) async {
    return initialize(
      offlineDataService: offlineDataService,
      profileId: profileId,
    );
  }
  
  /// Stop polling SMS inbox
  Future<void> stopListening() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isListening = false;
    notifyListeners();
    _logger.info('SMS listener stopped');
  }
  
  void setCurrentProfile(String profileId) {
    _currentProfileId = profileId;
    _logger.info('SMS listener profile set to: $profileId');
  }
  
  /// Process received SMS message
  Future<void> _handleSmsReceived(Map<String, dynamic> data) async {
    try {
      final message = SmsMessage.fromMap(data);

      if (_isFinancialTransaction(message) && _currentProfileId != null) {
        // Add to recent queue
        _recentMessages.insert(0, message);
        if (_recentMessages.length > 20) {
          _recentMessages = _recentMessages.sublist(0, 20);
        }

        // Parse structured transaction data
        final parsedData = parseTransaction(message);
        if (parsedData != null) {
          // Fallback: use extractor to find recipient if parser didn't
          final extractor = SmsTransactionExtractor();
          final recipient = parsedData.recipient ?? extractor.extractRecipient(message.body);
          
          final tx = Transaction(
            amount: parsedData.amount,
            type: parsedData.type.toLowerCase().contains('credit') ||
                   parsedData.type.toLowerCase().contains('received')
                ? Type.income
                : Type.expense,
            category: '',
            date: parsedData.timestamp,
            profileId: _currentProfileId!,
            smsSource: parsedData.rawMessage,
            reference: parsedData.reference,
            recipient: recipient,
          );

          // Persist pending transaction for review
          await _offlineDataService!.savePendingTransaction(tx);
          _logger.info('💰 Saved pending transaction: ${tx.amount} from ${message.sender}');
          
          // Notify any listeners/UI
          _messageController?.add(message);
        }
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _logger.severe('Error handling SMS', e, stackTrace);
    }
  }
  
  /// Process a manually entered SMS string (iOS fallback)
  Future<void> processManualSms(String rawMessage) async {
    final msg = SmsMessage(
      sender: 'MANUAL',
      body: rawMessage,
      timestamp: DateTime.now(),
    );
    await _handleSmsReceived(msg.toMap());
  }
  
  /// Check if SMS is a financial transaction
  bool _isFinancialTransaction(SmsMessage message) {
    final sender = message.sender.toLowerCase();
    final body = message.body.toLowerCase();
    
    // M-PESA transactions
    if (sender.contains('mpesa') || sender.contains('m-pesa')) {
      return body.contains('confirmed') || 
             body.contains('received') || 
             body.contains('sent') ||
             body.contains('paid') ||
             body.contains('withdrawn');
    }
    
    // Bank transactions
    final bankKeywords = [
      'kcb', 'equity', 'cooperative', 'coop', 'absa', 'dtb', 'family',
      'ncba', 'diamond', 'chase', 'gulf', 'prime', 'citibank', 'barclays',
      'standard', 'stanchart', 'bank'
    ];
    
    for (final bank in bankKeywords) {
      if (sender.contains(bank)) {
        return body.contains('transaction') ||
               body.contains('transfer') ||
               body.contains('deposit') ||
               body.contains('withdrawal') ||
               body.contains('payment') ||
               body.contains('debit') ||
               body.contains('credit');
      }
    }
    
    return false;
  }
  
  /// Parse transaction details from SMS
  TransactionData? parseTransaction(SmsMessage message) {
    try {
      return TransactionParser.parse(message);
    } catch (e) {
      _logger.warning('Error parsing transaction: $e');
      return null;
    }
  }
  
  /// Dispose resources
  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController?.close();
    super.dispose();
  }
}

// Transaction data models (unchanged)
class TransactionData {
  final String type;
  final double amount;
  final String currency;
  final String? recipient;
  final String? reference;
  final DateTime timestamp;
  final String source;
  final String rawMessage;
  
  TransactionData({
    required this.type,
    required this.amount,
    required this.currency,
    this.recipient,
    this.reference,
    required this.timestamp,
    required this.source,
    required this.rawMessage,
  });
}

class TransactionParser {
  static TransactionData? parse(SmsMessage message) {
    final sender = message.sender.toLowerCase();
    
    if (sender.contains('mpesa')) {
      return _parseMpesaTransaction(message);
    } else {
      return _parseBankTransaction(message);
    }
  }
  
  static TransactionData? _parseMpesaTransaction(SmsMessage message) {
    final body = message.body;
    
    final amountRegex = RegExp(r'Ksh([\d,]+\.?\d*)');
    final amountMatch = amountRegex.firstMatch(body);
    
    if (amountMatch == null) return null;
    
    final amountStr = amountMatch.group(1)?.replaceAll(',', '');
    final amount = double.tryParse(amountStr ?? '');
    
    if (amount == null) return null;
    
    String type = 'unknown';
    String? recipient;
    
    if (body.toLowerCase().contains('sent to')) {
      type = 'sent';
      final recipientRegex = RegExp(r'sent to ([^.]+)');
      final recipientMatch = recipientRegex.firstMatch(body);
      recipient = recipientMatch?.group(1)?.trim();
    } else if (body.toLowerCase().contains('received from')) {
      type = 'received';
      final senderRegex = RegExp(r'received from ([^.]+)');
      final senderMatch = senderRegex.firstMatch(body);
      recipient = senderMatch?.group(1)?.trim();
    } else if (body.toLowerCase().contains('withdrawn from')) {
      type = 'withdrawal';
    } else if (body.toLowerCase().contains('paid to')) {
      type = 'payment';
      final merchantRegex = RegExp(r'paid to ([^.]+)');
      final merchantMatch = merchantRegex.firstMatch(body);
      recipient = merchantMatch?.group(1)?.trim();
    }
    
    final refRegex = RegExp(r'([A-Z0-9]{10})');
    final refMatch = refRegex.firstMatch(body);
    final reference = refMatch?.group(1);
    
    return TransactionData(
      type: type,
      amount: amount,
      currency: 'KES',
      recipient: recipient,
      reference: reference,
      timestamp: message.timestamp,
      source: 'mpesa',
      rawMessage: message.body,
    );
  }
  
  static TransactionData? _parseBankTransaction(SmsMessage message) {
    final body = message.body;
    
    final amountRegex = RegExp(r'(KES|Ksh)\s*([\d,]+\.?\d*)');
    final amountMatch = amountRegex.firstMatch(body);
    
    if (amountMatch == null) return null;
    
    final amountStr = amountMatch.group(2)?.replaceAll(',', '');
    final amount = double.tryParse(amountStr ?? '');
    
    if (amount == null) return null;
    
    String type = 'unknown';
    if (body.toLowerCase().contains('debit')) {
      type = 'debit';
    } else if (body.toLowerCase().contains('credit')) {
      type = 'credit';
    } else if (body.toLowerCase().contains('transfer')) {
      type = 'transfer';
    } else if (body.toLowerCase().contains('withdrawal')) {
      type = 'withdrawal';
    }
    
    return TransactionData(
      type: type,
      amount: amount,
      currency: 'KES',
      timestamp: message.timestamp,
      source: 'bank',
      rawMessage: message.body,
    );
  }
}