// MOBILE ONLY: imported solely by main_mobile.dart.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parked_core/parked_core.dart';

/// Posts "Looks like you parked" as a system notification, so it appears
/// whether the app is foreground, backgrounded, or woken headlessly.
/// Tapping opens the app, where MapPage shows the "Which car is this?" sheet
/// for the pending event. Unconfirmed pending events never appear on the map.
class LocalParkNotifier implements ParkNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'park_detected',
      'Parking detected',
      channelDescription: 'Asks whether to save where you parked',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
  );

  @override
  Future<void> init() async {
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
    // Android 13+ runtime permission.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> promptParked(ParkEvent pending) => _plugin.show(
        pending.id.hashCode,
        'Looks like you parked',
        'Tap to save this spot and pick your car.',
        _details,
        payload: pending.id,
      );
}
