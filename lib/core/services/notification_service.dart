import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Initialize notification service
  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS: jangan rely pada requestAlertPermission di sini untuk v17+
    // Permission diminta eksplisit via requestPermissions() di bawah
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Selalu request permission segera setelah initialize
    await requestPermissions();
  }

  // Request permission — iOS dan Android 13+ (runtime)
  Future<bool> requestPermissions() async {
    // iOS
    final bool? iosResult = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ (API 33+) butuh runtime permission POST_NOTIFICATIONS
    final bool? androidResult = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();


    return (iosResult ?? true) && (androidResult ?? true);
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to reminder detail page
    // You can pass reminder ID via payload

  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Convert DateTime to TZDateTime
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Android notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'broiler_notification_channel', // channel ID
      'Notifikasi BroilerKu', // channel name
      channelDescription: 'Channel notifikasi otomatis BroilerKu',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combine notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Guard: jangan schedule jika waktu sudah lewat
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledTZDate.isBefore(now)) {
      return;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
    await _notifications.pendingNotificationRequests();
    return pendingNotifications;
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'broiler_notification_channel',
      'Notifikasi BroilerKu',
      channelDescription: 'Channel notifikasi otomatis BroilerKu',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );


  }
}