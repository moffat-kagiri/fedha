import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

class SmsListenerService extends ChangeNotifier {
  static SmsListenerService? _instance;
  static SmsListenerService get instance => _instance ??= SmsListenerService._();
  
  SmsListenerService._();
  
  static const MethodChannel _channel = MethodChannel('sms_listener');
  static const EventChannel _eventChannel = EventChannel('sms_listener_events');
  StreamController<SmsMessage>? _messageController;
  StreamSubscription? _eventChannelSubscription;
  
  bool _isListening = false;
  List<SmsMessage> _recentMessages = [];
  String? _currentProfileId;
  
  Stream<SmsMessage> get messageStream {
    _messageController ??= StreamController<SmsMessage>.broadcast();
    return _messageController!.stream;
  }
  
  List<SmsMessage> get recentMessages => List.unmodifiable(_recentMessages);
  bool get isListening => _isListening;
  
  /// Check for SMS permission and request it if needed
  Future<bool> checkAndRequestPermissions() async {
    try {
      // Check if SMS permission is granted
      var status = await Permission.sms.status;
      
      // If not granted, request permission
      if (!status.isGranted) {
        status = await Permission.sms.request();
      }
      
      if (kDebugMode) {
        print('SMS permission status: ${status.name}');
      }
      
      // Return whether permission is granted
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking SMS permissions: $e');
      }
      return false;
    }
  }
  
  /// Initialize the SMS listener service
  Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        // Web doesn't support SMS
        if (kDebugMode) {
          print('SMS listener not supported on web');
        }
        return false;
      }
      
      // Set up method channel handler
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Set up event channel listener
      _eventChannelSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map<Object?, Object?>) {
            _handleSmsReceived(Map<String, dynamic>.from(event as Map));
          }
        },
        onError: (dynamic error) {
          if (kDebugMode) {
            print('SMS event channel error: $error');
          }
        }
      );
      
      // For development, simulate initialization success
      if (kDebugMode) {
        print('SMS listener initialized (development mode)');
        return true;
      }
      
      // In production, initialize native SMS listener
      final result = await _channel.invokeMethod('initialize');
      return result == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SMS listener: $e');
      }
      return false;
    }
  }
  
  /// Start listening for SMS messages
  Future<void> startListening() async {
    if (_isListening) return;
    
    try {
      if (kDebugMode) {
        // Simulate starting in development
        _isListening = true;
        print('SMS listener started (development mode)');
        _simulateIncomingMessages();
        notifyListeners();
        return;
      }
      
      final result = await _channel.invokeMethod('startListening');
      if (result == true) {
        _isListening = true;
        print('SMS listener started successfully');
        notifyListeners();
      }
    } catch (e) {
      print('Error starting SMS listener: $e');
    }
  }
  
  /// Stop listening for SMS messages
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      if (kDebugMode) {
        _isListening = false;
        print('SMS listener stopped (development mode)');
        notifyListeners();
        return;
      }
      
      final result = await _channel.invokeMethod('stopListening');
      if (result == true) {
        _isListening = false;
        print('SMS listener stopped successfully');
        notifyListeners();
      }
    } catch (e) {
      print('Error stopping SMS listener: $e');
    }
  }
  
  void setCurrentProfile(String profileId) {
    _currentProfileId = profileId;
    print('SMS listener profile set to: $profileId');
  }
  
  /// Handle incoming method calls from native code
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSmsReceived':
        _handleSmsReceived(call.arguments);
        break;
      default:
        print('Unhandled method call: ${call.method}');
    }
  }
  
  /// Process received SMS message
  void _handleSmsReceived(Map<String, dynamic> data) {
    try {
      final message = SmsMessage.fromMap(data);
      
      // Check if it's a financial transaction
      if (_isFinancialTransaction(message)) {
        _recentMessages.insert(0, message);
        
        // Keep only recent messages (last 50)
        if (_recentMessages.length > 50) {
          _recentMessages = _recentMessages.take(50).toList();
        }
        
        // Parse transaction
        final transaction = parseTransaction(message);
        if (transaction != null) {
          // Save to pending transactions for review
          _savePendingTransaction(transaction);
          
          // Notify listeners
          _messageController?.add(message);
          notifyListeners();
          
          if (kDebugMode) {
            print('Financial transaction parsed: ${transaction.type} - ${transaction.amount} ${transaction.currency}');
          }
        }
        
        if (kDebugMode) {
          print('Financial SMS detected: ${message.sender} - ${message.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing SMS: $e');
      }
    }
  }
  
  /// Save a pending transaction to be reviewed
  Future<void> _savePendingTransaction(TransactionData transactionData) async {
    try {
      if (_currentProfileId == null) {
        if (kDebugMode) {
          print('No current profile set, cannot save transaction');
        }
        return;
      }
      
      // Create a transaction entry
      final transaction = Transaction(
        type: TransactionType.expense, // Add the required type parameter
        id: const Uuid().v4(),
        amount: transactionData.amount,
        date: transactionData.timestamp,
        description: 'SMS: ${transactionData.type} via ${transactionData.source}',
        categoryId: await _guessCategory(transactionData),
        // Keep any other existing parameters
      );
      
      // Save to pending transactions box
      final pendingBox = await Hive.openBox<Transaction>('pending_transactions');
      await pendingBox.add(transaction);
      
      if (kDebugMode) {
        print('Saved pending transaction: ${transaction.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving pending transaction: $e');
      }
    }
  }
  
  /// Guess transaction category based on content
  Future<String?> _guessCategory(TransactionData data) async {
    // Default categories
    const defaultIncomeCategory = 'income';
    const defaultExpenseCategory = 'expense';
    
    try {
      // Load categories
      final categoriesBox = await Hive.openBox('categories');
      
      // Keywords for common categories
      final Map<String, List<String>> categoryKeywords = {
        'food': ['restaurant', 'food', 'cafe', 'coffee', 'grocery', 'supermarket'],
        'transport': ['uber', 'taxi', 'fare', 'transport', 'travel', 'car', 'petrol', 'fuel'],
        'shopping': ['shop', 'store', 'mall', 'market', 'buy', 'purchase'],
        'entertainment': ['movie', 'cinema', 'theatre', 'event', 'ticket', 'concert'],
        'utility': ['bill', 'water', 'electricity', 'internet', 'wifi', 'utility'],
        'rent': ['rent', 'house', 'apartment', 'accommodation'],
        'salary': ['salary', 'payment', 'wage', 'income', 'payday'],
      };
      
      // Check transaction description and recipient for keywords
      final String searchText = [
        data.rawMessage.toLowerCase(),
        data.recipient?.toLowerCase() ?? '',
      ].join(' ');
      
      for (final entry in categoryKeywords.entries) {
        for (final keyword in entry.value) {
          if (searchText.contains(keyword)) {
            // Find matching category ID
            for (final key in categoriesBox.keys) {
              final category = categoriesBox.get(key);
              if (category['name']?.toLowerCase() == entry.key) {
                return key.toString();
              }
            }
          }
        }
      }
      
      // Fall back to default categories
      if (data.type == 'received' || data.type == 'credit') {
        for (final key in categoriesBox.keys) {
          final category = categoriesBox.get(key);
          if (category['name']?.toLowerCase() == defaultIncomeCategory) {
            return key.toString();
          }
        }
      } else {
        for (final key in categoriesBox.keys) {
          final category = categoriesBox.get(key);
          if (category['name']?.toLowerCase() == defaultExpenseCategory) {
            return key.toString();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error guessing category: $e');
      }
    }
    
    return null;
  }
  
  /// Simulate incoming messages for development
  void _simulateIncomingMessages() {
    if (!kDebugMode) return;
    
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      
      final simulatedMessages = [
        {
          'sender': 'MPESA',
          'body': 'LNM1234567 Confirmed. Ksh5,000.00 sent to JANE DOE 0722123456 on 15/1/24 at 2:30 PM. M-PESA balance is Ksh15,420.50.',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        {
          'sender': 'KCB-BANK',
          'body': 'Transaction Alert: KES 2,500.00 has been debited from your account ending in 1234. Balance: KES 45,670.25. Ref: TXN789456123',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        {
          'sender': 'MPESA',
          'body': 'LNM2345678 Confirmed. You have received Ksh3,200.00 from JOHN SMITH 0733456789 on 15/1/24 at 3:15 PM. M-PESA balance is Ksh18,620.50.',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ];
      
      final randomMessage = simulatedMessages[DateTime.now().second % simulatedMessages.length];
      _handleSmsReceived(randomMessage);
    });
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
      'ncba', 'diamond', 'chase', 'gulf', 'prime', 'citibank'
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
      print('Error parsing transaction: $e');
      return null;
    }
  }
  
  /// Get recent financial messages
  List<SmsMessage> getRecentFinancialMessages({int limit = 20}) {
    return _recentMessages.take(limit).toList();
  }
  
  /// Clear message history
  void clearHistory() {
    _recentMessages.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messageController?.close();
    _messageController = null;
    _isListening = false;
    _recentMessages.clear();
    super.dispose();
  }
}

class SmsMessage {
  final String sender;
  final String body;
  final DateTime timestamp;
  final String? address;
  
  SmsMessage({
    required this.sender,
    required this.body,
    required this.timestamp,
    this.address,
  });
  
  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      sender: map['sender'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      address: map['address'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'address': address,
    };
  }
}

class TransactionData {
  final String type; // 'sent', 'received', 'withdrawal', 'deposit', etc.
  final double amount;
  final String currency;
  final String? recipient;
  final String? reference;
  final DateTime timestamp;
  final String source; // 'mpesa', 'bank', etc.
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
    
    // M-PESA transaction patterns
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
    
    // Extract reference/transaction code
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
    
    // Bank transaction patterns
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
