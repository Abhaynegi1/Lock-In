import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _timerNotificationId = 101;
  static const int _completeNotificationId = 102;
  static const String _timerChannelId = 'lockin_focus_timer';
  static const String _completeChannelId = 'lockin_session_complete';

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);

    // Request permissions on Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> updateTimerNotification({
    required String timeRemaining,
    required String title,
    bool isBattle = false,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _timerChannelId,
      'Active Focus Timer',
      channelDescription: 'Shows remaining time for your active focus session',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      icon: '@mipmap/launcher_icon',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id: _timerNotificationId,
      title: '⏳ $timeRemaining · $title',
      body: isBattle ? 'Focus battle in progress' : 'Focus session in progress',
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showSessionCompleteNotification({
    required String title,
    required String body,
  }) async {
    await cancelTimerNotification();

    const androidDetails = AndroidNotificationDetails(
      _completeChannelId,
      'Session Completion',
      channelDescription: 'Alerts when a focus session finishes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id: _completeNotificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> cancelTimerNotification() async {
    await _notificationsPlugin.cancel(id: _timerNotificationId);
  }
}
