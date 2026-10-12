// View-only companion entrypoint (Windows/macOS). No sensing imports.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';

import 'app/parked_app.dart';
import 'app/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: read-only sync source (cloud or file export) replaces in-memory.
  runApp(ProviderScope(
    overrides: [
      parkingRepositoryProvider.overrideWithValue(InMemoryParkingRepository()),
      sweepingRepositoryProvider.overrideWithValue(InMemorySweepingRepository()),
    ],
    child: const ParkedApp(),
  ));
}
