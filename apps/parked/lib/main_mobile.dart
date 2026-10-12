import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';

import 'app/parked_app.dart';
import 'app/providers.dart';
import 'bootstrap/local_park_notifier.dart';
import 'bootstrap/mobile_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: swap for Drift repositories once parked_data codegen + impls land.
  final parking = InMemoryParkingRepository();
  final sweeping = InMemorySweepingRepository();
  final notifier = LocalParkNotifier();
  await notifier.init();
  await MobileDetector(parking, notifier).start();
  runApp(ProviderScope(
    overrides: [
      parkingRepositoryProvider.overrideWithValue(parking),
      sweepingRepositoryProvider.overrideWithValue(sweeping),
    ],
    child: const ParkedApp(),
  ));
}
