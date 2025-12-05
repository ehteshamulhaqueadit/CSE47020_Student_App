import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTapped,
      );

      _initialized = true;

      // Request notification permission for Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  static void onNotificationTapped(NotificationResponse notificationResponse) {
    // This will be handled by the app's navigation
    // The payload contains routing information
    print('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> scheduleBookReminder({
    required String bookId,
    required String bookTitle,
    required DateTime dueDate,
    required int hoursBeforeDue,
  }) async {
    await initialize();

    final notificationTime = dueDate.subtract(Duration(hours: hoursBeforeDue));

    // Don't schedule if the time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      print('Notification time is in the past, not scheduling');
      return;
    }

    final notificationId = bookId.hashCode.abs();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'book_reminders',
          'Book Due Date Reminders',
          channelDescription: 'Notifications for book due dates',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'Book Due Date Reminder',
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final hoursLeft = dueDate.difference(notificationTime).inHours;
    final daysLeft = (hoursLeft / 24).floor();

    String timeLeftMessage;
    if (daysLeft > 0) {
      timeLeftMessage = '$daysLeft day${daysLeft > 1 ? 's' : ''} left';
    } else {
      timeLeftMessage = '$hoursLeft hour${hoursLeft > 1 ? 's' : ''} left';
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Book Due Date Reminder 📚',
        '$bookTitle is due in $timeLeftMessage. Tap to renew.',
        tz.TZDateTime.from(notificationTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'bookId': bookId, 'route': '/library'}),
      );

      // Save notification settings
      await _saveNotificationSettings(bookId, hoursBeforeDue);
      print('Notification scheduled for $bookTitle at $notificationTime');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelBookReminder(String bookId) async {
    final notificationId = bookId.hashCode.abs();
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    await _removeNotificationSettings(bookId);
    print('Notification cancelled for book $bookId');
  }

  Future<void> _saveNotificationSettings(
    String bookId,
    int hoursBeforeDue,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = prefs.getString('notification_settings') ?? '{}';
      final Map<String, dynamic> settingsMap = jsonDecode(settings);
      settingsMap[bookId] = hoursBeforeDue;
      await prefs.setString('notification_settings', jsonEncode(settingsMap));
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  Future<void> _removeNotificationSettings(String bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = prefs.getString('notification_settings') ?? '{}';
      final Map<String, dynamic> settingsMap = jsonDecode(settings);
      settingsMap.remove(bookId);
      await prefs.setString('notification_settings', jsonEncode(settingsMap));
    } catch (e) {
      print('Error removing notification settings: $e');
    }
  }

  Future<Map<String, int>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = prefs.getString('notification_settings') ?? '{}';
      final Map<String, dynamic> settingsMap = jsonDecode(settings);
      return settingsMap.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print('Error getting notification settings: $e');
      return {};
    }
  }

  Future<int?> getBookNotificationHours(String bookId) async {
    final settings = await getNotificationSettings();
    return settings[bookId];
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_settings');
    print('All notifications cancelled');
  }
}
