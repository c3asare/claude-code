import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_data/parked_data.dart';
import 'package:parked_sensing/parked_sensing.dart';

import 'app/parked_app.dart';
import 'app/providers.dart';
import 'bootstrap/local_alert_scheduler.dart';
import 'bootstrap/local_park_notifier.dart';
import 'bootstrap/mobile_detector.dart';
import 'bootstrap/sweeping_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final parking = DriftParkingRepository(db);
  final sweeping = DriftSweepingRepository(db);
  await loadBundledSweeping(sweeping);

  final notifier = LocalParkNotifier();
  await notifier.init();
  final scheduler = LocalAlertScheduler();
  await scheduler.init();

  // Don't block first frame on permission prompts.
  MobileDetector(parking, notifier).start();

  runApp(ProviderScope(
    overrides: [
      parkingRepositoryProvider.overrideWithValue(parking),
      sweepingRepositoryProvider.overrideWithValue(sweeping),
      alertSchedulerProvider.overrideWithValue(scheduler),
      locationSourceProvider.overrideWithValue(GeolocatorLocationSource()),
    ],
    child: const ParkedApp(),
  ));
}
