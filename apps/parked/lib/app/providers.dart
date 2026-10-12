import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';

/// Composition roots (main_*.dart) override these with real implementations.
final parkingRepositoryProvider = Provider<ParkingRepository>(
    (_) => throw UnimplementedError('override in main'));
final sweepingRepositoryProvider = Provider<SweepingRepository>(
    (_) => throw UnimplementedError('override in main'));

/// Null on view-only platforms (desktop); the "I parked here" button hides.
final locationSourceProvider = Provider<LocationSource?>((_) => null);

/// Tests turn this off so no network tile requests are made.
final mapTilesEnabledProvider = Provider<bool>((_) => true);

final alertSchedulerProvider =
    Provider<AlertScheduler>((_) => const NoopAlertScheduler());

final sweepingAlertServiceProvider =
    Provider<SweepingAlertService>((ref) => SweepingAlertService(
          ref.watch(sweepingRepositoryProvider),
          ref.watch(alertSchedulerProvider),
        ));

final carsProvider = StreamProvider<List<Car>>(
    (ref) => ref.watch(parkingRepositoryProvider).watchCars());

final openEventsProvider = StreamProvider<List<ParkEvent>>(
    (ref) => ref.watch(parkingRepositoryProvider).watchOpenEvents());

/// Keyed by value so the family doesn't rebuild on every frame.
typedef SpotKey = ({String id, double lat, double lng, DateTime parkedAt});

final sweepingStatusProvider =
    FutureProvider.family<SweepingStatus, SpotKey>((ref, k) {
  final e = ParkEvent(
    id: k.id,
    position: GeoPoint(k.lat, k.lng),
    parkedAt: k.parkedAt,
    source: ParkSource.auto,
  );
  return ref.watch(sweepingAlertServiceProvider).statusFor(e);
});

class NoopAlertScheduler implements AlertScheduler {
  const NoopAlertScheduler();
  @override
  Future<void> cancelWhere(String keyPrefix) async {}
  @override
  Future<void> schedule(
      {required String key,
      required DateTime at,
      required String title,
      required String body}) async {}
}
