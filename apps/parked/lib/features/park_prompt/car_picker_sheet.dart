import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';

import '../../app/providers.dart';
import '../cars/car_editor_page.dart';
import '../cars/car_icon.dart';

Future<void> showCarPicker(BuildContext context, ParkEvent pending) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _CarPicker(pending),
    );

class _CarPicker extends ConsumerWidget {
  const _CarPicker(this.pending);
  final ParkEvent pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider).valueOrNull ?? const <Car>[];

    Future<void> choose(Car c) async {
      final confirmed = pending.copyWith(carId: c.id);
      await ref.read(parkingRepositoryProvider).saveEvent(confirmed);
      await ref.read(sweepingAlertServiceProvider).onParked(confirmed, car: c);
      if (context.mounted) Navigator.pop(context);
    }

    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Which car is this?')),
        if (cars.isEmpty)
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add your car first'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const CarEditorPage())),
          ),
        for (final c in cars)
          ListTile(
              leading: CarIcon.of(c, size: 40),
              title: Text(c.name),
              onTap: () => choose(c)),
        ListTile(
          leading: const Icon(Icons.close),
          title: const Text('Not parked / ignore'),
          onTap: () async {
            await ref
                .read(parkingRepositoryProvider)
                .saveEvent(pending.copyWith(departedAt: DateTime.now()));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ]),
    );
  }
}
