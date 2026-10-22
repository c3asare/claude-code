import 'geo_point.dart';

enum ParkSource { auto, manual }

/// A parked-car record. [carId] is null while an auto-detected event is
/// waiting for the user to answer "Which car is this?".
class ParkEvent {
  const ParkEvent({
    required this.id,
    required this.position,
    required this.parkedAt,
    required this.source,
    this.carId,
    this.accuracyMeters,
    this.departedAt,
    this.address,
    this.notes,
    this.sweepingScheduleId,
  });

  final String id;
  final String? carId;
  final GeoPoint position;
  final double? accuracyMeters;
  final DateTime parkedAt;
  final DateTime? departedAt;
  final ParkSource source;
  final String? address;
  final String? notes;
  final String? sweepingScheduleId;

  bool get isPending => carId == null;
  bool get isActive => departedAt == null && carId != null;

  ParkEvent copyWith({
    GeoPoint? position,
    String? carId,
    DateTime? departedAt,
    String? address,
    String? notes,
    String? sweepingScheduleId,
  }) =>
      ParkEvent(
        id: id,
        position: position ?? this.position,
        parkedAt: parkedAt,
        source: source,
        accuracyMeters: accuracyMeters,
        carId: carId ?? this.carId,
        departedAt: departedAt ?? this.departedAt,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        sweepingScheduleId: sweepingScheduleId ?? this.sweepingScheduleId,
      );
}
