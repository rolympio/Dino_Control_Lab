#!/usr/bin/env node
// Diagnostico estatico de um bundle web compilado (pasta ou .zip).
// Uso: node inspect_web_bundle.js <pasta_ou_zip> [--json]
// Detecta causas comuns de tela branca: base href errado, entrypoint ausente ou
// truncado, dependencia de CDN, service worker antigo, assets e PWA.
// Node puro, sem dependencias: roda no Windows do usuario e no Sandbox.
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const target = process.argv[2];
if (!target) { console.error('uso: node inspect_web_bundle.js <pasta_ou_zip> [--json]'); process.exit(2); }
const asJson = process.argv.includes('--json');
const findings = [];
const info = [];
const meta = {};
const add = (sev, id, msg) => findings.push({ sev, id, msg });

// ---------- ZIP sem dependencias ----------
function zipEntries(buf) {
  let eocd = -1;
  const floor = Math.max(0, buf.length - 66000);
  for (let i = buf.length - 22; i >= floor; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error('EOCD nao encontrado (zip invalido, spanned ou Zip64)');
  const count = buf.readUInt16LE(eocd + 10);
  let off = buf.readUInt32LE(eocd + 16);
  const entries = [];
  for (let n = 0; n < count; n++) {
    if (off + 46 > buf.length || buf.readUInt32LE(off) !== 0x02014b50) break;
    const method = buf.readUInt16LE(off + 10);
    const csize = buf.readUInt32LE(off + 20);
    const usize = buf.readUInt32LE(off + 24);
    const fnLen = buf.readUInt16LE(off + 28);
    const exLen = buf.readUInt16LE(off + 30);
    const cmLen = buf.readUInt16LE(off + 32);
    const lho = buf.readUInt32LE(off + 42);
    const name = buf.toString('utf8', off + 46, off + 46 + fnLen);
    entries.push({ name, method, csize, usize, lho });
    off += 46 + fnLen + exLen + cmLen;
  }
  return { entries, buf };
}
function zipRead(z, e) {
  const b = z.buf;
  if (b.readUInt32LE(e.lho) !== 0x04034b50) throw new Error('local header invalido em ' + e.name);
  const fnLen = b.readUInt16LE(e.lho + 26), exLen = b.readUInt16LE(e.lho + 28);
  const s = e.lho + 30 + fnLen + exLen;
  const raw = b.subarray(s, s + e.csize);
  return e.method === 0 ? Buffer.from(raw) : zlib.inflateRawSync(raw);
}

// ---------- coleta normalizada ----------
const loaded = new Map();
let list = [];
const st = fs.statSync(target);
if (st.isDirectory()) {
  const walk = (d, rel) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name), r = rel ? rel + '/' + e.name : e.name;
      if (e.isDirectory()) walk(p, r); else list.push({ name: r, size: fs.statSync(p).size, p });
    }
  };
  walk(target, '');
  Object.assign(meta, { kind: 'pasta', path: path.resolve(target), total: list.length });
} else {
  const buf = fs.readFileSync(target);
  const z = zipEntries(buf);
  list = z.entries.filter(e => !e.name.endsWith('/')).map(e => ({ name: e.name, size: e.usize }));
  for (const n of ['index.html', 'flutter_bootstrap.js', 'manifest.json', 'version.json', 'flutter_service_worker.js']) {
    const hit = z.entries.find(x => x.name === n || x.name.endsWith('/' + n));
    if (hit) try { loaded.set(n, zipRead(z, hit).toString('utf8')); } catch (_) {}
  }
  Object.assign(meta, { kind: 'zip', path: path.resolve(target), total: list.length });
}
const bytesTotal = list.reduce((a, f) => a + (f.size || 0), 0);
const base = n => list.filter(f => f.name.split('/').pop() === n)
  .reduce((a, f) => Math.max(a, f.size || 0), -1);
const has = n => base(n) >= 0;
const any = re => list.some(f => re.test(f.name));
const text = n => {
  if (loaded.has(n)) return loaded.get(n);
  const hit = list.find(f => f.name.split('/').pop() === n);
  if (!hit || !hit.p) return null;
  try { return fs.readFileSync(hit.p, 'utf8'); } catch (_) { return null; }
};

