import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parked_core/parked_core.dart';
import 'package:parked_data/parked_data.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('cars round-trip including body style and accent', () async {
    final repo = DriftParkingRepository(db);
    final car = Car(
      id: 'c1', name: 'Blue Civic', colorValue: 0xFF2459B8, createdAt: DateTime(2026),
      bodyStyle: CarBodyStyle.hatchback, accentColorValue: 0xFFF4F4F2, plate: 'ABC123',
    );
    await repo.saveCar(car);
    final got = (await repo.watchCars().first).single;
    expect(got.bodyStyle, CarBodyStyle.hatchback);
    expect(got.accentColorValue, 0xFFF4F4F2);
    expect(got.plate, 'ABC123');
  });

  test('pending -> confirmed -> departed lifecycle', () async {
    final repo = DriftParkingRepository(db);
    await repo.saveCar(Car(id: 'c1', name: 'A', colorValue: 1, createdAt: DateTime(2026)));
    final pending = ParkEvent(
      id: 'e1', position: const GeoPoint(33.77, -118.19), parkedAt: DateTime(2026, 10, 12), source: ParkSource.auto);
    await repo.saveEvent(pending);
    expect((await repo.watchOpenEvents().first).single.isPending, isTrue);
    await repo.saveEvent(pending.copyWith(carId: 'c1'));
    expect((await repo.watchOpenEvents().first).single.isActive, isTrue);
    await repo.saveEvent(pending.copyWith(carId: 'c1', departedAt: DateTime(2026, 10, 13)));
    expect(await repo.watchOpenEvents().first, isEmpty);
    expect(await repo.history(carId: 'c1'), hasLength(1));
  });

  test('deleting a car closes its open events and keeps history', () async {
    final repo = DriftParkingRepository(db);
    await repo.saveCar(Car(id: 'c1', name: 'A', colorValue: 1, createdAt: DateTime(2026)));
    await repo.saveEvent(ParkEvent(
      id: 'e1', carId: 'c1', position: const GeoPoint(1, 1), parkedAt: DateTime(2026), source: ParkSource.manual));
    await repo.deleteCar('c1');
    expect(await repo.watchOpenEvents().first, isEmpty);
    expect(await repo.history(), hasLength(1));
  });

  test('sweeping: replaceCity + coveringPoint round-trips masks, skips, polygon', () async {
    final repo = DriftSweepingRepository(db);
    final s = SweepingSchedule(
      id: 'LB:R1:0', cityCode: 'LB', routeId: 'R1', weekdays: {2, 4}, weeksOfMonth: {2, 4},
      startMinute: 480, endMinute: 600, skipDates: {DateTime(2026, 10, 27)},
      polygon: const [GeoPoint(0, 0), GeoPoint(0, 2), GeoPoint(2, 2), GeoPoint(2, 0)],
    );
    await repo.replaceCity('LB', [s]);
    final hit = await repo.coveringPoint(const GeoPoint(1, 1));
    expect(hit.single.weekdays, {2, 4});
    expect(hit.single.weeksOfMonth, {2, 4});
    expect(hit.single.skipDates, {DateTime(2026, 10, 27)});
    expect(await repo.coveringPoint(const GeoPoint(5, 5)), isEmpty);
    await repo.replaceCity('LB', const []);
    expect(await repo.coveringPoint(const GeoPoint(1, 1)), isEmpty);
  });
}
