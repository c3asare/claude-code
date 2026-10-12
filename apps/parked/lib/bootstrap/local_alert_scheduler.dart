// MOBILE ONLY: imported solely by main_mobile.dart.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:parked_core/parked_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules sweeping reminders as local notifications. The notifications
/// plugin must already be initialized (LocalParkNotifier.init does that).
///
/// Uses inexact scheduling so no exact-alarm permission is needed; Android may
/// delay a reminder by a few minutes in Doze. Revisit if that proves too loose
/// for the 1-hour alert.
class LocalAlertScheduler implements AlertScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'sweeping_alerts',
      'Street sweeping alerts',
      channelDescription: 'Reminders to move your car before sweeping',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive),
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(
        tz.getLocation(await FlutterTimezone.getLocalTimezone()));
  }

  int _id(String key) => key.hashCode & 0x7fffffff;

  @override
  Future<void> schedule({
    required String key,
    required DateTime at,
    required String title,
    required String body,
  }) =>
      _plugin.zonedSchedule(
        _id(key),
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: key,
      );

  @override
  Future<void> cancelWhere(String keyPrefix) async {
    for (final r in await _plugin.pendingNotificationRequests()) {
      if (r.payload?.startsWith(keyPrefix) ?? false) await _plugin.cancel(r.id);
    }
  }
}
