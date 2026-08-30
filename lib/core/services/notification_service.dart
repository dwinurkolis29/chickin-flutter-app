import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recording_app/features/period/data/models/period_data.dart';
import 'package:recording_app/features/recording/data/models/recording_data.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Top-level background message handler for Firebase Cloud Messaging (FCM).
/// Harus berupa top-level function ber-annotasi @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pesan FCM data/notification diterima saat aplikasi di background / terminated.
  // Notifikasi bawaan Firebase OS akan otomatis ditampilkan di notification tray.
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// ID Notifikasi Khusus Pengingat Catatan Recording Harian
  static const int dailyRecordingReminderId = 8888;

  /// Key preferensi lokal Hive untuk toggle pengingat harian
  static const String dailyReminderSettingKey = 'is_daily_recording_reminder_enabled';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;

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

    // Selalu request permission lokal segera setelah initialize
    await requestPermissions();

    // ── Inisialisasi Firebase Cloud Messaging (FCM) ─────────────────────────
    await _initFirebaseMessaging();
  }

  /// Konfigurasi dan inisialisasi listener FCM
  Future<void> _initFirebaseMessaging() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // 1. Request runtime permission untuk FCM (iOS & Android 13+)
      await _messaging?.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // 2. Set foreground presentation options (iOS)
      await _messaging?.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Listener saat aplikasi berada di Foreground (Foreground push handler)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final RemoteNotification? notification = message.notification;
        if (notification != null) {
          showImmediateNotification(
            id: notification.hashCode,
            title: notification.title ?? 'BroilerKu',
            body: notification.body ?? '',
            payload: message.data.isNotEmpty ? message.data.toString() : null,
          );
        }
      });

      // 4. Listener saat notifikasi ditekan dari background oleh user
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Aksi ketika notifikasi background diketuk
      });

      // 5. Langganan otomatis ke topic broadcast umum peternak
      if (!kIsWeb) {
        try {
          await _messaging?.subscribeToTopic('all_farmers');
        } catch (_) {}
      }
    } catch (_) {
      // Graceful fallback jika FCM gagal diinisialisasi
    }
  }

  /// Mengambil FCM Device Token untuk pengiriman notifikasi terarah
  Future<String?> getFcmToken() async {
    try {
      _messaging ??= FirebaseMessaging.instance;
      return await _messaging?.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Stream listener ketika FCM token diperbarui
  Stream<String>? get onTokenRefresh => _messaging?.onTokenRefresh;

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
    try {
      await _notifications.cancel(id);
    } catch (_) {}
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (_) {}
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _notifications.pendingNotificationRequests();
      return pendingNotifications;
    } catch (_) {
      return [];
    }
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
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
    } catch (_) {}
  }

  /// Status apakah pengingat catatan harian aktif dari preferensi lokal peternak
  bool isDailyReminderEnabled() {
    try {
      if (!Hive.isBoxOpen('settings')) return true;
      final box = Hive.box('settings');
      return box.get(dailyReminderSettingKey, defaultValue: true) as bool;
    } catch (_) {
      return true;
    }
  }

  /// Mengubah status aktif pengingat catatan harian
  Future<void> setDailyReminderEnabled(bool enabled) async {
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        await box.put(dailyReminderSettingKey, enabled);
      }
      if (!enabled) {
        await cancelNotification(dailyRecordingReminderId);
      }
    } catch (_) {}
  }

  /// Menjadwalkan / menyesuaikan pengingat harian cerdas secara otomatis
  /// berdasarkan status periode aktif dan pencatatan recording hari ini.
  Future<void> syncDailyRecordingReminder({
    required PeriodData? activePeriod,
    required List<RecordingData> recordings,
    int reminderHour = 19,
    int reminderMinute = 0,
  }) async {
    try {
      // 0. Jika peternak mematikan toggle notifikasi pengingat, batalkan pengingat
      if (!isDailyReminderEnabled()) {
        await cancelNotification(dailyRecordingReminderId);
        return;
      }

      // 1. Jika tidak ada periode yang aktif, batalkan pengingat
      if (activePeriod == null || !activePeriod.isActive) {
        await cancelNotification(dailyRecordingReminderId);
        return;
      }

      // 2. Hitung umur hari ayam hari ini
      final startDate = activePeriod.startDate;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final periodStart = DateTime(startDate.year, startDate.month, startDate.day);
      final int currentAgeDays = todayStart.difference(periodStart).inDays + 1;

      // Jika periode baru dimulai di masa depan
      if (currentAgeDays < 1) {
        await cancelNotification(dailyRecordingReminderId);
        return;
      }

      // 3. Periksa apakah recording hari ini sudah terisi
      final bool isTodayRecorded = recordings.any((rec) => rec.day == currentAgeDays);

      // 4. Tentukan target jadwal pengingat
      DateTime scheduledDateTime;
      int targetAgeDays;

      if (isTodayRecorded) {
        // Jika hari ini sudah terisi, jadwalkan untuk besok pukul reminderHour:reminderMinute
        final tomorrow = now.add(const Duration(days: 1));
        scheduledDateTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          reminderHour,
          reminderMinute,
        );
        targetAgeDays = currentAgeDays + 1;
      } else {
        // Jika hari ini belum terisi, target adalah hari ini pukul reminderHour:reminderMinute
        scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderHour,
          reminderMinute,
        );
        targetAgeDays = currentAgeDays;

        // Jika waktu hari ini sudah lewat (misal sekarang 20:00)
        if (scheduledDateTime.isBefore(now)) {
          // Jika belum larut malam (< 22:00), jadwalkan 15 detik dari sekarang untuk pengingat malam ini
          if (now.hour < 22) {
            scheduledDateTime = now.add(const Duration(seconds: 15));
          } else {
            // Jika sudah larut malam, jadwalkan besok
            final tomorrow = now.add(const Duration(days: 1));
            scheduledDateTime = DateTime(
              tomorrow.year,
              tomorrow.month,
              tomorrow.day,
              reminderHour,
              reminderMinute,
            );
            targetAgeDays = currentAgeDays + 1;
          }
        }
      }

      final title = 'Waktunya Catat Recording Harian 🐔';
      final body = 'Siklus ${activePeriod.name} hari ke-$targetAgeDays belum diisi. Yuk catat pakan & bobot ayam hari ini!';

      // Convert DateTime to TZDateTime
      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'broiler_recording_reminder',
        'Pengingat Recording Harian',
        channelDescription: 'Channel pengingat pencatatan harian pakan dan bobot ayam BroilerKu',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
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

      // Batalkan jadwal sebelumnya terlebih dahulu
      await cancelNotification(dailyRecordingReminderId);

      // Jadwalkan notifikasi baru
      final tzNow = tz.TZDateTime.now(tz.local);
      if (scheduledTZDate.isAfter(tzNow)) {
        await _notifications.zonedSchedule(
          dailyRecordingReminderId,
          title,
          body,
          scheduledTZDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'daily_recording_${activePeriod.id}',
        );
      }
    } catch (_) {
      // Graceful fallback jika timezone atau platform channel belum terpasang di test environment
    }
  }
}