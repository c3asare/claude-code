import '../models/car.dart';
import '../models/geo_point.dart';
import '../models/park_event.dart';
import '../models/sweeping_schedule.dart';

abstract interface class ParkingRepository {
  Stream<List<Car>> watchCars();
  Future<void> saveCar(Car car);
  Future<void> deleteCar(String id);

  /// Pending (no car yet) and active (car chosen, not departed) events.
  Stream<List<ParkEvent>> watchOpenEvents();
  Future<void> saveEvent(ParkEvent event);
  Future<List<ParkEvent>> history({String? carId, int limit = 100});
}

abstract interface class SweepingRepository {
  /// Schedules whose polygon contains [point].
  Future<List<SweepingSchedule>> coveringPoint(GeoPoint point);
  Future<void> replaceCity(String cityCode, List<SweepingSchedule> schedules);
}
