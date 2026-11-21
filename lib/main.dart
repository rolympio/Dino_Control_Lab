import 'dart:ui' show PlatformDispatcher;

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/store.dart';
import 'ui/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();
  runApp(DinoApp(store: AppStore(await _openPreferences())));
}

/// Storage can be unavailable (blocked site data, private windows, corrupt
/// platform files). The game must still open, without persistence.
Future<SharedPreferences?> _openPreferences() async {
  try {
    return await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 5),
    );
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'dino_control_lab',
        context: ErrorDescription('while opening local storage'),
      ),
    );
    return null;
  }
}

void _installErrorHandlers() {
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'dino_control_lab',
        context: ErrorDescription('outside the widget tree'),
      ),
    );
    return true;
  };
  // Release builds otherwise paint a blank grey box for a failed widget.
  ErrorWidget.builder = (details) => Material(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Algo deu errado nesta tela.\n${details.exceptionAsString()}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
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
