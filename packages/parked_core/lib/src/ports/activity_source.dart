import '../models/activity_sample.dart';

enum SensingPermission { granted, denied, permanentlyDenied, restricted }

/// Port implemented by the mobile-only sensing layer. Core never knows which
/// OS API sits behind it.
abstract interface class ActivitySource {
  Stream<ActivitySample> get samples;
  Future<SensingPermission> requestPermissions();
  Future<void> start();
  Future<void> stop();
}
