import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';

import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'session.dart';

Future<String> exportSession(
  Session session,
  String extension,
  Rect origin,
) async {
  final content = extension == 'csv' ? session.csv : session.json;
  final name = 'dino_${session.id}.$extension';
  final bytes = Uint8List.fromList(utf8.encode(content));
  if (Platform.isAndroid || Platform.isIOS) {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$name';
    await File(path).writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], sharePositionOrigin: origin),
    );
    return 'Arquivo salvo em $path';
  }
  final destination = await getSaveLocation(suggestedName: name);
  if (destination == null) return 'Exportação cancelada';
  await XFile.fromData(
    bytes,
    name: name,
    mimeType: extension == 'csv' ? 'text/csv' : 'application/json',
  ).saveTo(destination.path);
  return 'Arquivo salvo em ${destination.path}';
}
