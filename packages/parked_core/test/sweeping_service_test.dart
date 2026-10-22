import 'package:parked_core/parked_core.dart';
import 'package:test/test.dart';

class FakeScheduler implements AlertScheduler {
  final scheduled = <String, DateTime>{};
  final bodies = <String, String>{};
  @override
  Future<void> cancelWhere(String p) async =>
      scheduled.removeWhere((k, _) => k.startsWith(p));
  @override
  Future<void> schedule(
      {required String key,
      required DateTime at,
      required String title,
      required String body}) async {
    scheduled[key] = at;
    bodies[key] = body;
  }
}

const geojson = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","properties":{"route_id":"R1","weekdays":[2],"weeks":[2,4],"start":"08:00","end":"10:00","skip":["2026-10-27"]},
  "geometry":{"type":"Polygon","coordinates":[[[-118.20,33.76],[-118.20,33.78],[-118.18,33.78],[-118.18,33.76],[-118.20,33.76]]]}},
 {"type":"Feature","properties":{"route_id":"R2","weekdays":[3],"start":"09:00","end":"11:00","side":"even"},
  "geometry":{"type":"MultiPolygon","coordinates":[[[[-118.30,33.80],[-118.30,33.81],[-118.29,33.81],[-118.29,33.80],[-118.30,33.80]]]]}}
]}''';

void main() {
  test('parses normalized GeoJSON (lng,lat order, weeks default, skip dates)',
      () {
    final s = parseSweepingGeoJson(geojson, cityCode: 'LB');
    expect(s, hasLength(2));
    expect(s[0].weeksOfMonth, {2, 4});
    expect(s[0].skipDates, {DateTime(2026, 10, 27)});
    expect(s[0].polygon.first, const GeoPoint(33.76, -118.20));
    expect(s[1].weeksOfMonth, {1, 2, 3, 4, 5});
    expect(s[1].side, StreetSide.even);
  });

  test('onParked schedules alerts and onDeparted cancels them', () async {
    final repo = InMemorySweepingRepository();
    await repo.replaceCity('LB', parseSweepingGeoJson(geojson, cityCode: 'LB'));
    final sched = FakeScheduler();
    final svc = SweepingAlertService(repo, sched);
    final e = ParkEvent(
      id: 'e1',
      position: const GeoPoint(33.77, -118.19),
      parkedAt: DateTime(2026, 10, 12, 20),
      source: ParkSource.auto,
      carId: 'c1',
    );
    // Mon night; next window is Tue Oct 13 8:00 -> alerts at Oct 12 20:00(12h, not after now) and Oct 13 7:00.
    final st = await svc.onParked(e, now: DateTime(2026, 10, 12, 20, 30));
    expect(st.window?.start, DateTime(2026, 10, 13, 8));
    expect(sched.scheduled.values, [DateTime(2026, 10, 13, 7)]);
    await svc.onDeparted(e);
    expect(sched.scheduled, isEmpty);
  });

  test('spot outside any polygon is unknown', () async {
    final repo = InMemorySweepingRepository();
    await repo.replaceCity('LB', parseSweepingGeoJson(geojson, cityCode: 'LB'));
    final svc = SweepingAlertService(repo, FakeScheduler());
    final e = ParkEvent(
        id: 'e',
        position: const GeoPoint(40, -100),
        parkedAt: DateTime(2026),
        source: ParkSource.manual);
    expect((await svc.statusFor(e)).isUnknown, isTrue);
  });
}
