import 'package:material_ui/material_ui.dart';

import '../data/store.dart';
import 'controls.dart';
import 'game_page.dart';
import 'results.dart';
import 'saved_settings.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    void open(Widget page) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page));
    return Scaffold(
      appBar: AppBar(title: const Text('Dino Control Lab')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (store.notice case final notice?)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(notice),
                      trailing: IconButton(
                        tooltip: 'Dispensar aviso',
                        icon: const Icon(Icons.close),
                        onPressed: store.dismissNotice,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                Text(
                  'Pule. Experimente. Compare.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jogue o clássico ou explore como quatro controladores enfrentam o mesmo percurso.',
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () => open(GamePage(store: store, classic: true)),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Jogar — Modo Clássico'),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Laboratório de Controle'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(GamePage(store: store, classic: false)),
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Personagens e Física'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(PhysicsPage(store: store)),
                ),
                ListTile(
                  leading: const Icon(Icons.show_chart),
                  title: const Text('Resultados e Gráficos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(ResultsPage(store: store)),
                ),
                ListTile(
                  leading: const Icon(Icons.bookmarks_outlined),
                  title: const Text('Experimentos Salvos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(SavedPage(store: store)),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Configurações'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(SettingsPage(store: store)),
                ),
                const SizedBox(height: 32),
                Text('Recorde pessoal: ${store.best} · Disponível offline'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PhysicsPage extends StatefulWidget {
  const PhysicsPage({super.key, required this.store});
  final AppStore store;
  @override
  State<PhysicsPage> createState() => _PhysicsPageState();
}

class _PhysicsPageState extends State<PhysicsPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Personagens e Física')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PhysicsControls(
            config: widget.store.config,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
    ),
  );
}
