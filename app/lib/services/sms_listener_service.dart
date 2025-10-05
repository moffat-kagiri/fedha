import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as inbox;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../models/category.dart' as models;
import 'sms_transaction_extractor.dart';
import '../services/offline_data_service.dart';
import '../data/app_database.dart';

/// Top-level callback function for Workmanager background tasks.
/// Must be annotated with @pragma('vm:entry-point') to prevent tree-shaking.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'sms_listener_task') {
      try {
        final profileId = inputData?['profileId'] as String?;
        if (profileId == null || profileId.isEmpty) {
          if (kDebugMode) {
            print('Background task failed: Invalid or missing profileId');
          }
          return false;
        }

        // Initialize services with proper dependencies
        final db = AppDatabase();
        final dataService = OfflineDataService(db: db);
        final smsListener = SmsListenerService.getInstance(dataService: dataService);

        try {
          // Request SMS permissions
          if (!await smsListener.checkAndRequestPermissions()) {
            if (kDebugMode) {
              print('Background task failed: SMS permissions not granted');
            }
            return false;
          }

          // Setup notification channel for background service
          final notifications = FlutterLocalNotificationsPlugin();
          const androidChannel = AndroidNotificationChannel(
            'sms_listener_background',
            'SMS Listener Background Service',
            description: 'Monitors financial SMS messages in the background',
            importance: Importance.low,
            enableVibration: false,
            playSound: false,
          );

          await notifications
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(androidChannel);

          const androidSettings = AndroidNotificationDetails(
            'sms_listener_background',
            'SMS Listener Background Service',
            channelDescription: 'Monitors financial SMS messages in the background',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
          );

          // Show background service notification
          await notifications.show(
            2, // Different ID from foreground service
            'Fedha SMS Monitor',
            'Monitoring financial messages in background',
            const NotificationDetails(android: androidSettings),
          );

          // Poll for new messages
          final query = inbox.SmsQuery();
          final messages = await query.querySms(
            count: 20,
            sort: true,
          );

          for (final msg in messages) {
            final timestamp = msg.date is DateTime
                ? msg.date as DateTime
                : DateTime.fromMillisecondsSinceEpoch((msg.date as int?) ?? 0);

            final smsMsg = SmsMessage(
              sender: msg.address ?? '',
              body: msg.body ?? '',
              timestamp: timestamp,
            );

            // Process if it's a financial message
            if (smsListener._isFinancialTransaction(smsMsg)) {
              await smsListener._handleSmsReceived(smsMsg.toMap());
            }
          }

          if (kDebugMode) {
            print('Background SMS check completed successfully');
          }
          return true;
        } finally {
          // Clean up resources
          await db.close();
        }
      } catch (e, st) {
        if (kDebugMode) {
          print('Background task failed with error: $e');
          print('Stack trace: $st');
        }
        return false;
      }
    }
    return false;
  });
}

  /// Initialize the SMS listener service with the given profile ID.
  /// 
  /// This method:
  /// 1. Sets up SMS permissions
  /// 2. Initializes notifications
  /// 3. Sets up background tasks via Workmanager
  /// 4. Starts foreground SMS polling
  /// 
  /// Returns false if permissions are denied or initialization fails.
  Future<bool> initialize(String profileId) async {
    try {
      if (profileId.isEmpty) {
        if (kDebugMode) print('Cannot initialize with empty profileId');
        return false;
      }
      
      _currentProfileId = profileId;
      
      if (!await checkAndRequestPermissions()) {
        if (kDebugMode) print('SMS permissions not granted');
        return false;
      }
      
      // Initialize notifications
      await _initializeNotifications();
      
      // Initialize Workmanager for background tasks
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      
      // Register periodic task
      await Workmanager().registerPeriodicTask(
        'sms_listener',
        'sms_listener_task',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
        inputData: {
          'profileId': profileId,
        },
      );
      
      // Start foreground polling
      DateTime? lastTimestamp;
      _pollTimer?.cancel(); // Cancel any existing timer
      _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          // Poll SMS messages from inbox
          if (kDebugMode) print('Polling SMS inbox...');
          final List<inbox.SmsMessage> raw = await _query.querySms(
            count: 20,
            sort: true,
          );
          if (kDebugMode) print('Retrieved ${raw.length} SMS messages');
          
          for (var nativeMsg in raw) {
            // plugin returns DateTime or int? ensure a DateTime
            final DateTime msgTime = nativeMsg.date is DateTime
                ? nativeMsg.date as DateTime
                : DateTime.fromMillisecondsSinceEpoch((nativeMsg.date as int?) ?? 0);
                
            if (lastTimestamp == null || msgTime.isAfter(lastTimestamp!)) {
              lastTimestamp = msgTime;
              final msg = SmsMessage(
                sender: nativeMsg.address ?? '',
                body: nativeMsg.body ?? '',
                timestamp: msgTime,
              );
              if (kDebugMode) print('Evaluating SMS: sender=${msg.sender}, body=${msg.body}');
              
              if (_isFinancialTransaction(msg)) {
                _handleSmsReceived(msg.toMap());
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('Error during SMS polling: $e');
        }
      });

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
  // Dependency injection friendly singleton pattern
  static SmsListenerService? _instance;
  
  /// Gets the current singleton instance.
  /// 
  /// Throws a StateError if getInstance() hasn't been called first with dependencies.
  static SmsListenerService get instance {
    if (_instance == null) {
      throw StateError(
        'SmsListenerService has not been initialized. '
        'Call getInstance() with dependencies first.'
      );
    }
    return _instance!;
  }
  
  /// Creates or returns the singleton instance with the provided dependencies.
  /// Must be called before accessing the singleton via instance getter.
  /// 
  /// Example:
  /// ```dart
  /// final dataService = OfflineDataService(...);
  /// final smsListener = SmsListenerService.getInstance(dataService: dataService);
  /// ```
  static SmsListenerService getInstance({
    required OfflineDataService dataService,
  }) {
    _instance ??= SmsListenerService._(dataService: dataService);
    return _instance!;
  }
  
  final OfflineDataService _offlineDataService;
  
  // Private constructor to enforce singleton pattern with DI
  SmsListenerService._({
    required OfflineDataService dataService,
  }) : _offlineDataService = dataService;
  
  final inbox.SmsQuery _query = inbox.SmsQuery();
  Timer? _pollTimer;
  StreamController<SmsMessage>? _messageController;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isListening = false;
  String? _currentProfileId;
  List<SmsMessage> _recentMessages = [];
  
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
  


  /// Initialize notifications
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initializationSettings);
  }

  /// Start listening for SMS transactions with the current profile ID.
  /// Returns false if no profile ID is set or initialization fails.
  Future<bool> startListening() async {
    if (_currentProfileId == null || _currentProfileId!.isEmpty) {
      if (kDebugMode) print('Cannot start listening: no profile ID set');
      return false;
    }
    return initialize(_currentProfileId!);
  }

  /// Stop polling SMS inbox
  Future<void> stopListening() async {
    _pollTimer?.cancel();
    _isListening = false;
    notifyListeners();
  }
  
  
  void setCurrentProfile(String profileId) {
    _currentProfileId = profileId;
    print('SMS listener profile set to: $profileId');
  }
  
  
  /// Process received SMS message
  void _handleSmsReceived(Map<String, dynamic> data) {
    final message = SmsMessage.fromMap(data);

    if (_isFinancialTransaction(message) && _currentProfileId != null) {
      // Add to recent queue
      _recentMessages.insert(0, message);

      // Parse structured transaction data
      final data = parseTransaction(message);
      if (data != null) {
        // Fallback: use extractor to find recipient if parser didn't
        final extractor = SmsTransactionExtractor();
        final recipient = data.recipient ?? extractor.extractRecipient(message.body);
        final tx = Transaction(
          amount: data.amount,
          type: data.type.toLowerCase().contains('credit') ||
                 data.type.toLowerCase().contains('received')
              ? TransactionType.income
              : TransactionType.expense,
          categoryId: '',
          date: data.timestamp,
          profileId: _currentProfileId!,
          smsSource: data.rawMessage,
          reference: data.reference,
          recipient: recipient,
        );

  // Persist pending transaction for review
  unawaited(_offlineDataService.savePendingTransaction(tx));

        // Notify any listeners/UI
        _messageController?.add(message);
        notifyListeners();
      }
    }
  }
  
  /// Process a manually entered SMS string (iOS fallback)
  Future<void> processManualSms(String rawMessage) async {
    final msg = SmsMessage(
      sender: '',
      body: rawMessage,
      timestamp: DateTime.now(),
    );
    _handleSmsReceived(msg.toMap());
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
        type: TransactionType.expense, // Default to expense for SMS transactions
        profileId: _currentProfileId ?? '',
        id: const Uuid().v4(),
        amount: transactionData.amount,
        date: transactionData.timestamp,
        description: 'SMS: ${transactionData.type ?? ""} via ${transactionData.source}',
        categoryId: (await _guessCategory(transactionData)) ?? 'uncategorized',
        isRecurring: false,
        notes: 'Auto-detected from SMS',
        smsSource: transactionData.rawMessage,
        reference: transactionData.reference,
        recipient: transactionData.recipient,
      );
      
  // Save to pending transactions table via service
  await _offlineDataService.savePendingTransaction(transaction);
      
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
      // TODO: fetch categories via OfflineDataService
      final cats = await _offlineDataService.getCategories(int.tryParse(_currentProfileId!) ?? 0);
      final match = cats.firstWhere(
        (c) => c.name.toLowerCase() == entry.key,
        orElse: () => models.Category(id: '', name: ''));
      if (match.id.isNotEmpty) return match.id;
          }
        }
      }
      
      // Fall back to default categories
      if (data.type == 'received' || data.type == 'credit') {
  final cats = await _offlineDataService.getCategories(int.tryParse(_currentProfileId!) ?? 0);
  return cats.firstWhere(
    (c) => c.name.toLowerCase() == defaultIncomeCategory,
    orElse: () => models.Category(id: '', name: ''))
      .id;
      } else {
  final cats = await _offlineDataService.getCategories(int.tryParse(_currentProfileId!) ?? 0);
  return cats.firstWhere(
    (c) => c.name.toLowerCase() == defaultExpenseCategory,
    orElse: () => models.Category(id: '', name: ''))
      .id;
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

