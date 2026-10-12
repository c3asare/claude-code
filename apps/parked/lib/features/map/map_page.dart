import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:parked_core/parked_core.dart';

import '../../app/providers.dart';
import '../park_prompt/car_picker_sheet.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});
  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  String? _promptedFor;

  @override
  Widget build(BuildContext context) {
    final cars = {for (final c in ref.watch(carsProvider).valueOrNull ?? <Car>[]) c.id: c};
    final events = ref.watch(openEventsProvider).valueOrNull ?? const <ParkEvent>[];

    // "Which car is this?" for the oldest pending auto-detected park.
    final pending = events.where((e) => e.isPending).firstOrNull;
    if (pending != null && _promptedFor != pending.id) {
      _promptedFor = pending.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showCarPicker(context, pending);
      });
    }

    final active = events.where((e) => e.isActive).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Parked')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: active.isEmpty
              ? const LatLng(33.7701, -118.1937) // Long Beach; replace with last known
              : LatLng(active.first.position.lat, active.first.position.lng),
          initialZoom: 15,
        ),
        children: [
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
                width: 44,
                height: 44,
                child: Icon(Icons.directions_car,
                    color: Color(cars[e.carId]?.colorValue ?? 0xFF3F51B5), size: 36),
              ),
          ]),
        ],
      ),
    );
  }
}
