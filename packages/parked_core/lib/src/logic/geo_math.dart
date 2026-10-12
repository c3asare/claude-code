import '../models/geo_point.dart';

/// Ray-casting point-in-polygon. Fine at city scale (planar approximation).
bool pointInPolygon(GeoPoint p, List<GeoPoint> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i], b = ring[j];
    final crosses = (a.lat > p.lat) != (b.lat > p.lat) &&
        p.lng < (b.lng - a.lng) * (p.lat - a.lat) / (b.lat - a.lat) + a.lng;
    if (crosses) inside = !inside;
  }
  return inside;
}
