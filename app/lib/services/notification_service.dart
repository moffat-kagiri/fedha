import 'package:flutter/material.dart';
import '../data/app_database.dart';

class NotificationService extends ChangeNotifier {
  final AppDatabase _db;
  final int _profileId;
  List<Notification> _notifications = [];
  
  NotificationService(this._db, this._profileId);
  
  List<Notification> get notifications => _notifications;
  
  // Initialize notifications
  Future<void> initialize() async {
    await refreshNotifications();
  }
  
  // Refresh notifications list
  Future<void> refreshNotifications() async {
    _notifications = await _db.getAllNotifications(_profileId);
    notifyListeners();
  }
  
  // Get unread notifications count
  Future<int> getUnreadCount() async {
    final unread = await _db.getUnreadNotifications(_profileId);
    return unread.length;
  }
  
  // Create a new notification
  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    int? entityId,
    required DateTime scheduledFor,
  }) async {
    await _db.insertNotification(
      NotificationsCompanion.insert(
        title: title,
        body: body,
        type: type,
        entityId: Value(entityId),
        scheduledFor: scheduledFor,
        profileId: _profileId,
      ),
    );
    await refreshNotifications();
  }
  
  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    await _db.markNotificationAsRead(notificationId);
    await refreshNotifications();
  }
  
  // Clean up old notifications
  Future<void> cleanupOldNotifications({Duration? olderThan}) async {
    final cutoff = DateTime.now().subtract(olderThan ?? const Duration(days: 30));
    await _db.deleteOldNotifications(cutoff);
    await refreshNotifications();
  }
  
  // Create a budget alert
  Future<void> createBudgetAlert({
    required String categoryName,
    required double currentAmount,
    required double budgetLimit,
    required int budgetId,
  }) async {
    final percentage = (currentAmount / budgetLimit * 100).round();
    await createNotification(
      title: 'Budget Alert: $categoryName',
      body: 'You\'ve used $percentage% of your $categoryName budget',
      type: 'budget',
      entityId: budgetId,
      scheduledFor: DateTime.now(),
    );
  }
  
  // Create a goal reminder
  Future<void> createGoalReminder({
    required String goalName,
    required double currentAmount,
    required double targetAmount,
    required DateTime dueDate,
    required int goalId,
  }) async {
    final daysLeft = dueDate.difference(DateTime.now()).inDays;
    final percentage = (currentAmount / targetAmount * 100).round();
    
    await createNotification(
      title: 'Goal Reminder: $goalName',
      body: '$daysLeft days left to reach your goal. Currently at $percentage%',
      type: 'goal',
      entityId: goalId,
      scheduledFor: DateTime.now(),
    );
  }
}
