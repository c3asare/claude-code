import '../models/geo_point.dart';

class LocationFix {
  const LocationFix(this.point, this.accuracyMeters, this.at);
  final GeoPoint point;
  final double accuracyMeters;
  final DateTime at;
}

abstract interface class LocationSource {
  /// One-shot fix; null on timeout or denied permission.
  Future<LocationFix?> currentFix({Duration timeout = const Duration(seconds: 15)});
  Future<LocationFix?> lastKnown();
}
