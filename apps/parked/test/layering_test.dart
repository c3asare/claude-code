import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the desktop-ready rule: mobile-only sensing must not leak into
/// shared code.
void main() {
  test('shared app code never imports sensing or mobile-only plugins', () {
    const allowed = {'lib/main_mobile.dart', 'lib/bootstrap/mobile_detector.dart'};
    final banned = RegExp(
        r"import\s+'package:(parked_sensing|geolocator|flutter_activity_recognition|permission_handler)/");
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') || allowed.contains(path)) continue;
      if (banned.hasMatch(f.readAsStringSync())) offenders.add(path);
    }
    expect(offenders, isEmpty);
  });

  test('parked_core stays pure Dart', () {
    final bad = RegExp(r"import\s+'package:flutter/|import\s+'dart:ui'");
    final offenders = [
      for (final f in Directory('../../packages/parked_core/lib').listSync(recursive: true).whereType<File>())
        if (bad.hasMatch(f.readAsStringSync())) f.path
    ];
    expect(offenders, isEmpty);
  });
}
