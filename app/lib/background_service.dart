import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/sms_listener_service.dart';
import 'data/app_database.dart';
import 'services/offline_data_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'sms_listener_task':
        try {
          final db = AppDatabase();
          final dataService = OfflineDataService(db: db);
          final smsListener = SmsListenerService(dataService: dataService);
          
          // Start listening for SMS
          await smsListener.initialize(inputData?['profileId'] ?? '1');
          
          // Show a notification that the service is running
          final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
          const androidSettings = AndroidNotificationDetails(
            'sms_listener_channel',
            'SMS Listener Service',
            channelDescription: 'Keeps track of financial SMS messages',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
          );
          
          await flutterLocalNotificationsPlugin.show(
            1,
            'Fedha SMS Listener',
            'Monitoring financial transactions',
            const NotificationDetails(android: androidSettings),
          );
          
          return true;
        } catch (e) {
          return false;
        }
        
      default:
        return false;
    }
  });
}