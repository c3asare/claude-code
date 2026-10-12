import '../models/park_event.dart';

/// Asks the user, outside the app UI, whether to keep a detected park.
abstract interface class ParkNotifier {
  Future<void> init();
  Future<void> promptParked(ParkEvent pending);
}
