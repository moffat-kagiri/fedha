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
  final _extractor = SmsTransactionExtractor();
  
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

  /// Maps the canonical source code from TransactionParser._detectSource()
  /// to a human-readable display name for the review card Platform tag.
  static String _platformDisplayName(String source) {
    const displayNames = {
      'mpesa':         'M-PESA',
      'airtel':        'Airtel Money',
      'tkash':         'T-Kash',
      'equitel':       'Equitel',
      'kcb':           'KCB Bank',
      'equity':        'Equity Bank',
      'ncba':          'NCBA Bank',
      'coop':          'Co-op Bank',
      'absa':          'Absa Bank',
      'family_bank':   'Family Bank',
      'dtb':           'Diamond Trust Bank',
      'stima_sacco':   'Stima SACCO',
      'mwalimu_sacco': 'Mwalimu SACCO',
      'harambee_sacco':'Harambee SACCO',
      'sacco':         'SACCO',
      'bank':          'Bank',
      'other':         'Other',
      'standard':      'Standard Chartered',
      'stanbic':       'Stanbic Bank',
      'kbsacco':       'Kenya Bankers SACCO',
      'gtbank':        'GT Bank',
      'guaranty':      'Guaranty Trust Bank',
    };
    return displayNames[source] ?? source.toUpperCase();
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
          // ✅ Extract platform (recipient) and reference using enhanced extractor
          // parsedData.source is set by TransactionParser._detectSource()
          // and is always a canonical lowercase key ('mpesa', 'kcb', etc.)
          final platform  = _platformDisplayName(parsedData.source);
          final reference = _extractor.extractReference(message.body);
          final payee     = _extractor.extractRecipient(message.body);
          
          final tx = Transaction(
            amount: parsedData.amount,
            type: parsedData.type.toLowerCase().contains('credit') || 
                  parsedData.type.toLowerCase().contains('received') ||
                  parsedData.type.toLowerCase().contains('deposit')
                ? 'income'
                : 'expense',
            category: '', // Will be set by user in review screen
            date: parsedData.timestamp,
            profileId: _currentProfileId!,
            smsSource: parsedData.rawMessage,
            reference: reference,
            recipient: platform, // Platform name (M-PESA, KCB Bank, etc.)
            merchantName: payee, // Actual person/merchant if found
          );

          // Persist pending transaction for review
          await _offlineDataService!.savePendingTransaction(tx);
          _logger.info('💰 Saved pending transaction: ${tx.amount} from $platform');
          
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

    // ── Tier 1: known sender short-codes / keywords ──────────────────────────
    const financialSenders = [
      // Mobile money
      'mpesa', 'm-pesa', 'safaricom', 'airtel', 'tkash', 't-kash', 'equitel',
      // Banks
      'kcb', 'equity', 'cooperative', 'co-op', 'coop', 'absa', 'barclays',
      'dtb', 'diamond', 'family', 'ncba', 'chase', 'gulf', 'prime', 'citibank',
      'standard', 'stanchart', 'i&m', 'crdb', 'victoria', 'sidian', 'gtbank',
      'guaranty', 'hfck', 'hf', 'nbk', 'consolidated', 'middle east', 'meb',
      // SACCOs & MFIs
      'stima', 'mwalimu', 'harambee', 'ukulima', 'kenya police', 'afya',
      'faulu', 'kwft', 'smep', 'rafiki', 'century', 'imarika', 'kenya bankers', 
      'kbsacco',
      // Generic
      'bank', 'sacco', 'microfinance', 'mfi',
    ];

    final senderMatches = financialSenders.any((k) => sender.contains(k));

    // ── Tier 2: financial body keywords (catches messages where sender is a
    //    numeric short-code, e.g. "40033") ───────────────────────────────────
    const bodyFinancialKeywords = [
      'confirmed', 'transaction', 'transfer', 'deposit', 'withdrawal',
      'withdrawn', 'payment', 'debit', 'debited', 'credit', 'credited',
      'received', 'sent to', 'paid to', 'account balance', 'new balance',
      'your account', 'your m-pesa', 'mpesa balance',
    ];

    // Require both a monetary indicator AND a financial action keyword to avoid
    // marketing messages that mention "credit card offers" etc.
    const monetaryIndicators = ['ksh', 'kes', 'ksh.', '/=', 'shilling'];

    final hasMonetary = monetaryIndicators.any((m) => body.contains(m));
    final hasAction = bodyFinancialKeywords.any((k) => body.contains(k));
    final bodyMatches = hasMonetary && hasAction;

    if (!senderMatches && !bodyMatches) return false;

    // ── Tier 3: if sender matched, still require at least one action keyword
    //    to filter out balance inquiry responses and promotional messages ──────
    if (senderMatches) {
      return hasAction || body.contains('confirmed');
    }

    return bodyMatches;
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

// Transaction data models
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

// ---------------------------------------------------------------------------
// TransactionParser 
// ---------------------------------------------------------------------------
class TransactionParser {
  // Ordered list of amount patterns, tried in sequence.
  // Group 1 always captures the numeric string.
  static final _amountPatterns = [
    RegExp(r'[Kk][Ee][Ss]\.?\s*([\d,]+\.?\d*)',     caseSensitive: false), // KES 1,500 / Kes1500
    RegExp(r'[Kk][Ss][Hh]\.?\s*([\d,]+\.?\d*)',     caseSensitive: false), // Ksh 1500 / KSH1500
    RegExp(r'([\d,]+\.?\d*)\s*/='),                                          // 1,500/=
    RegExp(r'(?:amount|debit(?:ed)?|credit(?:ed)?|sent|received|paid)[:\s]+'
           r'([\d,]+\.?\d*)',                        caseSensitive: false), // Amount: 500
  ];

  /// Returns a parsed [TransactionData] for any Kenyan financial SMS, or null
  /// if the message cannot be recognised as a transaction.
  static TransactionData? parse(SmsMessage message) {
    final body  = message.body;
    final lower = body.toLowerCase();

    // ── 1. Extract amount ─────────────────────────────────────────────────
    double? amount;
    for (final pattern in _amountPatterns) {
      final m = pattern.firstMatch(body);
      if (m != null) {
        final raw = m.group(1)!.replaceAll(',', '');
        amount = double.tryParse(raw);
        if (amount != null && amount > 0) break;
      }
    }
    if (amount == null) return null;

    // ── 2. Determine transaction type from body ───────────────────────────
    //    Map to the four canonical types the app uses.
    String type;
    if (_bodyContainsAny(lower, ['received', 'credited', 'credit', 'deposit', 'deposited'])) {
      type = 'income';
    } else if (_bodyContainsAny(lower, ['sent to', 'paid to', 'payment', 'debit', 'debited',
                                         'withdrawn', 'withdrawal', 'purchase'])) {
      type = 'expense';
    } else if (_bodyContainsAny(lower, ['saved', 'saving', 'goal', 'investment'])) {
      type = 'savings';
    } else if (_bodyContainsAny(lower, ['transfer', 'moved'])) {
      // Default transfers to expense (money left the account)
      type = 'expense';
    } else if (lower.contains('confirmed')) {
      // M-PESA "confirmed" without clear direction — treat as expense (most common)
      type = 'expense';
    } else {
      // Cannot determine direction
      return null;
    }

    // ── 3. Extract recipient / payee ─────────────────────────────────────
    String? recipient;
    final recipientPatterns = [
      RegExp(r'(?:sent to|paid to|transfer(?:red)? to)\s+([A-Z][A-Za-z ]{2,40}?)(?=\s+\d|\s+on|\s+at|\.)',
             caseSensitive: false),
      RegExp(r'received from\s+([A-Z][A-Za-z ]{2,40}?)(?=\s+\d|\s+on|\s+at|\.)',
             caseSensitive: false),
    ];
    for (final p in recipientPatterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        recipient = m.group(1)?.trim();
        break;
      }
    }

    // ── 4. Extract reference code ─────────────────────────────────────────
    // M-PESA codes are exactly 10 upper-case alphanumerics at word boundary.
    // Bank references vary — look for explicit ref/code label first.
    String? reference;
    final refPatterns = [
      RegExp(r'\b([A-Z]{2,3}\d{7,12})\b'),         // e.g. QHK1234567890 (M-PESA)
      RegExp(r'(?:ref|reference|txn|tran)[.:\s#]*([A-Z0-9]{6,20})',
             caseSensitive: false),
      RegExp(r'\b([A-Z0-9]{10})\b'),               // fallback 10-char code
    ];
    for (final p in refPatterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        reference = m.group(1);
        break;
      }
    }

    // ── 5. Determine source label ─────────────────────────────────────────
    final source = _detectSource(message.sender, lower);

    return TransactionData(
      type:       type,
      amount:     amount,
      currency:   'KES',
      recipient:  recipient,
      reference:  reference,
      timestamp:  message.timestamp,
      source:     source,
      rawMessage: body,
    );
  }

  static bool _bodyContainsAny(String lower, List<String> terms) =>
      terms.any((t) => lower.contains(t));

  static String _detectSource(String sender, String lowerBody) {
    final s = sender.toLowerCase();
    if (s.contains('mpesa') || s.contains('m-pesa') || lowerBody.contains('m-pesa balance')) {
      return 'mpesa';
    }
    if (s.contains('airtel')) return 'airtel';
    if (s.contains('tkash') || s.contains('t-kash')) return 'tkash';
    if (s.contains('equitel')) return 'equitel';
    if (s.contains('kcb')) return 'kcb';
    if (s.contains('equity')) return 'equity';
    if (s.contains('ncba')) return 'ncba';
    if (s.contains('coop') || s.contains('co-op')) return 'coop';
    if (s.contains('absa') || s.contains('barclays')) return 'absa';
    if (s.contains('family')) return 'family_bank';
    if (s.contains('dtb') || s.contains('diamond')) return 'dtb';
    if (s.contains('stima')) return 'stima_sacco';
    if (s.contains('mwalimu')) return 'mwalimu_sacco';
    if (s.contains('harambee')) return 'harambee_sacco';
    if (s.contains('sacco')) return 'sacco';
    if (s.contains('bank')) return 'bank';
    return 'other';
  }
}


