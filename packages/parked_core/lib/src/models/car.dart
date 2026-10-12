class Car {
  const Car({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.make,
    this.model,
    this.plate,
  });

  final String id;
  final String name;

  /// ARGB int, so core stays free of Flutter's Color.
  final int colorValue;
  final DateTime createdAt;
  final String? make;
  final String? model;
  final String? plate;

  Car copyWith({String? name, int? colorValue, String? make, String? model, String? plate}) => Car(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
        make: make ?? this.make,
        model: model ?? this.model,
        plate: plate ?? this.plate,
      );
}
