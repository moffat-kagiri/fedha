// lib/services/sms_background_worker.dart
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as inbox;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/app_database.dart';
import '../services/offline_data_service.dart';
import '../services/sms_listener_service.dart';
import '../services/sms_transaction_extractor.dart';
import '../models/transaction.dart' as model;
import '../models/enums.dart';

/// Dedicated background worker for SMS processing
/// Runs independently of the main app UI
class SmsBackgroundWorker {
  static const String _lastProcessedKey = 'last_processed_sms_timestamp';
  
  /// Main entry point for background SMS processing
  static Future<bool> processSmsInBackground() async {
    try {
      print('🔄 SMS Background Worker: Starting...');
      
      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final profileId = prefs.getString('current_profile_id');
      
      if (!isLoggedIn || profileId == null || profileId.isEmpty) {
        print('❌ SMS Background Worker: No active session');
        return false;
      }
      
      print('✅ SMS Background Worker: Active session found for profile: $profileId');
      
      // Check SMS permissions
      final smsPermission = await Permission.sms.status;
      if (!smsPermission.isGranted) {
        print('❌ SMS Background Worker: SMS permission not granted');
        return false;
      }
      
      print('✅ SMS Background Worker: SMS permission granted');
      
      // Initialize database and services
      final db = AppDatabase();
      final offlineService = OfflineDataService(db: db);
      await offlineService.initialize();
      
      print('✅ SMS Background Worker: Services initialized');
      
      // Process SMS messages
      final messagesProcessed = await _processSmsMessages(
        offlineService: offlineService,
        profileId: profileId,
        prefs: prefs,
      );
      
      print('✅ SMS Background Worker: Processed $messagesProcessed messages');
      
      // Clean up
      await db.close();
      
      return messagesProcessed > 0;
      
    } catch (e, stackTrace) {
      print('❌ SMS Background Worker Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Process SMS messages from inbox
  static Future<int> _processSmsMessages({
    required OfflineDataService offlineService,
    required String profileId,
    required SharedPreferences prefs,
  }) async {
    try {
      // Get last processed timestamp
      final lastProcessed = prefs.getInt(_lastProcessedKey) ?? 0;
      final lastProcessedDate = DateTime.fromMillisecondsSinceEpoch(lastProcessed);
      
      print('📱 Processing SMS messages since: $lastProcessedDate');
      
      // Query recent SMS messages
      final query = inbox.SmsQuery();
      final List<inbox.SmsMessage> rawMessages = await query.querySms(
        count: 50,
        sort: true,
      );
      
      print('📬 Retrieved ${rawMessages.length} SMS messages');
      
      int newMessagesProcessed = 0;
      DateTime? latestTimestamp;
      
      // Initialize extractor
      final extractor = SmsTransactionExtractor();
      
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
          print('💰 Found financial SMS from: ${msg.sender}');
          await _saveTransaction(
            message: msg,
            offlineService: offlineService,
            profileId: profileId,
            extractor: extractor,
          );
          newMessagesProcessed++;
        }
      }
      
      // Update last processed timestamp
      if (latestTimestamp != null) {
        await prefs.setInt(_lastProcessedKey, latestTimestamp.millisecondsSinceEpoch);
        print('✅ Updated last processed timestamp to: $latestTimestamp');
      }
      
      return newMessagesProcessed;
      
    } catch (e, stackTrace) {
      print('❌ Error processing SMS messages: $e');
      print('Stack trace: $stackTrace');
      return 0;
    }
  }

  /// Maps the canonical source code from TransactionParser._detectSource()
  /// to a human-readable display name for the review card Platform tag.
  static String _platformDisplayNameStatic(String source) {
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
    return displayNames[source] ?? source;
  }

  /// Save transaction to pending transactions
  static Future<void> _saveTransaction({
    required SmsMessage message,
    required OfflineDataService offlineService,
    required String profileId,
    required SmsTransactionExtractor extractor,
  }) async {
    try {
      // Parse transaction data
      final parsedData = TransactionParser.parse(message);
      if (parsedData == null) {
        print('⚠️ Could not parse transaction from SMS');
        return;
      }
      
      // ✅ Extract platform and reference using enhanced extractor
      final platform = _platformDisplayNameStatic(parsedData.source);
      final reference = extractor.extractReference(message.body);
      final payee = extractor.extractRecipient(message.body);
      
      // Create transaction
      final tx = model.Transaction(
        amount: parsedData.amount,
        type: parsedData.type.toLowerCase().contains('credit') ||
               parsedData.type.toLowerCase().contains('received')
            ? 'income'
            : 'expense',
        category: '',
        date: parsedData.timestamp,
        profileId: profileId,
        smsSource: parsedData.rawMessage,
        reference: reference,
        recipient: platform,
        merchantName: payee,
      );
      
      // Save to pending transactions
      await offlineService.savePendingTransaction(tx);
      print('✅ Saved pending transaction: ${tx.amount} KES from $platform');
      
    } catch (e, stackTrace) {
      print('❌ Error saving transaction: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  /// Check if SMS is a financial transaction
  static bool _isFinancialTransaction(SmsMessage message) {
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
}
