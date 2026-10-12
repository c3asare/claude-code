/// Common factory-style paint colors so users can match their real car.
class CarPaint {
  const CarPaint(this.name, this.value);
  final String name;
  final int value; // ARGB
}

const carPaints = <CarPaint>[
  CarPaint('White', 0xFFF4F4F2),
  CarPaint('Silver', 0xFFB8BCC2),
  CarPaint('Gray', 0xFF6B7078),
  CarPaint('Black', 0xFF1C1D20),
  CarPaint('Red', 0xFFC8201E),
  CarPaint('Burgundy', 0xFF6E1423),
  CarPaint('Orange', 0xFFE8731A),
  CarPaint('Yellow', 0xFFF2C21B),
  CarPaint('Green', 0xFF2F7D4F),
  CarPaint('Teal', 0xFF1F8A8A),
  CarPaint('Blue', 0xFF2459B8),
  CarPaint('Navy', 0xFF14264F),
  CarPaint('Purple', 0xFF5B3A8C),
  CarPaint('Brown', 0xFF5A3D2B),
  CarPaint('Beige', 0xFFC9B79C),
  CarPaint('Gold', 0xFFB8963E),
];
