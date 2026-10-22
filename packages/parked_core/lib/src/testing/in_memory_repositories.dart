import 'dart:async';

import '../logic/geo_math.dart';
import '../models/car.dart';
import '../models/geo_point.dart';
import '../models/park_event.dart';
import '../models/sweeping_schedule.dart';
import '../ports/repositories.dart';

class InMemoryParkingRepository implements ParkingRepository {
  final _cars = <String, Car>{};
  final _events = <String, ParkEvent>{};
  final _carsCtl = StreamController<List<Car>>.broadcast();
  final _eventsCtl = StreamController<List<ParkEvent>>.broadcast();

  List<Car> get _carList => _cars.values.toList();
  List<ParkEvent> get _open =>
      _events.values.where((e) => e.departedAt == null).toList();

  @override
  Stream<List<Car>> watchCars() async* {
    yield _carList;
    yield* _carsCtl.stream;
  }

  @override
  Future<void> saveCar(Car car) async {
    _cars[car.id] = car;
    _carsCtl.add(_carList);
  }

  @override
  Future<void> deleteCar(String id) async {
    _cars.remove(id);
    _carsCtl.add(_carList);
  }

  @override
  Stream<List<ParkEvent>> watchOpenEvents() async* {
    yield _open;
    yield* _eventsCtl.stream;
  }

  @override
  Future<void> saveEvent(ParkEvent event) async {
    _events[event.id] = event;
    _eventsCtl.add(_open);
  }

  @override
  Future<List<ParkEvent>> history({String? carId, int limit = 100}) async {
    final all = _events.values
        .where((e) => carId == null || e.carId == carId)
        .toList()
      ..sort((a, b) => b.parkedAt.compareTo(a.parkedAt));
    return all.take(limit).toList();
  }
}

class InMemorySweepingRepository implements SweepingRepository {
  final _byCity = <String, List<SweepingSchedule>>{};

  @override
  Future<List<SweepingSchedule>> coveringPoint(GeoPoint point) async => [
        for (final list in _byCity.values)
          for (final s in list)
            if (pointInPolygon(point, s.polygon)) s
      ];

  @override
  Future<void> replaceCity(
          String cityCode, List<SweepingSchedule> schedules) async =>
      _byCity[cityCode] = schedules;
}
