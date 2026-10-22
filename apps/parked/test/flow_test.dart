import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parked/app/parked_app.dart';
import 'package:parked/app/providers.dart';
import 'package:parked_core/parked_core.dart';

class _Scheduler implements AlertScheduler {
  final keys = <String>[];
  @override
  Future<void> cancelWhere(String p) async =>
      keys.removeWhere((k) => k.startsWith(p));
  @override
  Future<void> schedule(
          {required String key,
          required DateTime at,
          required String title,
          required String body}) async =>
      keys.add(key);
}

void main() {
  testWidgets('pending park -> pick car -> sweeping status -> left',
      (tester) async {
    final parking = InMemoryParkingRepository();
    final sweeping = InMemorySweepingRepository();
    // Every day, all day, so the status is deterministic regardless of "now".
    await sweeping.replaceCity('T', [
      SweepingSchedule(
        id: 'T:1:0',
        cityCode: 'T',
        routeId: '1',
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        startMinute: 0,
        endMinute: 24 * 60 - 1,
        polygon: const [
          GeoPoint(0, 0),
          GeoPoint(0, 2),
          GeoPoint(2, 2),
          GeoPoint(2, 0)
        ],
      ),
    ]);
    await parking.saveCar(Car(
        id: 'c1',
        name: 'Blue Civic',
        colorValue: 0xFF2459B8,
        createdAt: DateTime(2026)));
    final scheduler = _Scheduler();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        parkingRepositoryProvider.overrideWithValue(parking),
        sweepingRepositoryProvider.overrideWithValue(sweeping),
        alertSchedulerProvider.overrideWithValue(scheduler),
        mapTilesEnabledProvider.overrideWithValue(false),
      ],
      child: const ParkedApp(),
    ));
    await tester.pumpAndSettle();

    // Native/foreground detection drops a pending event.
    await parking.saveEvent(ParkEvent(
        id: 'e1',
        position: const GeoPoint(1, 1),
        parkedAt: DateTime.now(),
        source: ParkSource.auto));
    await tester.pumpAndSettle();
    expect(find.text('Which car is this?'), findsOneWidget);

    await tester.tap(find.text('Blue Civic'));
    await tester.pumpAndSettle();

    expect(find.text('Which car is this?'), findsNothing);
    expect(find.textContaining('Sweeping is happening now'), findsOneWidget);

    await tester.tap(find.text('Left'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sweeping is happening now'), findsNothing);
  });

  testWidgets('adjust pin keeps the car parked and re-plans alerts',
      (tester) async {
    final parking = InMemoryParkingRepository();
    final sweeping = InMemorySweepingRepository();
    await parking.saveCar(Car(
        id: 'c1',
        name: 'Blue Civic',
        colorValue: 0xFF2459B8,
        createdAt: DateTime(2026)));
    await parking.saveEvent(ParkEvent(
        id: 'e1',
        carId: 'c1',
        position: const GeoPoint(1, 1),
        parkedAt: DateTime.now(),
        source: ParkSource.auto));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        parkingRepositoryProvider.overrideWithValue(parking),
        sweepingRepositoryProvider.overrideWithValue(sweeping),
        mapTilesEnabledProvider.overrideWithValue(false),
      ],
      child: const ParkedApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Adjust pin'));
    await tester.pumpAndSettle();
    expect(find.text('Set pin here'), findsOneWidget);

    await tester.tap(find.text('Set pin here'));
    await tester.pumpAndSettle();
    expect(find.text('Set pin here'), findsNothing);
    final open = await parking.watchOpenEvents().first;
    expect(open.single.isActive, isTrue);
  });
}
