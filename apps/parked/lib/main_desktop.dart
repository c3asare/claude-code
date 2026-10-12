// View-only companion entrypoint (Windows/macOS). No sensing imports.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_data/parked_data.dart';

import 'app/parked_app.dart';
import 'app/providers.dart';
import 'bootstrap/sweeping_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: the companion should read the phone's data (cloud sync or file
  // export). Until sync exists this opens its own empty local database.
  final db = AppDatabase();
  final sweeping = DriftSweepingRepository(db);
  await loadBundledSweeping(sweeping);
  runApp(ProviderScope(
    overrides: [
      parkingRepositoryProvider.overrideWithValue(DriftParkingRepository(db)),
      sweepingRepositoryProvider.overrideWithValue(sweeping),
    ],
    child: const ParkedApp(),
  ));
}
