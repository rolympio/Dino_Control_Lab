# Checklist: web não abre

Ordem de teste: **entrega → bundle → código → runtime**. Cada item indica a evidência
que o confirma, porque "talvez" não entra no relatório.

## Entrega (resolve a maioria dos casos)

| Checar | Evidência | Correção |
| --- | --- | --- |
| Abriram `index.html` via duplo clique | URL `file:///...` | Servir a pasta: `python -m http.server 8080 -d build/web` → `http://localhost:8080` |
| Hospedagem existe | `gh api repos/<d>/<r>/pages` → 404; `curl -I https://usuario.github.io/repo/` → 404 | Habilitar Pages ou publicar o conteúdo do bundle |
| Bundle foi publicado de verdade | `git ls-files build/web` vazio; remoto só com README | Publicar artefato (Pages/CI), não commitar `build/` |
| Caminho base errado em subpasta | `inspect_web_bundle.js` → `base: /` | `flutter build web --base-href=/repo/` |
| Servidor próprio em porta ocupada ou fora do ar | `Test-NetConnection localhost -Port 8080` falha | Trocar porta; confirmar que o processo vive (job de fundo do terminal) |
| Proxy/CDN com cache antigo | `curl -I` mostra `age` alto | Invalidar cache ou mudar query de versionamento |

## Bundle

- `main.dart.js` presente e não trivial (alguns KB = build incompleto).
- `flutter_bootstrap.js` presente (Flutter ≥ 3.10) e referenciando o local, não CDN.
- `version.json`, `manifest.json`, `flutter_service_worker.js` presentes.
- `canvaskit/canvaskit.js` + `.wasm` presentes **e** `useLocalCanvasKit: true` no bootstrap
  se o alvo é rodar offline ou atrás de firewall que bloqueie `storage.googleapis.com`.
- Assets de áudio/imagem no bundle: se o app carrega `assets/audio/*.wav` no start e o
  asset sumiu do build (`.gitignore` ou `flutter: assets:` ausente), a primeira tela falha.
- `.wasm` servido com `Content-Type: application/wasm` (servidorzinhos caseiros costumam
  errar; no Chrome isso derruba o boot silenciosamente).

## Código (padrões que dão tela branca sem erro de build)

| Padrão | Por que passa no build | Sintoma |
| --- | --- | --- |
| `import 'dart:io'` em arquivo do grafo web | dart2js permite; DDC recusa | falha só em runtime ao tocar `File`/`Platform` |
| Construção de store antes de `runApp` sem `try/catch` | compila | exceção no boot → página branca |
| `ThemeMode.values.byName(...)` com valor que não existe no enum | compila | `Value not in range` no boot |
| Cast estrito em `fromJson` (`as int` sem validar) | compila | abre-e-fecha quando o schema salvo é antigo |
| `schema_version` lido mas nunca comparado | compila | dados antigos quebram a primeira tela |
| `compute()` pesado no boot | compila | na web roda no mesmo isolate → trava 5–10 s e o usuário fecha |
| `Timer.periodic(100ms)` com trabalho pesado | compila | jank/frames perdidos, sensação de "não abre" |
| Cota de `localStorage` (~5 MB) estourada | compila | `QuotaExceededError` sem `try/catch` mata a thread de UI |
| `!` em valor nulo no primeiro frame (ex.: `selected!`) | compila | redireciona para tela de erro |

## Teste rápido de hipótese

```
node scripts/inspect_web_bundle.js build/web
# se limpo: sirva e abra, não julgue pelo arquivo
python -m http.server 8080 -d build/web
```

No navegador, o que decide o caso: **Console** (exceção do Dart = código; 404 de
`main.dart.js`/`canvaskit.wasm` = entrega/base-href) e **Network** (o que falhou de
carregar). Se você não tem navegador no ambiente de execução, entregue esses dois passos
ao usuário e registre como limite.

## Flutter específico

- `flutter config --enable-web` e `flutter doctor` (web sem Chrome ainda builda, mas
  `flutter run -d chrome` falha — `-d edge` funciona quando só Edge existe).
- Migração Material → pacote `material_ui`: exige trocar imports no app **e** manter
  compatibilidade com pacotes legados (`flame`, `share_plus`); há bridge de compatibilidade.
- Build `--wasm` falha se qualquer arquivo usa `dart:io`: corrija o import antes de tentar.
