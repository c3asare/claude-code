import 'dart:async';

import 'package:flutter_activity_recognition/flutter_activity_recognition.dart' as ar;
import 'package:parked_core/parked_core.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps the OS activity-recognition service (Android Activity Recognition,
/// iOS Core Motion) so no raw sensors are polled from Dart.
///
/// NOTE: flutter_activity_recognition delivers updates while the app process
/// is alive. Reliable background wake-up after the app is killed needs a
/// foreground service (Android) / significant-location + Visits wake (iOS).
/// That is the first spike to run on a real device; see docs/ARCHITECTURE.md.
class OsActivitySource implements ActivitySource {
  final _out = StreamController<ActivitySample>.broadcast();
  StreamSubscription<ar.Activity>? _sub;

  @override
  Stream<ActivitySample> get samples => _out.stream;

  @override
  Future<SensingPermission> requestPermissions() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) return SensingPermission.granted;
    if (status.isPermanentlyDenied) return SensingPermission.permanentlyDenied;
    if (status.isRestricted) return SensingPermission.restricted;
    return SensingPermission.denied;
  }

  @override
  Future<void> start() async {
    _sub ??= ar.FlutterActivityRecognition.instance.activityStream.listen((a) {
      _out.add(ActivitySample(_kind(a.type), _conf(a.confidence), DateTime.now()));
    });
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  ActivityKind _kind(ar.ActivityType t) => switch (t) {
        ar.ActivityType.IN_VEHICLE => ActivityKind.inVehicle,
        ar.ActivityType.WALKING => ActivityKind.walking,
        ar.ActivityType.RUNNING => ActivityKind.running,
        ar.ActivityType.ON_BICYCLE => ActivityKind.cycling,
        ar.ActivityType.STILL => ActivityKind.still,
        _ => ActivityKind.unknown,
      };

  ActivityConfidence _conf(ar.ActivityConfidence c) => switch (c) {
        ar.ActivityConfidence.HIGH => ActivityConfidence.high,
        ar.ActivityConfidence.MEDIUM => ActivityConfidence.medium,
        _ => ActivityConfidence.low,
      };
}
