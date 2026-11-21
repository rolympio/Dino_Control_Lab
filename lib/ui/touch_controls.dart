import 'package:material_ui/material_ui.dart';

import '../game/dino_game.dart';

class TouchControls extends StatelessWidget {
  const TouchControls({super.key, required this.game, required this.focus});
  final DinoGame game;
  final FocusNode focus;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              game.jump();
              focus.requestFocus();
            },
            child: const Text('Pular'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Listener(
            onPointerDown: (_) {
              game.heldDuck = true;
            },
            onPointerUp: (_) {
              game.heldDuck = false;
            },
            onPointerCancel: (_) {
              game.heldDuck = false;
            },
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Segure para abaixar'),
            ),
          ),
        ),
      ],
    ),
  );
}
