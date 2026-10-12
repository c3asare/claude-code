import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';

/// Composition roots (main_*.dart) override these with real implementations.
final parkingRepositoryProvider =
    Provider<ParkingRepository>((_) => throw UnimplementedError('override in main'));
final sweepingRepositoryProvider =
    Provider<SweepingRepository>((_) => throw UnimplementedError('override in main'));

final carsProvider = StreamProvider<List<Car>>(
    (ref) => ref.watch(parkingRepositoryProvider).watchCars());

final openEventsProvider = StreamProvider<List<ParkEvent>>(
    (ref) => ref.watch(parkingRepositoryProvider).watchOpenEvents());
