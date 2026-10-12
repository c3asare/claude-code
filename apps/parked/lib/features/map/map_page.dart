import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:parked_core/parked_core.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../cars/car_editor_page.dart';
import '../cars/car_icon.dart';
import '../cars/cars_page.dart';
import '../park_prompt/car_picker_sheet.dart';
import 'active_cars_panel.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});
  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _map = MapController();
  String? _promptedFor;

  Future<void> _parkHere() async {
    final messenger = ScaffoldMessenger.of(context);
    final fix = await ref.read(locationSourceProvider)?.currentFix();
    if (fix == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not get your location. Check permissions.')));
      return;
    }
    await ref.read(parkingRepositoryProvider).saveEvent(ParkEvent(
          id: const Uuid().v4(),
          position: fix.point,
          accuracyMeters: fix.accuracyMeters,
          parkedAt: fix.at,
          source: ParkSource.manual,
        ));
    // The pending event triggers the "Which car is this?" sheet via build().
  }

  @override
  Widget build(BuildContext context) {
    final carList = ref.watch(carsProvider).valueOrNull ?? <Car>[];
    final cars = {for (final c in carList) c.id: c};
    final events =
        ref.watch(openEventsProvider).valueOrNull ?? const <ParkEvent>[];

    // "Which car is this?" for the oldest pending park.
    final pending = events.where((e) => e.isPending).lastOrNull;
    if (pending != null && _promptedFor != pending.id) {
      _promptedFor = pending.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showCarPicker(context, pending);
      });
    }

    final active = events.where((e) => e.isActive).toList();
    final canPin = ref.watch(locationSourceProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Parked'), actions: [
        IconButton(
          tooltip: 'My cars',
          icon: const Icon(Icons.directions_car_filled_outlined),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute<void>(builder: (_) => const CarsPage())),
        ),
      ]),
      floatingActionButton: canPin
          ? FloatingActionButton.extended(
              onPressed: carList.isEmpty
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const CarEditorPage()))
                  : _parkHere,
              icon: Icon(carList.isEmpty ? Icons.add : Icons.local_parking),
              label: Text(carList.isEmpty ? 'Add your car' : 'I parked here'),
            )
          : null,
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: active.isEmpty
                ? const LatLng(
                    33.7701, -118.1937) // Long Beach; replace with last known
                : LatLng(active.first.position.lat, active.first.position.lng),
            initialZoom: 15,
          ),
          children: [
            if (ref.watch(mapTilesEnabledProvider))
              TileLayer(
                // Dev only: OSM's public tiles are not for production traffic.
                // Swap for MapTiler/Stadia/self-hosted before release.
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app.parked',
              ),
            MarkerLayer(markers: [
              for (final e in active)
                Marker(
                  point: LatLng(e.position.lat, e.position.lng),
                  width: 48,
                  height: 48,
                  child: cars[e.carId] == null
                      ? const Icon(Icons.directions_car, size: 36)
                      : Tooltip(
                          message: cars[e.carId]!.name,
                          child: CarIcon.of(cars[e.carId]!, size: 44)),
                ),
            ]),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              // Leave room for the FAB.
              padding: EdgeInsets.only(bottom: canPin ? 72 : 0),
              child: ActiveCarsPanel(
                events: active,
                cars: cars,
                onTapEvent: (e) =>
                    _map.move(LatLng(e.position.lat, e.position.lng), 17),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
