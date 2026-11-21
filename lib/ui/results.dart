import 'package:material_ui/material_ui.dart';

import '../data/export.dart';
import '../data/session.dart';
import '../data/store.dart';
import '../domain/config.dart';
import 'trace_chart.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, required this.store});
  final AppStore store;
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  Session? selected;
  bool exporting = false;
  Future<void> export(String extension) async {
    final session = selected;
    if (session == null) return;
    setState(() => exporting = true);
    try {
      final box = context.findRenderObject() as RenderBox;
      final origin = box.localToGlobal(Offset.zero) & box.size;
      final message = await exportSession(session, extension, origin);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = widget.store.sessions.reversed.toList();
    selected ??= sessions.firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Resultados e Gráficos')),
      body: SafeArea(
        child: sessions.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma sessão concluída. Jogue ou execute uma comparação no laboratório.',
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Selecione uma sessão para inspecionar e exportar.',
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Modo')),
                        DataColumn(label: Text('Semente')),
                        DataColumn(label: Text('Pontos')),
                        DataColumn(label: Text('Tempo (s)')),
                        DataColumn(label: Text('Pulos')),
                        DataColumn(label: Text('Fim')),
                      ],
                      rows: sessions
                          .map(
                            (s) => DataRow(
                              selected: selected == s,
                              onSelectChanged: (_) =>
                                  setState(() => selected = s),
                              cells: [
                                DataCell(
                                  Text(
                                    s.classic
                                        ? 'Clássico'
                                        : s.initial.controller.label,
                                  ),
                                ),
                                DataCell(Text('${s.initial.seed}')),
                                DataCell(Text('${s.score}')),
                                DataCell(Text(s.duration.toStringAsFixed(2))),
                                DataCell(Text('${s.jumps}')),
                                DataCell(Text(s.outcome)),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Altura × tempo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'Arraste para ler cada amostra. A altura é medida em pixels de mundo.',
                  ),
                  TraceChart(key: ValueKey(selected!.id), session: selected!),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      FilledButton(
                        onPressed: exporting ? null : () => export('csv'),
                        child: const Text('Exportar CSV'),
                      ),
                      OutlinedButton(
                        onPressed: exporting ? null : () => export('json'),
                        child: const Text('Exportar JSON completo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CSV: série temporal em 10 Hz. JSON: configuração, semente, ações e alterações por tick, com metadados para reprodução.',
                  ),
                ],
              ),
      ),
    );
  }
}
