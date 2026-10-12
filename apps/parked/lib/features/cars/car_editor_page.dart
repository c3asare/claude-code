import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parked_core/parked_core.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import 'car_icon.dart';
import 'car_palette.dart';

class CarEditorPage extends ConsumerStatefulWidget {
  const CarEditorPage({super.key, this.car});
  final Car? car; // null = new car

  @override
  ConsumerState<CarEditorPage> createState() => _CarEditorPageState();
}

class _CarEditorPageState extends ConsumerState<CarEditorPage> {
  late final _name = TextEditingController(text: widget.car?.name ?? '');
  late final _make = TextEditingController(text: widget.car?.make ?? '');
  late final _model = TextEditingController(text: widget.car?.model ?? '');
  late final _plate = TextEditingController(text: widget.car?.plate ?? '');
  late CarBodyStyle _style = widget.car?.bodyStyle ?? CarBodyStyle.sedan;
  late int _color = widget.car?.colorValue ?? carPaints[10].value;
  late int? _accent = widget.car?.accentColorValue;

  @override
  void dispose() {
    for (final c in [_name, _make, _model, _plate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final car = Car(
      id: widget.car?.id ?? const Uuid().v4(),
      name: name,
      colorValue: _color,
      accentColorValue: _accent,
      bodyStyle: _style,
      createdAt: widget.car?.createdAt ?? DateTime.now(),
      make: orNull(_make),
      model: orNull(_model),
      plate: orNull(_plate),
    );
    await ref.read(parkingRepositoryProvider).saveCar(car);
    if (mounted) Navigator.pop(context);
  }

  Widget _swatch(int value,
          {required bool selected,
          required VoidCallback onTap,
          String? tooltip}) =>
      Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(value),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black26,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car == null ? 'Add car' : 'Edit car'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CarIcon(
              style: _style,
              color: Color(_color),
              accent: _accent == null ? null : Color(_accent!),
              size: 140,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Name', hintText: 'e.g. Blue Civic'),
            onChanged: (_) => setState(() {}),
          ),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _make,
                    decoration: const InputDecoration(labelText: 'Make'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'Model'))),
          ]),
          TextField(
              controller: _plate,
              decoration: const InputDecoration(labelText: 'Plate (optional)')),
          const SizedBox(height: 20),
          Text('Body style', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in CarBodyStyle.values)
              ChoiceChip(
                selected: s == _style,
                onSelected: (_) => setState(() => _style = s),
                avatar: CarIcon(style: s, color: Color(_color), size: 22),
                label: Text(s.label),
              ),
          ]),
          const SizedBox(height: 20),
          Text('Paint', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final p in carPaints)
              _swatch(p.value,
                  selected: p.value == _color,
                  tooltip: p.name,
                  onTap: () => setState(() => _color = p.value)),
          ]),
          const SizedBox(height: 20),
          Text('Stripe (optional)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            ChoiceChip(
                label: const Text('None'),
                selected: _accent == null,
                onSelected: (_) => setState(() => _accent = null)),
            for (final p in carPaints)
              _swatch(p.value,
                  selected: p.value == _accent,
                  tooltip: p.name,
                  onTap: () => setState(() => _accent = p.value)),
          ]),
        ],
      ),
    );
  }
}
