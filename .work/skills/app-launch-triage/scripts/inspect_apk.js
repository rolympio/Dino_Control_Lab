#!/usr/bin/env node
// Diagnóstico de APK sem Android SDK: ABIs, debug vs release, assinaturas,
// minSdk/targetSdk (lidos do AndroidManifest.xml binário) e tamanho.
// Uso: node inspect_apk.js <arquivo.apk> [--json]
const fs = require('fs');
const zlib = require('zlib');

const file = process.argv[2];
if (!file) { console.error('uso: node inspect_apk.js <arquivo.apk> [--json]'); process.exit(2); }
const asJson = process.argv.includes('--json');
let buf;
try { buf = fs.readFileSync(file); }
catch (e) { console.error('nao consegui ler ' + file + ' (' + e.code + '). Confirme o caminho: flutter build apk gera build/app/outputs/flutter-apk/*.apk'); process.exit(2); }
const findings = [], info = [{ check: 'arquivo', value: fs.statSync(file).size + ' bytes' }];
const add = (sev, id, msg) => findings.push({ sev, id, msg });

// ---------- ZIP central directory ----------
let eocd = -1;
for (let i = buf.length - 22; i >= Math.max(0, buf.length - 66000); i--) {
  if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
}
if (eocd < 0) { console.error('não parece um APK/zip válido (EOCD ausente)'); process.exit(2); }
const count = buf.readUInt16LE(eocd + 10);
let off = buf.readUInt32LE(eocd + 16);
const entries = [];
for (let n = 0; n < count; n++) {
  if (buf.readUInt32LE(off) !== 0x02014b50) break;
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
function read(e) {
  if (buf.readUInt32LE(e.lho) !== 0x04034b50) throw new Error('local header inválido: ' + e.name);
  const fnLen = buf.readUInt16LE(e.lho + 26), exLen = buf.readUInt16LE(e.lho + 28);
  const s = e.lho + 30 + fnLen + exLen;
  const raw = buf.subarray(s, s + e.csize);
  return e.method === 0 ? Buffer.from(raw) : zlib.inflateRawSync(raw);
}

// ---------- AXML (AndroidManifest.xml binário) ----------
function parseAxml(b) {
  const out = { attrs: {}, elements: [], package: null };
  const pool = { strings: [] };
  let p = 8; // pula ResChunk_header do arquivo
  const u16 = o => b.readUInt16LE(o), u32 = o => b.readUInt32LE(o);
  while (p + 8 <= b.length) {
    const type = u16(p), size = u32(p + 4);
    if (size < 8 || p + size > b.length) break;
    if (type === 0x0001) {
      const n = u32(p + 8), flags = u32(p + 16), stringsStart = u32(p + 20);
      const utf8 = (flags & (1 << 8)) !== 0;
      const base = p + stringsStart;
      for (let i = 0; i < n; i++) {
        const so = p + 28 + i * 4;
        if (so + 4 > b.length) break;
        let s = base + u32(so);
        if (utf8) {
          const dec = o => { let v = b[o]; if (v & 0x80) v = ((v & 0x7f) << 8) | b[o + 1]; return v; };
          let lenA = dec(s); s += lenA & 0x80 ? 2 : 1;
          let blen = dec(s); s += blen & 0x80 ? 2 : 1;
          pool.strings.push(b.toString('utf8', s, s + blen));
        } else {
          let lenA = u16(s); s += (lenA & 0x8000) ? 4 : 2;
          pool.strings.push(b.toString('utf16le', s, s + lenA * 2));
        }
      }
    } else if (type === 0x0102) { // start element
      const h = p + 16; // ResXMLTree_attrExt: ns(4) name(4) attrStart(2) attrSize(2) attrCount(2) idIndex(2) styleIndex(2)
      const nameIdx = u32(h + 4); // h+0 e namespace (-1 quando sem prefixo)
      const attrStart = u16(h + 8), attrCount = u16(h + 12);
      const elName = pool.strings[nameIdx] || ('#' + nameIdx);
      out.elements.push(elName);
      for (let a = 0; a < attrCount; a++) {
        const ao = p + 16 + attrStart + a * 20;
        if (ao + 20 > b.length) break;
        const aName = pool.strings[u32(ao + 4)] || '?';
        const rawIdx = u32(ao + 8);
        const size = u16(ao + 12), dataType = b[ao + 15], data = u32(ao + 16);
        let value;
        if (rawIdx !== 0xffffffff && pool.strings[rawIdx] !== undefined) value = pool.strings[rawIdx];
        else if (dataType === 0x03) value = pool.strings[data];   // TYPE_STRING por indice
        else if (dataType === 0x10) value = data | 0;             // TYPE_INT_DEC
        else if (dataType === 0x12) value = data !== 0;           // TYPE_INT_BOOLEAN
        else if (dataType === 0x01) value = '@0x' + data.toString(16); // TYPE_REFERENCE
        else if (dataType === 0x02) value = '0x' + data.toString(16); // TYPE_ATTRIBUTE
        else value = undefined;
        if (value !== undefined) out.attrs[aName] = value;
        if (aName === 'name' && elName === 'activity') out.activityName = value;
        void size;
      }
      if (elName === 'manifest' && out.attrs.package) out.package = out.attrs.package;
    }
    p += size;
  }
  return out;
}
let axml = null;
const mf = entries.find(e => e.name === 'AndroidManifest.xml');
if (mf) { try { axml = parseAxml(read(mf)); } catch (e) { add('MEDIO', 'axml', 'falha ao ler AndroidManifest binário: ' + e.message); } }

// ---------- checagens ----------
const abis = [...new Set(entries.filter(e => /^lib\/[^/]+\//.test(e.name)).map(e => e.name.split('/')[1]))].sort();
info.push({ check: 'ABIs', value: abis.length ? abis.join(', ') : 'nenhuma biblioteca nativa' });
if (!abis.length) add('ALTO', 'sem-abi', 'APK sem libs/ : provavelmente asset pack, split incompleto ou build corrompido.');
const soPorAbi = {};
for (const e of entries) if (/^lib\/[^/]+\//.test(e.name)) (soPorAbi[e.name.split('/')[1]] ||= []).push(e.name.split('/').pop());
info.push({ check: 'libflutter.so por ABI', value: Object.entries(soPorAbi).map(([k, v]) => k + '=' + (v.includes('libflutter.so') ? 'sim' : 'NAO')).join(', ') || '-' });
for (const [abi, libs] of Object.entries(soPorAbi)) {
  if (!libs.includes('libflutter.so') && !libs.includes('libapp.so')) add('MEDIO', 'abi-incompleta', abi + ' sem libflutter/libapp: nessa ABI o app aborta no start.');
}
const debug = entries.some(e => /kernel_blob\.bin$/.test(e.name));
const release = entries.some(e => /libapp\.so$/.test(e.name));
info.push({ check: 'modo', value: debug ? 'DEBUG (JIT, kernel_blob)' : release ? 'RELEASE (AOT, libapp.so)' : 'indeterminado' });
if (debug) {
  add('ALTO', 'apk-debug', 'APK de debug: não distribuível, maior, e exige perfil de execução compatível. Para validar em aparelho use `flutter build apk` (release) ou `--profile`.');
}
const sigv1 = entries.filter(e => /^META-INF\/.*\.(RSA|DSA|EC|SF|MF)$/i.test(e.name)).map(e => e.name.split('/').pop());
info.push({ check: 'assinatura v1 (JAR)', value: sigv1.length ? sigv1.join(', ') : 'ausente' });
// APK Signing Block: fica logo antes do central directory.
function signingBlock() {
  const cd = buf.readUInt32LE(eocd + 16);
  const magic = Buffer.from('APK Sig Block 42');
  const at = cd - 16;
  if (at < 0 || buf.toString('latin1', at, cd) !== magic.toString('latin1')) return null;
  let len;
  try { len = Number(buf.readBigUInt64LE(cd - 24)); } catch (_) { return null; }
  // bloco = [u64 size][pairs][u64 size][magic 16]; size = tudo depois dos primeiros 8 bytes.
  const start = cd - len - 8;
  if (!Number.isFinite(len) || len < 32 || start < 0) return null;
  let firstOk = false;
  try { firstOk = buf.readBigUInt64LE(start) === BigInt(len); } catch (_) {}
  if (!firstOk) return { ids: [], offsetProblem: true };
  const ids = [];
  let p = start + 8;
  while (p + 12 <= cd - 24) {
    const pairLen = Number(buf.readBigUInt64LE(p));
    const id = buf.readUInt32LE(p + 8);
    if (!Number.isFinite(pairLen) || pairLen < 4) break;
    ids.push(id);
    p += 8 + pairLen;
  }
  return { ids };
}
const sb = signingBlock();
const NAMES = { 0x7109871a: 'v2', 0xf05368c0: 'v3', 0x1b5f4fd0: 'v3.1', 0x42dfb936: 'v4' };
if (!sb) {
  if (!sigv1.length) add('CRITICO', 'sem-assinatura', 'APK sem v1 e sem APK Signing Block: o Android recusa instalar (INSTALL_PARSE_FAILED_NO_CERTIFICATES).');
} else {
  const schemes = sb.ids.map(i => NAMES[i] || ('0x' + i.toString(16)));
  info.push({ check: 'assinatura v2+', value: schemes.length ? schemes.join(', ') : 'bloco presente, sem esquema conhecido' });
}
const debugKey = entries.some(e => /META-INF.*DEBUG\.(RSA|SF|MF)$/i.test(e.name));
if (debug || debugKey) info.push({ check: 'keystore', value: debug ? 'debug (não publicável)' : 'indícios de chave de debug' });
if (axml) {
  if (axml.package) info.push({ check: 'package', value: axml.package });
  const mn = axml.attrs.minSdkVersion, tg = axml.attrs.targetSdkVersion;
  info.push({ check: 'minSdk', value: mn ?? '?' });
  info.push({ check: 'targetSdk', value: tg ?? '?' });
  if (typeof mn === 'number' && mn > 23) add('MEDIO', 'minsdk-alto', 'minSdk ' + mn + ' exclui aparelhos com Android < ' + (mn >= 31 ? '12' : mn >= 30 ? '11' : mn >= 29 ? '10' : mn >= 26 ? '8.0' : '7.0') + '. Confirme a base de usuários-alvo.');
  if (axml.attrs['android:extractNativeLibs'] !== undefined) info.push({ check: 'extractNativeLibs', value: axml.attrs['android:extractNativeLibs'] });
if (axml.attrs.extractNativeLibs !== undefined) info.push({ check: 'extractNativeLibs', value: axml.attrs.extractNativeLibs });
  if (axml.activityName) info.push({ check: 'launcher', value: axml.activityName });
  const perms = axml.elements.filter(e => e === 'uses-permission').length;
  if (perms) info.push({ check: 'permissões declaradas', value: String(perms) });
}
if (entries.some(e => e.name.startsWith('assets/flutter_assets/')) === false && debug) add('MEDIO', 'sem-assets', 'sem assets/flutter_assets: engine inicia e cai na tela preta.');
if (fs.statSync(file).size > 150 * 1024 * 1024) add('BAIXO', 'grande', 'APK acima de 150 MB: difícil de transferir para o aparelho; use release/AAB.');

if (asJson) console.log(JSON.stringify({ info, findings }, null, 2));
else {
  console.log('# APK: ' + fs.realpathSync(file));
  for (const i of info) console.log('  . ' + i.check + ': ' + i.value);
  console.log('');
  if (!findings.length) console.log('Nenhum problema estático detectado.');
  for (const f of findings) console.log('[' + f.sev + '] ' + f.id + ' — ' + f.msg);
}
process.exit(findings.some(f => f.sev === 'ALTO' || f.sev === 'CRITICO') ? 1 : 0);
