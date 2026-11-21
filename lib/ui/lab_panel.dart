import 'package:material_ui/material_ui.dart';

import '../data/comparison.dart';
import '../data/store.dart';
import '../domain/config.dart';
import 'controls.dart';
import 'fuzzy_editor.dart';
import 'results.dart';

class LabPanel extends StatefulWidget {
  const LabPanel({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;
  @override
  State<LabPanel> createState() => _LabPanelState();
}

class _LabPanelState extends State<LabPanel> {
  bool busy = false;
  ComparisonRunner? runner;
  ComparisonProgress? progress;

  @override
  void dispose() {
    runner?.cancel();
    super.dispose();
  }

  void changed() {
    widget.onChanged();
    setState(() {});
  }

  Future<void> compare() async {
    final comparison = ComparisonRunner(widget.store.config);
    runner = comparison;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      progress = null;
    });
    try {
      final results = await comparison.run(
        onProgress: (value) {
          if (mounted) setState(() => progress = value);
        },
      );
      if (!mounted) return;
      for (final result in results) {
        if (!mounted) return;
        await widget.store.addSession(result);
      }
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResultsPage(store: widget.store),
          ),
        );
      }
    } on ComparisonCancelled {
      // Cancellation leaves the previous results untouched.
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível concluir a comparação: $error'),
          ),
        );
      }
    } finally {
      runner = null;
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.store.config;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeFocus(
          excluding: busy,
          child: AbsorbPointer(
            absorbing: busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<ControllerKind>(
                  initialValue: c.controller,
                  decoration: const InputDecoration(
                    labelText: 'Controlador automático',
                  ),
                  items: ControllerKind.values
                      .map(
                        (k) => DropdownMenuItem(value: k, child: Text(k.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      c.controller = v;
                      changed();
                    }
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: c.seed.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Semente do próximo reinício',
                    helperText: 'Mesma semente + mesma configuração = mesmos obstáculos',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (s) => int.tryParse(s ?? '') == null
                      ? 'Digite um número inteiro'
                      : null,
                  onChanged: (s) {
                    final seed = int.tryParse(s);
                    if (seed != null) c.seed = seed;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Parâmetros — ${c.controller.label}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Only the active controller's settings: each controller
                // reads its own parameters and ignores the others.
                KeyedSubtree(
                  key: ValueKey(c.controller),
                  child: switch (c.controller) {
                    ControllerKind.onOff => NumberControl(
                      label: 'Antecipação ON/OFF (s)',
                      value: c.threshold,
                      min: .08,
                      max: .5,
                      onChanged: (v) {
                        c.threshold = v;
                        changed();
                      },
                    ),
                    ControllerKind.adaptive => NumberControl(
                      label: 'Ganho de adaptação',
                      value: c.adaptation,
                      min: .05,
                      max: 1,
                      onChanged: (v) {
                        c.adaptation = v;
                        changed();
                      },
                    ),
                    ControllerKind.fuzzy => FuzzyEditor(
                      config: c,
                      onChanged: changed,
                    ),
                    ControllerKind.mpc => NumberControl(
                      label: 'Horizonte MPC (s)',
                      value: c.horizon,
                      min: .6,
                      max: 2,
                      onChanged: (v) {
                        c.horizon = v;
                        changed();
                      },
                    ),
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Personagem e física ao vivo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                PhysicsControls(config: c, onChanged: changed),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (busy) ...[
          LinearProgressIndicator(value: progress?.fraction ?? 0),
          const SizedBox(height: 8),
          Text(
            '${progress?.controller.label ?? 'Preparando'} · '
            '${((progress?.fraction ?? 0) * 100).toStringAsFixed(0)}%',
          ),
          TextButton(
            onPressed: runner?.cancel,
            child: const Text('Cancelar comparação'),
          ),
        ],
        FilledButton(
          onPressed: busy ? null : compare,
          child: Text(
            busy ? 'Comparando…' : 'Comparar os quatro controladores (60 s)',
          ),
        ),
        const Text(
          'Cada execução usa a mesma semente e termina na colisão ou em 60 segundos simulados. '
          'Controladores não selecionados usam os últimos parâmetros ajustados neles.',
        ),
      ],
    );
  }
}
