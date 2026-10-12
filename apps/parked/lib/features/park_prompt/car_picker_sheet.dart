import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';

import '../../app/providers.dart';
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
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Which car is this?')),
        for (final c in cars)
          ListTile(
            leading: CarIcon.of(c, size: 40),
            title: Text(c.name),
            onTap: () async {
              await ref
                  .read(parkingRepositoryProvider)
                  .saveEvent(pending.copyWith(carId: c.id));
              if (context.mounted) Navigator.pop(context);
            },
          ),
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
