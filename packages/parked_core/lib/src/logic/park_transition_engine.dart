import '../models/activity_sample.dart';

/// Emitted when a drive has ended. [parkedAt] is the last time the OS still
/// reported the vehicle, which is a better park timestamp than "now".
class ParkSignal {
  const ParkSignal(this.parkedAt);
  final DateTime parkedAt;
}

/// Turns OS activity transitions into a debounced "you parked" signal.
/// Pure and clock-free: callers feed samples and periodic ticks, so it is
/// unit-testable and identical on every platform.
class ParkTransitionEngine {
  ParkTransitionEngine({
    this.walkConfirm = const Duration(seconds: 20),
    this.stillConfirm = const Duration(minutes: 3),
    this.minConfidence = ActivityConfidence.medium,
  });

  /// Walking after driving is a strong signal; confirm quickly.
  final Duration walkConfirm;

  /// Stationary-in-vehicle looks identical to a red light; wait longer.
  final Duration stillConfirm;
  final ActivityConfidence minConfidence;

  DateTime? _lastVehicleAt;
  DateTime? _leftVehicleAt;
  ActivityKind? _leftKind;

  ParkSignal? onSample(ActivitySample s) {
    if (s.confidence.index < minConfidence.index) return onTick(s.at);
    switch (s.kind) {
      case ActivityKind.inVehicle:
        _lastVehicleAt = s.at;
        _leftVehicleAt = null;
        _leftKind = null;
      case ActivityKind.still:
      case ActivityKind.walking:
      case ActivityKind.onFoot:
      case ActivityKind.running:
        if (_lastVehicleAt != null && _leftVehicleAt == null) {
          _leftVehicleAt = s.at;
          _leftKind = s.kind;
        }
      case ActivityKind.cycling:
      case ActivityKind.unknown:
        break;
    }
    return onTick(s.at);
  }

  /// Call on a timer too: platforms emit on change only, so "still for 3
  /// minutes" produces no new sample.
  ParkSignal? onTick(DateTime now) {
    final left = _leftVehicleAt, last = _lastVehicleAt;
    if (left == null || last == null) return null;
    final needed = _leftKind == ActivityKind.still ? stillConfirm : walkConfirm;
    if (now.difference(left) < needed) return null;
    _lastVehicleAt = _leftVehicleAt = _leftKind = null;
    return ParkSignal(last);
  }
}
