import '../models/geo_point.dart';

/// A park detected by native code while the Flutter app was not running.
class DetectedPark {
  const DetectedPark({
    required this.id,
    required this.position,
    required this.parkedAt,
    this.accuracyMeters,
  });
  final String id;
  final GeoPoint position;
  final double? accuracyMeters;
  final DateTime parkedAt;
}

/// Native, OS-woken detection (Android Transition API receiver, iOS
/// significant-location/Visits). Native code posts the notification and
/// stores a pending record; Dart drains it when the app next runs.
abstract interface class BackgroundParkSource {
  /// Registers OS callbacks. Safe to call on every launch.
  Future<void> start();
  Future<void> stop();

  /// Returns and clears parks detected while the app was not running.
  Future<List<DetectedPark>> drainDetected();

  /// Notification id of the tap that launched the app, if any.
  Future<String?> launchedFromPark();
}
