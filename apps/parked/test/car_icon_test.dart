import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parked/features/cars/car_icon.dart';
import 'package:parked_core/parked_core.dart';

void main() {
  testWidgets('CarIcon paints every body style, with and without stripe',
      (tester) async {
    for (final style in CarBodyStyle.values) {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          CarIcon(style: style, color: Colors.red),
          CarIcon(
              style: style,
              color: Colors.blue,
              accent: Colors.white,
              size: 120),
        ]),
      ));
      expect(tester.takeException(), isNull, reason: style.name);
    }
  });
}
