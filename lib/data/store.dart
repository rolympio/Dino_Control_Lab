import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/config.dart';
import '../domain/json_values.dart';
import 'session.dart';

class AppStore extends ChangeNotifier {
  AppStore(this.preferences) {
    _restore('best', () => best = jsonInt(preferences.get('best'), min: 0));
    _restore('sound', () {
      final value = preferences.get('sound');
      if (value is! bool) throw const FormatException('Som inválido');
      sound = value;
    });
    _restore(
      'theme',
      () => theme = jsonEnum(preferences.get('theme'), ThemeMode.values),
    );
    _restore('sessions', () {
      final history = jsonList(
        jsonDecode(jsonString(preferences.get('sessions'))),
      );
      for (final item in history) {
        try {
          sessions.add(Session.fromJson(jsonObject(item)));
        } on FormatException {
          _warn('Sessões inválidas foram ignoradas.');
        }
      }
      if (sessions.length > 20) {
        sessions.removeRange(0, sessions.length - 20);
        _warn('Histórico limitado às 20 sessões mais recentes.');
      }
    });
    _restore('experiments', () {
      final saved = jsonObject(
        jsonDecode(jsonString(preferences.get('experiments'))),
      );
      for (final entry in saved.entries) {
        try {
          experiments[entry.key] = LabConfig.fromJson(jsonObject(entry.value));
        } on FormatException {
          _warn('Experimentos inválidos foram ignorados.');
        }
      }
    });
  }
  final SharedPreferences preferences;
  LabConfig config = LabConfig();
  int best = 0;
  bool sound = true;
  ThemeMode theme = ThemeMode.system;
  String? notice;
  final List<Session> sessions = [];
  final Map<String, LabConfig> experiments = {};
  Future<void> _pending = Future.value();

  void _warn(String message) {
    if (!(notice?.contains(message) ?? false)) {
      notice = notice == null ? message : '$notice $message';
    }
  }

  void _restore(String key, void Function() read) {
    if (!preferences.containsKey(key)) return;
    try {
      read();
    } on FormatException {
      _warn('Dados locais inválidos ($key) foram ignorados.');
    }
  }

  Future<void> _write(String key, Future<bool> Function() write) async {
    try {
      if (!await write()) throw StateError('Gravação recusada');
    } catch (_) {
      _warn(
        'Não foi possível salvar $key neste dispositivo. Exporte os dados antes de sair.',
      );
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    _pending = _pending.then((_) async {
      try {
        await action();
      } catch (_) {
        _warn(
          'Não foi possível salvar os dados. Exporte a sessão antes de sair.',
        );
      }
      notifyListeners();
    });
    return _pending;
  }

  Future<void> addSession(Session session) {
    sessions.add(session);
    if (sessions.length > 20) {
      sessions.removeRange(0, sessions.length - 20);
      _warn('Histórico limitado às 20 sessões mais recentes.');
    }
    if (session.classic && session.score > best) best = session.score;
    notifyListeners();
    return _enqueue(() async {
      final encoded = <String>[];
      var bytes = 4; // UTF-16 brackets.
      for (final item in sessions.reversed) {
        final record = jsonEncode(item.toJson());
        final size = record.length * 2 + (encoded.isEmpty ? 0 : 2);
        if (bytes + size > 2 * 1024 * 1024) {
          _warn(
            'Histórico salvo limitado a 2 MiB. Exporte a sessão atual antes de sair.',
          );
          continue;
        }
        encoded.add(record);
        bytes += size;
      }
      await _write(
        'sessions',
        () => preferences.setString(
          'sessions',
          '[${encoded.reversed.join(',')}]',
        ),
      );
      await _write('best', () => preferences.setInt('best', best));
    });
  }

  Future<void> saveExperiment(String name) {
    experiments[name] = config.copy();
    notifyListeners();
    return _enqueue(
      () => _write(
        'experiments',
        () => preferences.setString(
          'experiments',
          jsonEncode(
            experiments.map((name, config) => MapEntry(name, config.toJson())),
          ),
        ),
      ),
    );
  }

  Future<void> settings({bool? soundEnabled, ThemeMode? themeMode}) {
    if (soundEnabled != null) sound = soundEnabled;
    if (themeMode != null) theme = themeMode;
    notifyListeners();
    return _enqueue(() async {
      await _write('sound', () => preferences.setBool('sound', sound));
      await _write('theme', () => preferences.setString('theme', theme.name));
    });
  }
}