info.push({ check: 'tamanho total', value: (bytesTotal / 1048576).toFixed(1) + ' MB' });

// ---------- engine ----------
function detectEngine() {
  if (has('flutter_bootstrap.js') || has('main.dart.js')) return 'flutter';
  if (any(/\.wasm\.js$/) && any(/loader\.js$/)) return 'unity-webgl';
  if (any(/\.pck$/) || /\.godot$/.test(meta.path)) return 'godot';
  if (has('index.html') && any(/assets\/index-.*\.js$/)) return 'vite/react';
  if (any(/\.wasm$/)) return 'webassembly (generico)';
  return 'desconhecido';
}
const engine = detectEngine();
info.push({ check: 'engine', value: engine });

// ---------- HTML ----------
const html = text('index.html');
if (!has('index.html')) {
  add('CRITICO', 'sem-index', 'index.html ausente: nada para servir. A compilacao escreve um diretorio inteiro; provavelmente o bundle foi copiado pela metade ou o caminho esta errado.');
}
if (html) {
  const bh = (html.match(/<base[^>]+href=["']([^"']*)["']/i) || [])[1];
  if (bh === undefined) info.push({ check: 'base-href', value: 'ausente (relativo, ok em qualquer subpasta)' });
  else if (bh === '/') add('ALTO', 'base-href-raiz', '<base href="/"> so funciona na RAIZ do dominio. Em subpasta (GitHub Pages /repo/, hospedagem compartilhada) vira tela branca com 404 de bootstrap/main.dart.js. Rebuild: --base-href=/subpasta/');
  else info.push({ check: 'base-href', value: bh });
  if (/file:\/\/\//i.test(html)) add('ALTO', 'file-urls', 'URLs file:// no HTML: este bundle nao e portavel, so abre nesta maquina (caminho absoluto do build de debug).');
  const scripts = [...html.matchAll(/<script[^>]+src=["']([^"']+)["']/gi)].map(m => m[1]);
  for (const s of scripts) {
    if (/^https?:/i.test(s)) info.push({ check: 'script externo', value: s });
    else if (!has(s.split('/').pop())) add('CRITICO', 'script-faltando', 'script referenciado no HTML nao esta no bundle: ' + s);
  }
  if (engine === 'flutter' && !scripts.some(s => /flutter_bootstrap\.js|main\.dart\.js|require\.js/i.test(s))) {
    add('CRITICO', 'sem-entrypoint', 'HTML sem flutter_bootstrap.js nem main.dart.js: o navegador nao tem o que executar.');
  }
  if (!/<meta[^>]+name=["']viewport["']/i.test(html)) add('BAIXO', 'sem-viewport', 'sem meta viewport: layout de celular errado/zoom indevido na web mobile.');
  const t = (html.match(/<title>([^<]*)<\/title>/i) || [])[1];
  if (t) info.push({ check: 'title', value: t });
}

// ---------- bootstrap Flutter ----------
const boot = text('flutter_bootstrap.js') || '';
if (boot) {
  const cdnRef = /gstatic\.com|unpkg\.com|jsdelivr|cdn\.flutter\.dev|storage\.googleapis\.com/i.test(boot);
  const local = /"useLocalCanvasKit"\s*:\s*true/.test(boot) || /useLocalCanvasKit\s*[:=]\s*!0/.test(boot);
  if (cdnRef && !local && !any(/canvaskit\.wasm$/)) add('CRITICO', 'canvaskit-cdn-sem-copias', 'CanvasKit aponta para CDN e nao ha copia local no bundle: offline ou CDN bloqueado = tela branca.');
  else if (cdnRef && local) info.push({ check: 'canvaskit', value: 'local (useLocalCanvasKit: true), CDN apenas fallback' });
  else if (cdnRef) add('MEDIO', 'canvaskit-cdn', 'bootstrap referencia CDN havendo copia local: confirme em runtime qual caminho e escolhido.');
  else info.push({ check: 'canvaskit', value: 'sem referencia a CDN' });
  const main = base('main.dart.js');
  if (main < 0) add('CRITICO', 'sem-main-dart-js', 'main.dart.js ausente: a compilacao nao produziu entrypoint (build incompleto ou copiado pela metade).');
  else if (main < 100 * 1024) add('ALTO', 'main-truncado', 'main.dart.js com apenas ' + (main / 1024).toFixed(0) + ' KB: build provavelmente truncado/interrompido.');
  else info.push({ check: 'main.dart.js', value: (main / 1048576).toFixed(2) + ' MB' });
  if (has('flutter_service_worker.js')) {
    const sw = text('flutter_service_worker.js') || '';
    if (/unregister\(\)/.test(sw)) info.push({ check: 'service worker', value: 'se desregistra (estilo novo do Flutter)' });
    else add('MEDIO', 'sw-cache', 'service worker de cache presente: apos publicar, a versao antiga pode continuar servindo tela branca. Teste em janela anonima e valide o cache-busting.');
  }
  if (/dart_sdk\.js|main\.mjs/.test(boot) || has('dart_sdk.js')) info.push({ check: 'wasm', value: 'build dart2wasm: exige servidor com Content-Type application/wasm' });
}
if (engine === 'flutter' && !has('version.json')) add('ALTO', 'sem-version-json', 'version.json ausente: o bootstrap le esse arquivo no boot e falha antes de desenhar.');
const wasm = list.filter(f => /\.wasm$/.test(f.name));
if (wasm.length) info.push({ check: '.wasm', value: wasm.length + ' arquivo(s); servidor deve enviar Content-Type: application/wasm' });

// ---------- PWA / manifest ----------
if (has('manifest.json')) {
  const raw = text('manifest.json');
  try {
    const m = JSON.parse(raw);
    info.push({ check: 'pwa', value: (m.name || '?') + ' / display=' + (m.display || '?') });
    const defaults = ['A new Flutter project', 'Flutter Web App'];
    if (m.description && defaults.some(d => m.description.includes(d))) add('BAIXO', 'manifest-template', 'manifest.json ainda com metadados do template (' + m.description + ').');
    const icons = (m.icons || []).filter(i => i.src && !/^https?:/i.test(i.src));
    for (const i of icons) if (!has(i.src.split('/').pop())) add('MEDIO', 'icone-faltando', 'icone do manifest ausente no bundle: ' + i.src);
  } catch (e) { add('MEDIO', 'manifest-invalido', 'manifest.json ilegivel: ' + e.message); }
}
if (has('index.html') && has('favicon.png') === false && engine === 'flutter') info.push({ check: 'favicon', value: 'ausente (irrelevante para abrir)' });

// ---------- assets ----------
const assets = list.filter(f => /^assets\//.test(f.name));
info.push({ check: 'assets/', value: assets.length + ' arquivo(s)' });
const fontManifest = text('assets/FontManifest.json');
if (fontManifest === null && engine === 'flutter' && has('assets/AssetManifest.json')) info.push({ check: 'AssetManifest', value: 'presente' });
if (has('assets/AssetManifest.json') && (text('assets/AssetManifest.json') || '').length < 4) add('MEDIO', 'assetmanifest-vazio', 'AssetManifest.json vazio: app com flutter: assets: declarado mas sem assets empacotados (falha de primeira tela em quem carrega audio/imagem no boot).');

const big = list.filter(f => f.size > 5 * 1024 * 1024).sort((a, b) => b.size - a.size);
if (big.length) info.push({ check: 'pesados', value: big.slice(0, 4).map(f => f.name + ' (' + (f.size / 1048576).toFixed(1) + ' MB)').join(', ') });

// ---------- saida ----------
if (asJson) console.log(JSON.stringify({ meta, info, findings }, null, 2));
else {
  console.log('# bundle: ' + meta.path + '  (' + meta.kind + ', ' + meta.total + ' arquivos)');
  for (const i of info) console.log('  . ' + i.check + ': ' + i.value);
  console.log('');
  if (!findings.length) console.log('Nenhum problema estatico detectado. Lembre: bundle sao + servidor errado = tela branca. Servir com http:// antes de julgar (file:// nao funciona de proposito no Flutter web).');
  for (const f of findings) console.log('[' + f.sev + '] ' + f.id + ': ' + f.msg);
}
const fatal = f => f.sev === 'CRITICO' || (f.sev === 'ALTO' && f.id !== 'base-href-raiz');
process.exit(findings.some(f => f.sev === 'CRITICO') ? 1 : 0);
void fatal;
