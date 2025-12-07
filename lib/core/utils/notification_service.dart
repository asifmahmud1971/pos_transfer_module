import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request notification permission
    await Permission.notification.request();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to transfer dashboard
    // This will be handled by the app's navigation system
  }

  Future<void> showTransferNotification({
    required String id,
    required String title,
    required String body,
    int progress = 0,
    bool showProgress = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'transfer_channel',
      'File Transfers',
      channelDescription: 'Notifications for file uploads and downloads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: showProgress,
      maxProgress: 100,
      progress: progress,
      ongoing: showProgress,
      autoCancel: !showProgress,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id.hashCode,
      title,
      body,
      details,
    );
  }

  Future<void> showCompletionNotification({
    required String id,
    required String title,
    required String body,
    bool isSuccess = true,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'transfer_complete_channel',
      'Transfer Complete',
      channelDescription: 'Notifications when transfers complete',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id.hashCode,
      title,
      body,
      details,
    );
  }

  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}