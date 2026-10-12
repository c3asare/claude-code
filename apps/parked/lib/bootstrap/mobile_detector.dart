// MOBILE ONLY: the one place that wires OS sensing into core. Imported solely
// by main_mobile.dart. test/layering_test.dart enforces this.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:parked_core/parked_core.dart';
import 'package:parked_sensing/parked_sensing.dart';
import 'package:uuid/uuid.dart';

/// Two detection paths feed the same pending-event pipeline:
///  1. Foreground: OS activity stream -> ParkTransitionEngine -> one GPS fix
///     -> pending event + notification.
///  2. Background: native code (app closed) detects, notifies and stores the
///     park; we drain it on launch and every resume.
/// Duplicates (both paths firing for one park) are dropped by [_isDuplicate].
class MobileDetector with WidgetsBindingObserver {
  MobileDetector(
    this._repo,
    this._notifier, {
    OsActivitySource? activity,
    GeolocatorLocationSource? location,
    NativeBackgroundSource? background,
  })  : _activity = activity ?? OsActivitySource(),
        _location = location ?? GeolocatorLocationSource(),
        _background = background ?? NativeBackgroundSource();

  final ParkingRepository _repo;
  final ParkNotifier _notifier;
  final OsActivitySource _activity;
  final GeolocatorLocationSource _location;
  final NativeBackgroundSource _background;
  final _engine = ParkTransitionEngine();
  StreamSubscription<ActivitySample>? _sub;
  Timer? _tick;

  /// Whether the OS granted "always" location (needed for closed-app detection).
  bool backgroundEnabled = false;

  Future<SensingPermission> start() async {
    final perm = await _activity.requestPermissions();
    if (perm != SensingPermission.granted) return perm;

    backgroundEnabled = await _background.requestPermissions();
    if (backgroundEnabled) {
      try {
        await _background.start();
      } on Exception {
        backgroundEnabled = false; // native side not present (e.g. tests)
      }
    }

    await _activity.start();
    _sub = _activity.samples.listen((s) => _handle(_engine.onSample(s)));
    _tick = Timer.periodic(const Duration(seconds: 15),
        (_) => _handle(_engine.onTick(DateTime.now())));

    WidgetsBinding.instance.addObserver(this);
    await drainBackground();
    return perm;
  }

  Future<void> stop() async {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    await _sub?.cancel();
    await _activity.stop();
    if (backgroundEnabled) await _background.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) drainBackground();
  }

  Future<void> drainBackground() async {
    if (!backgroundEnabled) return;
    for (final d in await _background.drainDetected()) {
      await _savePending(d.id, d.position, d.accuracyMeters, d.parkedAt,
          notify: false);
    }
  }

  Future<void> _handle(ParkSignal? signal) async {
    if (signal == null) return;
    // One-shot fix at the moment of confirmation; no continuous GPS.
    final fix = await _location.currentFix();
    if (fix == null) return;
    await _savePending(
        const Uuid().v4(), fix.point, fix.accuracyMeters, signal.parkedAt,
        notify: true);
  }

  Future<void> _savePending(
    String id,
    GeoPoint position,
    double? accuracy,
    DateTime parkedAt, {
    required bool notify,
  }) async {
    if (await _isDuplicate(parkedAt)) return;
    final pending = ParkEvent(
      id: id,
      position: position,
      accuracyMeters: accuracy,
      parkedAt: parkedAt,
      source: ParkSource.auto,
    );
    await _repo.saveEvent(pending);
    if (notify) await _notifier.promptParked(pending);
  }

  Future<bool> _isDuplicate(DateTime parkedAt) async {
    final open = await _repo.watchOpenEvents().first;
    return open.any((e) =>
        e.parkedAt.difference(parkedAt).abs() < const Duration(minutes: 5));
  }
}
