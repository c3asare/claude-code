import 'package:parked_core/parked_core.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime(2026, 10, 12, 8);
  ActivitySample s(ActivityKind k, int sec,
          [ActivityConfidence c = ActivityConfidence.high]) =>
      ActivitySample(k, c, t0.add(Duration(seconds: sec)));

  group('ParkTransitionEngine', () {
    test('drive then sustained walking emits park at last vehicle time', () {
      final e = ParkTransitionEngine();
      expect(e.onSample(s(ActivityKind.inVehicle, 0)), isNull);
      expect(e.onSample(s(ActivityKind.walking, 60)), isNull);
      final sig = e.onTick(t0.add(const Duration(seconds: 90)));
      expect(sig?.parkedAt, t0);
    });

    test('red light (brief still) does not emit', () {
      final e = ParkTransitionEngine();
      e.onSample(s(ActivityKind.inVehicle, 0));
      e.onSample(s(ActivityKind.still, 10));
      expect(e.onTick(t0.add(const Duration(seconds: 100))), isNull);
      e.onSample(s(ActivityKind.inVehicle, 110));
      expect(e.onTick(t0.add(const Duration(minutes: 10))), isNull);
    });

    test('long still after driving emits', () {
      final e = ParkTransitionEngine();
      e.onSample(s(ActivityKind.inVehicle, 0));
      e.onSample(s(ActivityKind.still, 5));
      expect(e.onTick(t0.add(const Duration(minutes: 4))), isNotNull);
    });
  });

  group('SweepingPlanner', () {
    // 2nd and 4th Tuesday, 8-10am.
    final sched = SweepingSchedule(
      id: 'x',
      cityCode: 'LA',
      routeId: '1A',
      weekdays: {DateTime.tuesday},
      weeksOfMonth: {2, 4},
      startMinute: 8 * 60,
      endMinute: 10 * 60,
    );
    const planner = SweepingPlanner();

    test('finds next 2nd/4th Tuesday', () {
      // Mon 2026-10-12 -> Tue Oct 13 is week 2.
      final w = planner.nextWindow(sched, DateTime(2026, 10, 12, 12));
      expect(w?.start, DateTime(2026, 10, 13, 8));
    });

    test('skips holidays', () {
      final s2 = SweepingSchedule(
        id: 'y',
        cityCode: 'LA',
        routeId: '1A',
        weekdays: {DateTime.tuesday},
        weeksOfMonth: {2, 4},
        startMinute: 480,
        endMinute: 600,
        skipDates: {DateTime(2026, 10, 13)},
      );
      expect(planner.nextWindow(s2, DateTime(2026, 10, 12))?.start,
          DateTime(2026, 10, 27, 8));
    });

    test('alert times drop past instants', () {
      final a = planner.alertTimes(sched, DateTime(2026, 10, 13, 6));
      expect(a, [DateTime(2026, 10, 13, 7)]);
    });
  });

  test('pointInPolygon', () {
    const ring = [
      GeoPoint(0, 0),
      GeoPoint(0, 2),
      GeoPoint(2, 2),
      GeoPoint(2, 0)
    ];
    expect(pointInPolygon(const GeoPoint(1, 1), ring), isTrue);
    expect(pointInPolygon(const GeoPoint(3, 1), ring), isFalse);
  });
}
