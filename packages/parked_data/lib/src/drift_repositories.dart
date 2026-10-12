import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:parked_core/parked_core.dart';

import 'database.dart';

int _maskOf(Iterable<int> values, int base) =>
    values.fold(0, (m, v) => m | (1 << (v - base)));

Set<int> _setOf(int mask, int base, int count) =>
    {for (var i = 0; i < count; i++) if (mask & (1 << i) != 0) i + base};

class DriftParkingRepository implements ParkingRepository {
  DriftParkingRepository(this._db);
  final AppDatabase _db;

  Car _car(CarRow r) => Car(
        id: r.id,
        name: r.name,
        colorValue: r.colorValue,
        accentColorValue: r.accentColorValue,
        bodyStyle: CarBodyStyle.values[r.bodyStyle.clamp(0, CarBodyStyle.values.length - 1)],
        createdAt: r.createdAt,
        make: r.make,
        model: r.model,
        plate: r.plate,
      );

  ParkEvent _event(ParkEventRow r) => ParkEvent(
        id: r.id,
        carId: r.carId,
        position: GeoPoint(r.lat, r.lng),
        accuracyMeters: r.accuracyMeters,
        parkedAt: r.parkedAt,
        departedAt: r.departedAt,
        source: ParkSource.values[r.source],
        address: r.address,
        notes: r.notes,
        sweepingScheduleId: r.sweepingScheduleId,
      );

  @override
  Stream<List<Car>> watchCars() =>
      (_db.select(_db.cars)..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
          .watch()
          .map((rows) => rows.map(_car).toList());

  @override
  Future<void> saveCar(Car c) => _db.into(_db.cars).insertOnConflictUpdate(CarsCompanion.insert(
        id: c.id,
        name: c.name,
        colorValue: c.colorValue,
        createdAt: c.createdAt,
        bodyStyle: Value(c.bodyStyle.index),
        accentColorValue: Value(c.accentColorValue),
        make: Value(c.make),
        model: Value(c.model),
        plate: Value(c.plate),
      ));

  @override
  Future<void> deleteCar(String id) async {
    await _db.transaction(() async {
      // Keep history but detach it; pending/active events for this car close.
      await (_db.update(_db.parkEvents)..where((e) => e.carId.equals(id) & e.departedAt.isNull()))
          .write(ParkEventsCompanion(departedAt: Value(DateTime.now())));
      await (_db.update(_db.parkEvents)..where((e) => e.carId.equals(id)))
          .write(const ParkEventsCompanion(carId: Value(null)));
      await (_db.delete(_db.cars)..where((c) => c.id.equals(id))).go();
    });
  }

  @override
  Stream<List<ParkEvent>> watchOpenEvents() =>
      (_db.select(_db.parkEvents)
            ..where((e) => e.departedAt.isNull())
            ..orderBy([(e) => OrderingTerm.desc(e.parkedAt)]))
          .watch()
          .map((rows) => rows.map(_event).toList());

  @override
  Future<void> saveEvent(ParkEvent e) =>
      _db.into(_db.parkEvents).insertOnConflictUpdate(ParkEventsCompanion.insert(
        id: e.id,
        carId: Value(e.carId),
        lat: e.position.lat,
        lng: e.position.lng,
        accuracyMeters: Value(e.accuracyMeters),
        parkedAt: e.parkedAt,
        departedAt: Value(e.departedAt),
        source: e.source.index,
        address: Value(e.address),
        notes: Value(e.notes),
        sweepingScheduleId: Value(e.sweepingScheduleId),
      ));

  @override
  Future<List<ParkEvent>> history({String? carId, int limit = 100}) async {
    final q = _db.select(_db.parkEvents)
      ..orderBy([(e) => OrderingTerm.desc(e.parkedAt)])
      ..limit(limit);
    if (carId != null) q.where((e) => e.carId.equals(carId));
    return (await q.get()).map(_event).toList();
  }
}

class DriftSweepingRepository implements SweepingRepository {
  DriftSweepingRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<SweepingSchedule>> coveringPoint(GeoPoint p) async {
    // Bounding-box prefilter in SQL, exact test in Dart.
    final rows = await (_db.select(_db.sweepingSchedules)
          ..where((s) =>
              s.minLat.isSmallerOrEqualValue(p.lat) &
              s.maxLat.isBiggerOrEqualValue(p.lat) &
              s.minLng.isSmallerOrEqualValue(p.lng) &
              s.maxLng.isBiggerOrEqualValue(p.lng)))
        .get();
    return [
      for (final r in rows)
        if (pointInPolygon(p, _ring(r.polygonJson))) _schedule(r)
    ];
  }

  List<GeoPoint> _ring(String json) => [
        for (final c in (jsonDecode(json) as List)) GeoPoint((c[0] as num).toDouble(), (c[1] as num).toDouble())
      ];

  SweepingSchedule _schedule(SweepingScheduleRow r) => SweepingSchedule(
        id: r.id,
        cityCode: r.cityCode,
        routeId: r.routeId,
        weekdays: _setOf(r.weekdayMask, 1, 7),
        weeksOfMonth: _setOf(r.weekOfMonthMask, 1, 5),
        startMinute: r.startMinute,
        endMinute: r.endMinute,
        side: StreetSide.values[r.side],
        skipDates: {for (final d in (jsonDecode(r.skipDatesJson) as List)) DateTime.parse(d as String)},
        polygon: _ring(r.polygonJson),
        sourceUpdatedAt: r.sourceUpdatedAt,
      );

  @override
  Future<void> replaceCity(String cityCode, List<SweepingSchedule> schedules) =>
      _db.transaction(() async {
        await (_db.delete(_db.sweepingSchedules)..where((s) => s.cityCode.equals(cityCode))).go();
        await _db.batch((b) {
          b.insertAll(_db.sweepingSchedules, [
            for (final s in schedules)
              SweepingSchedulesCompanion.insert(
                id: s.id,
                cityCode: s.cityCode,
                routeId: s.routeId,
                weekdayMask: _maskOf(s.weekdays, 1),
                weekOfMonthMask: _maskOf(s.weeksOfMonth, 1),
                startMinute: s.startMinute,
                endMinute: s.endMinute,
                side: s.side.index,
                skipDatesJson: Value(jsonEncode([for (final d in s.skipDates) d.toIso8601String()])),
                polygonJson: jsonEncode([for (final g in s.polygon) [g.lat, g.lng]]),
                minLat: s.polygon.map((g) => g.lat).reduce((a, b) => a < b ? a : b),
                maxLat: s.polygon.map((g) => g.lat).reduce((a, b) => a > b ? a : b),
                minLng: s.polygon.map((g) => g.lng).reduce((a, b) => a < b ? a : b),
                maxLng: s.polygon.map((g) => g.lng).reduce((a, b) => a > b ? a : b),
                sourceUpdatedAt: Value(s.sourceUpdatedAt),
              ),
          ]);
        });
      });
}
