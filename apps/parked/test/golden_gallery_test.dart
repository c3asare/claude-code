import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parked/features/cars/car_icon.dart';
import 'package:parked/features/cars/car_palette.dart';
import 'package:parked_core/parked_core.dart';

/// Visual regression for the car painter. Regenerate with:
///   flutter test --update-goldens test/golden_gallery_test.dart
void main() {
  testWidgets('car icon gallery', (tester) async {
    tester.view.physicalSize = const Size(900, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFE9E4D8), // map-ish background
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Wrap(spacing: 14, runSpacing: 14, children: [
              for (final s in CarBodyStyle.values)
                CarIcon(style: s, color: Color(carPaints[10].value), size: 100),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 14, runSpacing: 14, children: [
              for (var i = 0; i < 8; i++)
                CarIcon(
                  style: CarBodyStyle.values[i % 7],
                  color: Color(carPaints[i * 2].value),
                  accent: i.isOdd ? Colors.white : null,
                  size: 80,
                ),
            ]),
          ]),
        ),
      ),
    ));
    await expectLater(find.byType(ColoredBox).first, matchesGoldenFile('goldens/car_gallery.png'));
  }, skip: !Platform.isLinux); // pixel output differs per platform; goldens are generated on Linux/CI
}
