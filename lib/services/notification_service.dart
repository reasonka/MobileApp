import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';

/// Singleton wrapper around flutter_local_notifications.
/// Mirrors the style of SoundService — one shared instance, init once in main().
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _eventChannelId = 'event_reminders';
  static const String _eventChannelName = 'Event Reminders';
  static const String _eventChannelDesc =
      'Reminders for upcoming calendar events';

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const androidChannel = AndroidNotificationChannel(
      _eventChannelId,
      _eventChannelName,
      description: _eventChannelDesc,
      importance: Importance.high,
    );

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Call this from a user-driven action (e.g. tapping "enable reminders"),
  /// not automatically on app start, per Android 13+ / iOS guidance.
  Future<bool> requestPermissions() async {
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidImpl?.requestNotificationsPermission() ?? true;

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidGranted && iosGranted;
  }

  /// Deterministic int ID from a Firestore doc id string, since the plugin
  /// needs an int id per notification. Two events will essentially never collide.
  int idFromEventId(String eventId) => eventId.hashCode & 0x7FFFFFFF;

  Future<void> scheduleReminder({
    required String eventId,
    required String eventTitle,
    required DateTime fireAt,
  }) async {
    if (!_initialized) await init();

    // Never schedule for a time that's already passed.
    if (fireAt.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      idFromEventId(eventId),
      'Upcoming event',
      eventTitle,
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _eventChannelId,
          _eventChannelName,
          channelDescription: _eventChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(String eventId) async {
    if (!_initialized) await init();
    await _plugin.cancel(idFromEventId(eventId));
  }

  /// DEV-ONLY: fires a notification immediately, bypassing scheduling,
  /// so you can verify permissions/wiring work on a real device.
  /// Do not ship a button calling this to production users.
  Future<void> debugFireTestNotification({String? eventTitle}) async {
    if (!_initialized) await init();
    debugPrint('🔔 debugFireTestNotification called, initialized=$_initialized');
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await androidImpl?.areNotificationsEnabled();
    debugPrint('🔔 areNotificationsEnabled=$enabled');
    await _plugin.show(
      999999,
      'Test reminder',
      eventTitle ?? 'This is a simulated notification',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _eventChannelId,
          _eventChannelName,
          channelDescription: _eventChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}