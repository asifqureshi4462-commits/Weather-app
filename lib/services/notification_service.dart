import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _dailySummaryId = 1001;
  static const int _alertNotificationId = 2001;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped payload: ${response.payload}');
        },
      );

      _isInitialized = true;
      await requestPermissions();
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();
        if (status.isGranted) return true;

        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImplementation?.requestNotificationsPermission();
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    if (!_isInitialized) await init();

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'weather_alerts_channel',
        'Severe Weather & Instant Alerts',
        channelDescription: 'Immediate notifications for weather alerts and warnings',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        id ?? _alertNotificationId,
        title,
        body,
        platformDetails,
      );
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }

  Future<void> scheduleDailyMorningSummary({
    required int hour,
    required int minute,
    required String cityName,
    required String condition,
    required String tempText,
    required String rainChanceText,
  }) async {
    if (!_isInitialized) await init();

    try {
      await cancelDailySummary();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_morning_summary_channel',
        'Daily Morning Weather Summary',
        channelDescription: 'Daily scheduled morning forecast for your favorite location',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

      await _notificationsPlugin.zonedSchedule(
        _dailySummaryId,
        'Morning Weather Summary • $cityName',
        'Today in $cityName: $tempText, $condition. $rainChanceText.',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Scheduled daily weather notification for $hour:$minute at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling daily morning summary: $e');
      // Fallback to periodic daily show if zonedSchedule exact alarm is restricted
      try {
        await _notificationsPlugin.periodicallyShow(
          _dailySummaryId,
          'Morning Weather Summary • $cityName',
          'Today in $cityName: $tempText, $condition. $rainChanceText.',
          RepeatInterval.daily,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_morning_summary_channel',
              'Daily Morning Weather Summary',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (err) {
        debugPrint('Periodic notification fallback error: $err');
      }
    }
  }

  Future<void> cancelDailySummary() async {
    try {
      await _notificationsPlugin.cancel(_dailySummaryId);
    } catch (e) {
      debugPrint('Error cancelling daily summary: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
