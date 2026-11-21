import 'package:material_ui/material_ui.dart';

import '../domain/config.dart';

class NumberControl extends StatelessWidget {
  const NumberControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label: ${value.toStringAsFixed(2)}'),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        label: value.toStringAsFixed(2),
        onChanged: onChanged,
      ),
    ],
  );
}

class PhysicsControls extends StatelessWidget {
  const PhysicsControls({
    super.key,
    required this.config,
    required this.onChanged,
  });
  final LabConfig config;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final p = config.physics;
    void update({
      double? mass,
      double? gravity,
      double? impulse,
      double? drag,
    }) {
      config.physics = Physics(
        mass: mass ?? p.mass,
        gravity: gravity ?? p.gravity,
        impulse: impulse ?? p.impulse,
        drag: drag ?? p.drag,
      );
      onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<CharacterKind>(
          initialValue: config.character,
          decoration: const InputDecoration(labelText: 'Personagem'),
          items: const [
            DropdownMenuItem(
              value: CharacterKind.dino,
              child: Text('Dinossauro clássico'),
            ),
            DropdownMenuItem(value: CharacterKind.robot, child: Text('Robô')),
            DropdownMenuItem(
              value: CharacterKind.runner,
              child: Text('Corredor'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              config.character = v;
              onChanged();
            }
          },
        ),
        const SizedBox(height: 24),
        NumberControl(
          label: 'Massa (kg)',
          value: p.mass,
          min: .5,
          max: 2,
          onChanged: (v) => update(mass: v),
        ),
        NumberControl(
          label: 'Gravidade (px/s²)',
          value: p.gravity,
          min: 800,
          max: 2400,
          onChanged: (v) => update(gravity: v),
        ),
        NumberControl(
          label: 'Impulso (kg·px/s)',
          value: p.impulse,
          min: 400,
          max: 1000,
          onChanged: (v) => update(impulse: v),
        ),
        NumberControl(
          label: 'Arrasto (kg/s)',
          value: p.drag,
          min: 0,
          max: 2,
          onChanged: (v) => update(drag: v),
        ),
        const Text(
          'A física editável é usada no laboratório. O modo clássico usa a física padrão.',
        ),
        TextButton(
          onPressed: () {
            config.physics = const Physics();
            onChanged();
          },
          child: const Text('Restaurar física padrão'),
        ),
      ],
    );
  }
}
