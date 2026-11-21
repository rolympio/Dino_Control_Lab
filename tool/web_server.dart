import 'dart:io';
import 'dart:math' as math;

Future<HttpServer> serveDirectory(Directory root, int port, String base) async {
  if (!base.startsWith('/') || !base.endsWith('/')) {
    throw ArgumentError('Base path must start and end with /.');
  }
  final directory = root.absolute.uri;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  server.listen((request) async {
    final response = request.response;
    try {
      response.headers.set('Cache-Control', 'no-cache');
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        return;
      }
      if (base != '/' && request.uri.path == base.substring(0, base.length - 1)) {
        response.statusCode = HttpStatus.movedPermanently;
        response.headers.set('Location', base);
        return;
      }
      if (!request.uri.path.startsWith(base)) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      var relative = request.uri.path.substring(base.length);
      if (relative.isEmpty) relative = 'index.html';
      final uri = directory.resolve(relative);
      if (!uri.toString().startsWith(directory.toString())) {
        response.statusCode = HttpStatus.forbidden;
        return;
      }
      final file = File.fromUri(uri);
      if (!await file.exists()) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final extension = file.path.split('.').last.toLowerCase();
      response.headers.set('Content-Type', switch (extension) {
        'html' => 'text/html; charset=utf-8',
        'js' => 'application/javascript',
        'wasm' => 'application/wasm',
        'json' => 'application/json',
        'css' => 'text/css',
        'wav' => 'audio/wav',
        'png' => 'image/png',
        'svg' => 'image/svg+xml',
        'ico' => 'image/x-icon',
        'ttf' => 'font/ttf',
        'otf' => 'font/otf',
        _ => 'application/octet-stream',
      });
      response.headers.set('Accept-Ranges', 'bytes');
      final length = await file.length();
      var start = 0, end = length - 1;
      final range = request.headers.value('Range');
      if (range != null) {
        final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range);
        final first = match?.group(1) ?? '';
        final last = match?.group(2) ?? '';
        if (match == null || (first.isEmpty && last.isEmpty)) {
          response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          response.headers.set('Content-Range', 'bytes */$length');
          return;
        }
        if (first.isEmpty) {
          start = math.max(0, length - (int.tryParse(last) ?? 0));
        } else {
          start = int.tryParse(first) ?? length;
          if (last.isNotEmpty) end = math.min(end, int.tryParse(last) ?? -1);
        }
        if (start >= length || end < start) {
          response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          response.headers.set('Content-Range', 'bytes */$length');
          return;
        }
        response.statusCode = HttpStatus.partialContent;
        response.headers.set('Content-Range', 'bytes $start-$end/$length');
      }
      response.contentLength = math.max(0, end - start + 1);
      if (request.method == 'GET') await response.addStream(file.openRead(start, end + 1));
    } on FileSystemException {
      response.statusCode = HttpStatus.internalServerError;
    } finally {
      await response.close();
    }
  });
  return server;
}

Future<void> main(List<String> arguments) async {
  final root = Directory(arguments.firstOrNull ?? 'build/web');
  if (!File('${root.path}/index.html').existsSync()) {
    stderr.writeln('Web build missing. Run tool/build-web.ps1 first.');
    exitCode = 1;
    return;
  }
  final port = arguments.length > 1 ? int.parse(arguments[1]) : 8080;
  final base = arguments.length > 2 ? arguments[2] : '/';
  final server = await serveDirectory(root, port, base);
  stdout.writeln('Dino Control Lab: http://127.0.0.1:${server.port}$base');
  stdout.writeln('Open this address in Edge, Chrome or Firefox. Ctrl+C stops the server.');
}
