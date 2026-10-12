import 'package:flutter/services.dart';
import 'package:parked_core/parked_core.dart';
import 'package:permission_handler/permission_handler.dart';

/// Dart side of the native background detector.
///
/// Android: Activity Recognition Transition API -> BroadcastReceiver ->
/// WorkManager job (see android/.../ParkDetection*.kt).
/// iOS: significant-location-change / CLVisit relaunch -> Core Motion history
/// (see ios/Runner/ParkDetector.swift).
/// Native code posts the "Looks like you parked" notification itself and
/// parks the result in prefs/UserDefaults; this class drains it.
class NativeBackgroundSource implements BackgroundParkSource {
  static const _channel = MethodChannel('app.parked/background');

  /// Android requires foreground location BEFORE background location, and
  /// each is a separate system prompt. Returns false if "always" is refused;
  /// detection while the app is closed will not work then.
  Future<bool> requestPermissions() async {
    await Permission.notification.request();
    await Permission.activityRecognition.request(); // Android; Core Motion on iOS
    if (!(await Permission.locationWhenInUse.request()).isGranted) return false;
    return (await Permission.locationAlways.request()).isGranted;
  }

  @override
  Future<void> start() => _channel.invokeMethod<void>('start');

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  Future<List<DetectedPark>> drainDetected() async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('drainDetected') ?? const [];
    return [
      for (final m in raw)
        DetectedPark(
          id: m['id'] as String,
          position: GeoPoint((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
          accuracyMeters: (m['accuracy'] as num?)?.toDouble(),
          parkedAt: DateTime.fromMillisecondsSinceEpoch((m['parkedAtMillis'] as num).toInt()),
        )
    ];
  }

  @override
  Future<String?> launchedFromPark() => _channel.invokeMethod<String>('launchedFromPark');
}
