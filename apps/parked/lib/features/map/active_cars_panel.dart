import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';

import '../../app/providers.dart';
import '../cars/car_icon.dart';

String _fmtWindow(SweepWindow w) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String t(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute == 0 ? '' : ':${d.minute.toString().padLeft(2, '0')}';
    return '$h$m${d.hour < 12 ? 'am' : 'pm'}';
  }

  return '${days[w.start.weekday - 1]} ${w.start.month}/${w.start.day}, ${t(w.start)}–${t(w.end)}';
}

/// One row per currently parked car: where/when, sweeping status, and "Left".
class ActiveCarsPanel extends ConsumerWidget {
  const ActiveCarsPanel(
      {super.key,
      required this.events,
      required this.cars,
      this.onTapEvent,
      this.onAdjust});
  final List<ParkEvent> events;
  final Map<String, Car> cars;
  final void Function(ParkEvent)? onTapEvent;
  final void Function(ParkEvent)? onAdjust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final e in events)
          _Row(
              event: e,
              car: cars[e.carId],
              onTap: onTapEvent,
              onAdjust: onAdjust),
      ]),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row(
      {required this.event, required this.car, this.onTap, this.onAdjust});
  final ParkEvent event;
  final Car? car;
  final void Function(ParkEvent)? onTap;
  final void Function(ParkEvent)? onAdjust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      id: event.id,
      lat: event.position.lat,
      lng: event.position.lng,
      parkedAt: event.parkedAt
    );
    final status = ref.watch(sweepingStatusProvider(key));
    final scheme = Theme.of(context).colorScheme;

    final (text, color) = status.when(
      loading: () => ('Checking sweeping…', null),
      error: (_, __) => ('Sweeping unavailable', null),
      data: (s) {
        if (s.isUnknown) return ('No sweeping schedule found here', null);
        final now = DateTime.now();
        if (s.isInWindow(now)) {
          return ('Sweeping is happening now – move your car!', scheme.error);
        }
        return (
          'Next sweep ${_fmtWindow(s.window!)}',
          s.window!.start.difference(now) < const Duration(hours: 24)
              ? scheme.error
              : null
        );
      },
    );

    return ListTile(
      onTap: onTap == null ? null : () => onTap!(event),
      leading: car == null
          ? const Icon(Icons.directions_car)
          : CarIcon.of(car!, size: 40),
      title: Text(car?.name ?? 'Car'),
      subtitle: Text(text, style: TextStyle(color: color)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (onAdjust != null)
          IconButton(
            tooltip: 'Adjust pin',
            icon: const Icon(Icons.edit_location_alt_outlined),
            onPressed: () => onAdjust!(event),
          ),
        TextButton(
          onPressed: () async {
            await ref
                .read(parkingRepositoryProvider)
                .saveEvent(event.copyWith(departedAt: DateTime.now()));
            await ref.read(sweepingAlertServiceProvider).onDeparted(event);
          },
          child: const Text('Left'),
        ),
      ]),
    );
  }
}
