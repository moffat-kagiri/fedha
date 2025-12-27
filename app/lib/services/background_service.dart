// lib/services/background_service.dart
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' show Color;
import '../services/sms_background_worker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background task dispatcher
/// This function runs in an isolate separate from the main app
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 Background Task Started: $task');
    
    try {
      // Check if still logged in
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (!isLoggedIn) {
        print('❌ No active session, skipping background task');
        return Future.value(false);
      }
      
      switch (task) {
        case 'sms_listener_task':
          return await _handleSmsListenerTask(prefs);
          
        case 'daily_review_task':
          return await _handleDailyReviewTask(prefs);
          
        default:
          print('⚠️ Unknown task: $task');
          return Future.value(false);
      }
    } catch (e, stackTrace) {
      print('❌ Background task error: $e');
      print('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

/// Handle SMS listener background task
Future<bool> _handleSmsListenerTask(SharedPreferences prefs) async {
  try {
    print('📱 SMS Listener Task: Processing...');
    
    // Process SMS messages in background
    final result = await SmsBackgroundWorker.processSmsInBackground();
    
    if (result) {
      print('✅ SMS Listener Task: Completed successfully');
    } else {
      print('ℹ️ SMS Listener Task: No new messages');
    }
    
    return Future.value(true);
    
  } catch (e, stackTrace) {
    print('❌ SMS Listener Task Error: $e');
    print('Stack trace: $stackTrace');
    return Future.value(false);
  }
}

/// Handle daily review notification task
Future<bool> _handleDailyReviewTask(SharedPreferences prefs) async {
  try {
    print('🔔 Daily Review Task: Processing...');
    
    final profileId = prefs.getString('current_profile_id');
    if (profileId == null || profileId.isEmpty) {
      print('❌ No profile ID found');
      return Future.value(false);
    }
    
    // Process SMS first
    await SmsBackgroundWorker.processSmsInBackground();
    
    // Initialize notifications
    await _initializeNotifications();
    
    // Get pending transaction count from shared preferences
    // (Background worker updates this)
    final pendingCount = prefs.getInt('pending_transaction_count_$profileId') ?? 0;
    
    if (pendingCount > 0) {
      await _showPendingTransactionsNotification(pendingCount);
      print('✅ Daily Review Task: Notification sent for $pendingCount transactions');
    } else {
      print('ℹ️ Daily Review Task: No pending transactions');
    }
    
    return Future.value(true);
    
  } catch (e, stackTrace) {
    print('❌ Daily Review Task Error: $e');
    print('Stack trace: $stackTrace');
    return Future.value(false);
  }
}

/// Initialize awesome notifications
Future<void> _initializeNotifications() async {
  try {
    final isInitialized = await AwesomeNotifications().isNotificationAllowed();
    if (!isInitialized) {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'pending_transactions',
            channelName: 'Pending Transactions',
            channelDescription: 'Notifications for pending transaction reviews',
            defaultColor: const Color(0xFF007A39),
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
        ],
      );
    }
  } catch (e) {
    print('⚠️ Could not initialize notifications: $e');
  }
}

/// Show pending transactions notification
Future<void> _showPendingTransactionsNotification(int count) async {
  try {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'pending_transactions',
        title: 'Review Transactions',
        body: count == 1
            ? 'You have 1 pending transaction to review'
            : 'You have $count pending transactions to review',
        notificationLayout: NotificationLayout.Default,
        payload: {'action': 'open_sms_review'},
      ),
    );
  } catch (e) {
    print('⚠️ Could not show notification: $e');
  }
}