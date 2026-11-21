import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../domain/config.dart';
import '../game/dino_game.dart';
import 'lab_panel.dart';
import 'touch_controls.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.store, required this.classic});
  final AppStore store;
  final bool classic;
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late DinoGame game;
  final focus = FocusNode();
  final audio = AudioPlayer();
  late Timer ticker;
  String? audioError;

  /// Bumped only when something the HUD shows has changed, so the ticker
  /// does not rebuild the whole page (lab panel included) ten times a second.
  final hud = ValueNotifier<int>(0);
  Object? _shown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    newGame();
    ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = (
        game,
        game.sim.score,
        game.sim.speed.round(),
        game.sim.crashed,
        game.userPaused,
        widget.store.best,
      );
      if (now != _shown) {
        _shown = now;
        hud.value++;
      }
    });
  }

  Widget live(WidgetBuilder builder) => ValueListenableBuilder<int>(
    valueListenable: hud,
    builder: (context, _, _) => builder(context),
  );

  void newGame() {
    game = DinoGame(
      widget.classic
          ? LabConfig(seed: DateTime.now().millisecondsSinceEpoch)
          : widget.store.config,
      classic: widget.classic,
      onFinished: (session) {
        unawaited(widget.store.addSession(session));
      },
      onSound: (name) {
        if (widget.store.sound) unawaited(playSound(name));
      },
    );
  }

  Future<void> playSound(String name) async {
    try {
      await audio.play(AssetSource('audio/$name.wav'));
    } catch (error) {
      if (mounted) setState(() => audioError = 'Som indisponível: $error');
    }
  }

  void restart() {
    game.finish('reiniciada');
    setState(newGame);
    focus.requestFocus();
  }

  void pause() => setState(() {
    game.userPaused = !game.userPaused;
    game.heldDuck = false;
    game.pendingJump = false;
  });
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      game.userPaused = true;
      game.heldDuck = false;
      game.pendingJump = false;
    }
  }

  @override
  void dispose() {
    game.finish('encerrada');
    ticker.cancel();
    hud.dispose();
    focus.dispose();
    unawaited(audio.dispose());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  KeyEventResult key(FocusNode node, KeyEvent event) {
    final down = event is KeyDownEvent;
    final up = event is KeyUpEvent;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown) {
      if (down || up) game.heldDuck = down;
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.arrowUp) {
      if (down) {
        if (game.sim.crashed) {
          restart();
        } else {
          game.jump();
        }
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyP || k == LogicalKeyboardKey.escape) {
      if (down) pause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    game.ink = colors.onSurface;
    game.paper = Theme.of(context).scaffoldBackgroundColor;
    final arena = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: live(
            (context) => Wrap(
              spacing: 24,
              children: [
                Text(
                  'Pontos ${game.sim.score}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('Recorde ${widget.store.best}'),
                Text('${game.sim.speed.toStringAsFixed(0)} px/s'),
              ],
            ),
          ),
        ),
        Expanded(
          child: Focus(
            focusNode: focus,
            autofocus: true,
            onKeyEvent: key,
            onFocusChange: (hasFocus) {
              if (!hasFocus) game.heldDuck = false;
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                focus.requestFocus();
                if (game.sim.crashed) {
                  restart();
                } else {
                  game.jump();
                }
              },
              child: Stack(
                children: [
                  GameWidget(
                    key: ObjectKey(game),
                    game: game,
                    autofocus: false,
                  ),
                  live(
                    (context) => !(game.sim.crashed || game.userPaused)
                        ? const SizedBox.shrink()
                        : Center(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      game.sim.crashed
                                          ? 'Fim de jogo'
                                          : 'Pausado',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: game.sim.crashed
                                          ? restart
                                          : pause,
                                      child: Text(
                                        game.sim.crashed
                                            ? 'Jogar novamente'
                                            : 'Retomar',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.classic) TouchControls(game: game, focus: focus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            widget.classic
                ? 'Toque / Espaço / ↑: pular · ↓: abaixar · P: pausa'
                : '${widget.store.config.controller.label} · semente ${game.sim.config.seed}',
          ),
        ),
        if (audioError != null) Text(audioError!),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.classic ? 'Modo Clássico' : 'Laboratório de Controle',
        ),
        actions: [
          live(
            (context) => IconButton(
              onPressed: pause,
              tooltip: game.userPaused ? 'Retomar' : 'Pausar',
              icon: Icon(game.userPaused ? Icons.play_arrow : Icons.pause),
            ),
          ),
          IconButton(
            onPressed: restart,
            tooltip: 'Reiniciar',
            icon: const Icon(Icons.replay),
          ),
        ],
      ),
      body: SafeArea(
        child: widget.classic
            ? arena
            : ListView(
                children: [
                  SizedBox(height: 320, child: arena),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: LabPanel(
                      store: widget.store,
                      onChanged: () {
                        game.change(widget.store.config);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
