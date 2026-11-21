import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/store.dart';
import 'ui/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(await SharedPreferences.getInstance());
  runApp(DinoApp(store: store));
}

class DinoApp extends StatelessWidget {
  const DinoApp({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'Dino Control Lab',
      debugShowCheckedModeBanner: false,
      themeMode: store.theme,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff356449)),
        scaffoldBackgroundColor: const Color(0xfff6f7f3),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffa0d4ad),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff161c18),
      ),
      home: HomePage(store: store),
    ),
  );
}
