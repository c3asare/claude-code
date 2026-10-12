enum CarBodyStyle {
  sedan('Sedan'),
  coupe('Coupe'),
  hatchback('Hatchback'),
  suv('SUV'),
  truck('Truck'),
  van('Van'),
  motorcycle('Motorcycle');

  const CarBodyStyle(this.label);
  final String label;
}

class Car {
  const Car({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.bodyStyle = CarBodyStyle.sedan,
    this.accentColorValue,
    this.make,
    this.model,
    this.plate,
  });

  final String id;
  final String name;

  /// ARGB ints, so core stays free of Flutter's Color.
  final int colorValue;

  /// Optional racing-stripe color; null = no stripe.
  final int? accentColorValue;
  final CarBodyStyle bodyStyle;
  final DateTime createdAt;
  final String? make;
  final String? model;
  final String? plate;

  Car copyWith({
    String? name,
    int? colorValue,
    CarBodyStyle? bodyStyle,
    int? accentColorValue,
    bool clearAccent = false,
    String? make,
    String? model,
    String? plate,
  }) =>
      Car(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
        bodyStyle: bodyStyle ?? this.bodyStyle,
        accentColorValue: clearAccent ? null : (accentColorValue ?? this.accentColorValue),
        make: make ?? this.make,
        model: model ?? this.model,
        plate: plate ?? this.plate,
      );
}
