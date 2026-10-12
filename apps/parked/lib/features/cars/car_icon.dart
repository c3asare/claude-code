import 'package:flutter/material.dart';
import 'package:parked_core/parked_core.dart';

/// Top-down car drawn from the user's body style, paint and stripe, so the
/// map marker looks like their actual vehicle. Pure Canvas: no image assets,
/// works on every platform.
class CarIcon extends StatelessWidget {
  const CarIcon({
    super.key,
    required this.style,
    required this.color,
    this.accent,
    this.size = 40,
  });

  CarIcon.of(Car car, {Key? key, double size = 40})
      : this(
          key: key,
          style: car.bodyStyle,
          color: Color(car.colorValue),
          accent: car.accentColorValue == null
              ? null
              : Color(car.accentColorValue!),
          size: size,
        );

  final CarBodyStyle style;
  final Color color;
  final Color? accent;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _CarPainter(style, color, accent)),
      );
}

class _Spec {
  const _Spec(this.length, this.width, this.cabinTop, this.cabinBottom,
      {this.bed = false});
  final double length, width; // fractions of the icon box
  final double cabinTop, cabinBottom; // fractions of car length, nose = 0
  final bool bed;
}

const _specs = <CarBodyStyle, _Spec>{
  CarBodyStyle.sedan: _Spec(0.92, 0.46, 0.30, 0.68),
  CarBodyStyle.coupe: _Spec(0.88, 0.48, 0.36, 0.66),
  CarBodyStyle.hatchback: _Spec(0.80, 0.48, 0.30, 0.80),
  CarBodyStyle.suv: _Spec(0.90, 0.54, 0.26, 0.82),
  CarBodyStyle.truck: _Spec(0.96, 0.54, 0.22, 0.44, bed: true),
  CarBodyStyle.van: _Spec(0.94, 0.54, 0.12, 0.88),
  CarBodyStyle.motorcycle: _Spec(0.80, 0.16, 0, 0),
};

class _CarPainter extends CustomPainter {
  _CarPainter(this.style, this.color, this.accent);
  final CarBodyStyle style;
  final Color color;
  final Color? accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final spec = _specs[style]!;
    final w = s * spec.width, l = s * spec.length;
    final left = (size.width - w) / 2, top = (size.height - l) / 2;
    final dark = Paint()..color = const Color(0xFF15161A);

    if (style == CarBodyStyle.motorcycle) {
      _paintMotorcycle(canvas, left, top, w, l, s);
      return;
    }

    // Wheels poke slightly past the body.
    final ww = w * 0.16, wl = l * 0.18;
    for (final fy in const [0.14, 0.68]) {
      for (final x in [left - ww * 0.4, left + w - ww * 0.6]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, top + l * fy, ww, wl), Radius.circular(ww / 2)),
          dark,
        );
      }
    }

    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, l), Radius.circular(w * 0.38));
    canvas.drawShadow(Path()..addRRect(body), Colors.black, 2, true);
    canvas.drawRRect(body, Paint()..color = color);

    if (accent != null) {
      canvas.drawRect(
        Rect.fromLTWH(left + w * 0.40, top + l * 0.04, w * 0.20, l * 0.92),
        Paint()..color = accent!,
      );
    }

    // Glass: windshield + roof area.
    final glass = Paint()
      ..color = const Color(0xFF20262E).withValues(alpha: 0.88);
    final ct = top + l * spec.cabinTop, cb = top + l * spec.cabinBottom;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(left + w * 0.12, ct, left + w * 0.88, cb),
          Radius.circular(w * 0.22)),
      glass,
    );
    // Roof panel (body color) so glass reads as windshield/rear window.
    final roofInset = (cb - ct) * 0.26;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(
              left + w * 0.18, ct + roofInset, left + w * 0.82, cb - roofInset),
          Radius.circular(w * 0.12)),
      Paint()..color = Color.lerp(color, Colors.black, 0.12)!,
    );

    if (spec.bed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(left + w * 0.12, top + l * 0.50, left + w * 0.88,
                top + l * 0.94),
            Radius.circular(w * 0.08)),
        Paint()..color = Color.lerp(color, Colors.black, 0.35)!,
      );
    }

    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..color = Colors.black.withValues(alpha: 0.35),
    );
  }

  void _paintMotorcycle(
      Canvas canvas, double left, double top, double w, double l, double s) {
    final dark = Paint()..color = const Color(0xFF15161A);
    final cx = left + w / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w * 0.3, top, w * 0.6, l * 0.22),
            Radius.circular(w * 0.3)),
        dark);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w * 0.3, top + l * 0.78, w * 0.6, l * 0.22),
            Radius.circular(w * 0.3)),
        dark);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.55, top + l * 0.18, w * 1.1, l * 0.64),
          Radius.circular(w * 0.5)),
      Paint()..color = color,
    );
    if (accent != null) {
      canvas.drawRect(
          Rect.fromLTWH(cx - w * 0.1, top + l * 0.2, w * 0.2, l * 0.6),
          Paint()..color = accent!);
    }
    // Handlebars.
    canvas.drawLine(
      Offset(cx - w * 1.5, top + l * 0.24),
      Offset(cx + w * 1.5, top + l * 0.24),
      Paint()
        ..color = const Color(0xFF15161A)
        ..strokeWidth = s * 0.04
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CarPainter old) =>
      old.style != style || old.color != color || old.accent != accent;
}
