import 'package:flutter/services.dart';
import 'package:parked_core/parked_core.dart';

/// Bundled per-city sweeping snapshots. Add a city by shipping a normalized
/// GeoJSON file (see parseSweepingGeoJson) and listing it here.
const bundledSweeping = <String, String>{
  'LB': 'assets/sweeping/long_beach_dev_sample.geojson',
};

Future<void> loadBundledSweeping(SweepingRepository repo) async {
  for (final e in bundledSweeping.entries) {
    final json = await rootBundle.loadString(e.value);
    await repo.replaceCity(e.key, parseSweepingGeoJson(json, cityCode: e.key));
  }
}
