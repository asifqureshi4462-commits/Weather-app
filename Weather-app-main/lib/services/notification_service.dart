import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _dailySummaryId = 1001;
  static const int _alertNotificationId = 2001;

  static const String _alertChannelId = 'weather_alerts_channel';
  static const String _dailyChannelId = 'daily_morning_summary_channel';
  static const String _statusIcon = 'ic_stat_weather';

  /// Initializes the plugin. Does NOT ask for permission (the UI does that with a friendly dialog).
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();
      _configureLocalTimezone();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped payload: ${response.payload}');
        },
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _alertChannelId,
        'Severe Weather & Instant Alerts',
        description: 'Immediate notifications for weather alerts and warnings',
        importance: Importance.max,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _dailyChannelId,
        'Daily Morning Weather Summary',
        description: 'Daily scheduled morning forecast for your location',
        importance: Importance.high,
      ));

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// The timezone package defaults to UTC. Match the device's real offset so the
  /// daily summary fires at the correct local time.
  void _configureLocalTimezone() {
    try {
      final now = DateTime.now();
      final offsetMs = now.timeZoneOffset.inMilliseconds;
      final nowMs = now.millisecondsSinceEpoch;
      final abbreviation = now.timeZoneName;

      tz.Location? offsetMatch;
      for (final location in tz.timeZoneDatabase.locations.values) {
        final zone = location.timeZone(nowMs);
        if (zone.offset != offsetMs) continue;
        offsetMatch ??= location;
        if (zone.abbreviation == abbreviation) {
          offsetMatch = location;
          break;
        }
      }
      if (offsetMatch != null) tz.setLocalLocation(offsetMatch);
    } catch (e) {
      debugPrint('Timezone configuration fallback to UTC: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await android?.areNotificationsEnabled();
        if (enabled != null) return enabled;
      }
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPermanentlyDenied() async {
    try {
      return await Permission.notification.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system notification permission prompt (Android 13+ / iOS).
  Future<bool> requestPermissions() async {
    try {
      if (!_isInitialized) await init();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        if (granted == true) return true;
        return await areNotificationsEnabled();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
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

    final notificationId = id ?? _alertNotificationId;

    NotificationDetails details(String? icon) => NotificationDetails(
          android: AndroidNotificationDetails(
            _alertChannelId,
            'Severe Weather & Instant Alerts',
            channelDescription: 'Immediate notifications for weather alerts and warnings',
            importance: Importance.max,
            priority: Priority.high,
            icon: icon,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
        );

    try {
      await _plugin.show(notificationId, title, body, details(_statusIcon));
    } catch (e) {
      debugPrint('Notification with custom icon failed ($e), retrying with default icon.');
      try {
        await _plugin.show(notificationId, title, body, details(null));
      } catch (err) {
        debugPrint('Error showing immediate notification: $err');
      }
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

    final title = 'Morning Weather Summary • $cityName';
    final body = 'Today in $cityName: $tempText, $condition. $rainChanceText.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyChannelId,
        'Daily Morning Weather Summary',
        channelDescription: 'Daily scheduled morning forecast for your location',
        importance: Importance.high,
        priority: Priority.high,
        icon: _statusIcon,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    try {
      await cancelDailySummary();

      final scheduledDate = _nextInstanceOfTime(hour, minute);

      // "inexact" scheduling needs no special exact-alarm permission, so it never crashes on Android 12+.
      await _plugin.zonedSchedule(
        _dailySummaryId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Scheduled daily weather notification for $hour:$minute at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling daily morning summary: $e');
      try {
        await _plugin.periodicallyShow(
          _dailySummaryId,
          title,
          body,
          RepeatInterval.daily,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (err) {
        debugPrint('Periodic notification fallback error: $err');
      }
    }
  }

  Future<void> cancelDailySummary() async {
    try {
      await _plugin.cancel(_dailySummaryId);
    } catch (e) {
      debugPrint('Error cancelling daily summary: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
