import 'dart:convert';

import '../models/geo_point.dart';
import '../models/sweeping_schedule.dart';

/// Parses Parked's normalized sweeping format. Per-city converters (LA ArcGIS,
/// Long Beach, ...) must emit this shape, so the app never depends on a
/// municipality's raw schema.
///
/// FeatureCollection; each Feature has Polygon or MultiPolygon geometry and
/// properties:
///   route_id : string
///   weekdays : [1..7]   (1 = Monday)
///   weeks    : [1..5]   (omit = every week)
///   start,end: "HH:MM" local
///   side     : optional StreetSide name
///   skip     : optional ["YYYY-MM-DD", ...] holiday suspensions
///   updated  : optional ISO date of the source data
List<SweepingSchedule> parseSweepingGeoJson(String json, {required String cityCode}) {
  final root = jsonDecode(json) as Map<String, dynamic>;
  final out = <SweepingSchedule>[];
  for (final f in (root['features'] as List).cast<Map<String, dynamic>>()) {
    final props = (f['properties'] as Map).cast<String, dynamic>();
    final geom = (f['geometry'] as Map).cast<String, dynamic>();
    final polygons = switch (geom['type']) {
      'Polygon' => [geom['coordinates'] as List],
      'MultiPolygon' => (geom['coordinates'] as List).cast<List>(),
      _ => const <List>[],
    };
    final routeId = props['route_id'].toString();
    for (var i = 0; i < polygons.length; i++) {
      final outer = (polygons[i].first as List)
          .map((c) => GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble())) // GeoJSON is [lng, lat]
          .toList();
      out.add(SweepingSchedule(
        id: '$cityCode:$routeId:$i',
        cityCode: cityCode,
        routeId: routeId,
        weekdays: (props['weekdays'] as List).cast<int>().toSet(),
        weeksOfMonth: props['weeks'] == null
            ? const {1, 2, 3, 4, 5}
            : (props['weeks'] as List).cast<int>().toSet(),
        startMinute: _minutes(props['start'] as String),
        endMinute: _minutes(props['end'] as String),
        side: StreetSide.values.firstWhere(
          (s) => s.name == props['side'],
          orElse: () => StreetSide.both,
        ),
        skipDates: {
          for (final d in (props['skip'] as List? ?? const []))
            DateTime.parse(d as String),
        },
        polygon: outer,
        sourceUpdatedAt: props['updated'] == null ? null : DateTime.parse(props['updated'] as String),
      ));
    }
  }
  return out;
}

int _minutes(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}
