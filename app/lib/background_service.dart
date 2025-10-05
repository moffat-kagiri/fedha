import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'services/sms_listener_service.dart';
import 'data/app_database.dart';
import 'services/offline_data_service.dart';

final _logger = Logger('BackgroundService');

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Initialize logging for the background service
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.time} ${record.level.name} ${record.loggerName}: ${record.message}');
    if (record.error != null) print(record.error);
    if (record.stackTrace != null) print(record.stackTrace);
  });

  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'sms_listener_task':
        AppDatabase? db;
        SmsListenerService? smsListener;
        try {
          // Validate profileId from input data
          final profileId = inputData?['profileId'] as String? ?? '1';
          if (profileId.isEmpty) {
            print('Error: Empty profileId provided to SMS listener task');
            return false;
          }

          db = AppDatabase();
          final dataService = OfflineDataService(db: db);
          smsListener = SmsListenerService(dataService: dataService);
          
          // Start listening for SMS with validated profileId
          await smsListener.initialize(profileId);
          
          // Initialize notifications plugin with platform settings
          final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
          
          // Set up platform specific initialization settings
          const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
          const initializationSettings = InitializationSettings(
            android: androidInitSettings,
          );
          
          // Initialize the plugin
          await flutterLocalNotificationsPlugin.initialize(initializationSettings);
          
          // Create the notification channel for Android O and above
          const androidChannel = AndroidNotificationChannel(
            'sms_listener_channel', // Channel ID
            'SMS Listener Service', // Channel name
            description: 'Keeps track of financial SMS messages',
            importance: Importance.low,
            enableVibration: false,
            playSound: false,
          );
          
          // Create the channel
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(androidChannel);
          
          // Configure notification details using the created channel
          const androidSettings = AndroidNotificationDetails(
            androidChannel.id,
            androidChannel.name,
            channelDescription: androidChannel.description,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
          );
          
          // Show the notification using the configured channel
          await flutterLocalNotificationsPlugin.show(
            1,
            'Fedha SMS Listener',
            'Monitoring financial transactions',
            const NotificationDetails(android: androidSettings),
          );
          
          return true;
        } catch (e, st) {
          _logger.severe(
            'Failed to execute SMS listener background task',
            e,
            st,
          );
          return false;
        } finally {
          // Cleanup resources
          if (smsListener != null) {
            await smsListener.stopListening();
          }
          if (db != null) {
            await db.close();
          }
        }
        
      default:
        return false;
    }
  });
}