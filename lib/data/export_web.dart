import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';

import 'session.dart';

Future<String> exportSession(
  Session session,
  String extension,
  Rect origin,
) async {
  final content = extension == 'csv' ? session.csv : session.json;
  final name = 'dino_${session.id}.$extension';
  await XFile.fromData(
    Uint8List.fromList(utf8.encode(content)),
    name: name,
    mimeType: extension == 'csv' ? 'text/csv' : 'application/json',
  ).saveTo(name);
  return 'Download de $name iniciado';
}
