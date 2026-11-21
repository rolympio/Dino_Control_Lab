// Servidor estatico minimo para validar o bundle flutter build web.
// Uso: node web-server.js <porta> <dirRaiz> [subpath] [coop]
//   subpath -> serve as sob /app/ para simular GitHub Pages / pasta filhos
//   coop    -> envia cabecalhos Cross-Origin-Isolation (necessario p/ skwasm threads)
const http = require('http');
const fs = require('fs');
const path = require('path');

const port = parseInt(process.argv[2] || '8765', 10);
const root = path.resolve(process.argv[3] || '.');
const sub = (process.argv[4] || '').replace(/^\/+|\/+$/g, '');
const coop = process.argv[5] === 'coop';

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.css': 'text/css',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.wav': 'audio/wav',
  '.bin': 'application/octet-stream',
  '.map': 'application/json',
  '.frag': 'text/plain',
  '.svg': 'image/svg+xml',
};

http
  .createServer((req, res) => {
    let urlPath = decodeURIComponent(req.url.split('?')[0]);
    if (sub) {
      if (urlPath === '/' ) { res.writeHead(302, { Location: '/' + sub + '/' }); res.end(); return; }
      if (!urlPath.startsWith('/' + sub)) { res.writeHead(404); res.end('fora do subpath'); return; }
      urlPath = urlPath.slice(('/' + sub).length) || '/';
    }
    if (urlPath.endsWith('/')) urlPath += 'index.html';
    const file = path.join(root, path.normalize(urlPath));
    if (!file.startsWith(root)) { res.writeHead(403); res.end('negado'); return; }
    const headers = { 'Cache-Control': 'no-store' };
    if (coop) {
      headers['Cross-Origin-Opener-Policy'] = 'same-origin';
      headers['Cross-Origin-Embedder-Policy'] = 'require-corp';
    }
    fs.readFile(file, (err, data) => {
      if (err) {
        console.log('404 ' + urlPath);
        res.writeHead(404, headers);
        res.end('nao encontrado: ' + urlPath);
        return;
      }
      headers['Content-Type'] = mime[path.extname(file).toLowerCase()] || 'application/octet-stream';
      res.writeHead(200, headers);
      res.end(data);
    });
  })
  .listen(port, '0.0.0.0', () =>
    console.log('servindo ' + root + ' em http://127.0.0.1:' + port + '/' + (sub ? sub + '/' : '') + (coop ? ' (COOP/COEP ligado)' : '')),
  );
