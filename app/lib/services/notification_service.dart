import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'reminders_channel',
          channelName: 'Daily Reminders',
          channelDescription: 'Daily prompts to review pending transactions',
          defaultColor: const Color(0xFF007A39),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
      debug: false,
    );
    // Request permission if needed
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> showPendingTransactionsNotification(int count) async {
    final title = 'Review transactions';
    final body = count == 0
        ? 'No pending transactions — great job today!'
        : 'You have $count pending ${count == 1 ? 'transaction' : 'transactions'} to review.';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'reminders_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
