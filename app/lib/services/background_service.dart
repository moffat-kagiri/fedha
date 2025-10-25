import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' show Color;
import '../data/app_database.dart';
import '../services/offline_data_service.dart';
import '../services/sms_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Check if still logged in
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (!isLoggedIn) {
      return Future.value(false);
    }
    
    switch (task) {
      case 'sms_listener_task':
        try {
          // Initialize database and services
          final db = AppDatabase();
          final dataService = OfflineDataService(db: db);
          await dataService.initialize();
          
          try {
            // Create and initialize SMS listener
            final smsListener = SmsListenerService();
            
            // Get profile ID from input data with fallback
            final profileId = inputData?['profileId'] as String? ?? '1';
            final numericProfileId = int.tryParse(profileId) ?? 1;
            
            // Start SMS processing with offline data service
            await smsListener.initialize(
              offlineDataService: dataService,
              profileId: profileId
            );
            
            // Check for pending transactions
            final pendingCount = await dataService.getPendingTransactionCount(numericProfileId);
            
            if (pendingCount > 0) {
              // Show notification only if there are pending transactions
              // Initialize notifications if not already initialized
              if (!await AwesomeNotifications().isNotificationAllowed()) {
                await AwesomeNotifications().initialize(
                  null, // no icon for now, can be updated later
                  [
                    NotificationChannel(
                      channelKey: 'pending_transactions',
                      channelName: 'Pending Transactions',
                      channelDescription: 'Notifications for pending transaction reviews',
                      defaultColor: const Color(0xFF9D50DD),
                      importance: NotificationImportance.High,
                      channelShowBadge: true,
                    ),
                  ],
                );
              }

              // Show notification
              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: 0,
                  channelKey: 'pending_transactions',
                  title: 'New Transactions to Review',
                  body: 'You have $pendingCount pending transactions to review',
                  notificationLayout: NotificationLayout.Default,
                ),
              );
            }
            
            return Future.value(true);
          } finally {
            // Always ensure database is closed
            await db.close();
          }
        } catch (e) {
          print('Error in background task: $e');
          return Future.value(false);
        }
    }
    return Future.value(false);
  });
}