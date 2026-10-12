import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';

import '../../app/providers.dart';
import 'car_editor_page.dart';
import 'car_icon.dart';

class CarsPage extends ConsumerWidget {
  const CarsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider).valueOrNull ?? const <Car>[];
    void open([Car? c]) => Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) => CarEditorPage(car: c)));

    return Scaffold(
      appBar: AppBar(title: const Text('My cars')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: open,
          icon: const Icon(Icons.add),
          label: const Text('Add car')),
      body: cars.isEmpty
          ? const Center(
              child: Text('Add your car so parked spots look like it.'))
          : ListView(children: [
              for (final c in cars)
                ListTile(
                  leading: CarIcon.of(c, size: 44),
                  title: Text(c.name),
                  subtitle: Text([
                    c.bodyStyle.label,
                    if (c.make != null) c.make!,
                    if (c.model != null) c.model!
                  ].join(' · ')),
                  onTap: () => open(c),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(parkingRepositoryProvider).deleteCar(c.id),
                  ),
                ),
            ]),
    );
  }
}
