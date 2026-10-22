import 'package:geolocator/geolocator.dart';
import 'package:parked_core/parked_core.dart';

/// One-shot fixes only. We never stream GPS; the activity engine decides
/// when a fix is worth the battery.
class GeolocatorLocationSource implements LocationSource {
  @override
  Future<LocationFix?> currentFix(
      {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: timeout),
      );
      return _fix(p);
    } catch (_) {
      return lastKnown();
    }
  }

  @override
  Future<LocationFix?> lastKnown() async {
    final p = await Geolocator.getLastKnownPosition();
    return p == null ? null : _fix(p);
  }

  LocationFix _fix(Position p) =>
      LocationFix(GeoPoint(p.latitude, p.longitude), p.accuracy, p.timestamp);
}
