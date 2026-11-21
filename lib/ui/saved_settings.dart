import 'package:material_ui/material_ui.dart';

import '../data/store.dart';
import '../domain/config.dart';
import 'game_page.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key, required this.store});
  final AppStore store;
  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final name = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Experimentos Salvos')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Nome do experimento'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await widget.store.saveExperiment(name.text.trim());
              if (mounted) setState(() => name.clear());
            },
            child: const Text('Salvar configuração atual'),
          ),
          const SizedBox(height: 24),
          if (widget.store.experiments.isEmpty)
            const Text('Nenhum experimento salvo.'),
          for (final entry in widget.store.experiments.entries)
            ListTile(
              title: Text(entry.key),
              subtitle: Text(
                '${entry.value.controller.label} · semente ${entry.value.seed}',
              ),
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                widget.store.config = entry.value.copy();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        GamePage(store: widget.store, classic: false),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configurações')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SwitchListTile(
              title: const Text('Efeitos sonoros'),
              value: store.sound,
              onChanged: (v) => store.settings(soundEnabled: v),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<ThemeMode>(
              initialValue: store.theme,
              decoration: const InputDecoration(labelText: 'Tema'),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Sistema'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
              ],
              onChanged: (v) => store.settings(themeMode: v),
            ),
          ],
        ),
      ),
    ),
  );
}
