// MOBILE ONLY: the one place that wires OS sensing into core. Imported solely
// by main_mobile.dart. test/layering_test.dart enforces this.
import 'dart:async';

import 'package:parked_core/parked_core.dart';
import 'package:parked_sensing/parked_sensing.dart';
import 'package:uuid/uuid.dart';

class MobileDetector {
  MobileDetector(this._repo, {OsActivitySource? activity, GeolocatorLocationSource? location})
      : _activity = activity ?? OsActivitySource(),
        _location = location ?? GeolocatorLocationSource();

  final ParkingRepository _repo;
  final OsActivitySource _activity;
  final GeolocatorLocationSource _location;
  final _engine = ParkTransitionEngine();
  StreamSubscription<ActivitySample>? _sub;
  Timer? _tick;

  Future<SensingPermission> start() async {
    final perm = await _activity.requestPermissions();
    if (perm != SensingPermission.granted) return perm;
    await _activity.start();
    _sub = _activity.samples.listen((s) => _handle(_engine.onSample(s)));
    _tick = Timer.periodic(const Duration(seconds: 15), (_) => _handle(_engine.onTick(DateTime.now())));
    return perm;
  }

  Future<void> stop() async {
    _tick?.cancel();
    await _sub?.cancel();
    await _activity.stop();
  }

  Future<void> _handle(ParkSignal? signal) async {
    if (signal == null) return;
    // One-shot fix at the moment of confirmation; no continuous GPS.
    final fix = await _location.currentFix();
    if (fix == null) return;
    await _repo.saveEvent(ParkEvent(
      id: const Uuid().v4(),
      position: fix.point,
      accuracyMeters: fix.accuracyMeters,
      parkedAt: signal.parkedAt,
      source: ParkSource.auto,
    ));
  }
}
