import 'geo_point.dart';

enum StreetSide { both, even, odd, north, south, east, west }

/// One posted sweeping rule for a route. Times are wall-clock in the city's
/// local zone (no tz math in core; callers pass local DateTimes).
class SweepingSchedule {
  const SweepingSchedule({
    required this.id,
    required this.cityCode,
    required this.routeId,
    required this.weekdays,
    required this.startMinute,
    required this.endMinute,
    this.weeksOfMonth = const {1, 2, 3, 4, 5},
    this.side = StreetSide.both,
    this.skipDates = const {},
    this.polygon = const [],
    this.sourceUpdatedAt,
  });

  final String id;

  /// e.g. 'LA', 'LB'. Keys the per-city data pipeline.
  final String cityCode;
  final String routeId;

  /// DateTime.monday..DateTime.sunday
  final Set<int> weekdays;

  /// 1-based week of month the weekday falls in (1..5). All weeks = weekly.
  final Set<int> weeksOfMonth;
  final int startMinute; // minutes after local midnight
  final int endMinute;
  final StreetSide side;

  /// Holiday suspensions, as local dates (time-of-day ignored).
  final Set<DateTime> skipDates;

  /// Outer ring only; enough for point-in-polygon lookup.
  final List<GeoPoint> polygon;
  final DateTime? sourceUpdatedAt;
}
