# Auditoria — Dino Control Lab (Web e Android não abrem)

Data: 20/11/2026 · Escopo: `D:\Repos\Dino_Control_Lab` (Flutter/Flame) e `rolympio/Dino_Control_Lab` (GitHub)

## 1. Conclusão em uma linha

O aplicativo **compila e os artefatos estão sãos**; o que não existe é um **ambiente capaz de executá-lo**. A toolchain inteira (Flutter, Android SDK, Gradle) vive dentro de `D:\rolym\Documents\ChatGPT\Dino_Control_Lab\.toolchain\` e é alcançada só por caminhos absolutos gravados no checkout de *staging*. O checkout do repositório não tem `local.properties`, não tem `.dart_tool`, o `flutter` não está no PATH, o Chrome não está instalado e não há nenhum emulador Android. Nenhuma das duas plataformas foi, portanto, alguma vez realmente aberta: as próprias notas do projeto (`docs/VALIDATION.md`) registram a validação manual como pendente e o GitHub como contendo apenas o README.

Três causas independentes, cada uma suficiente para "não abre":

| # | Causa | Plataforma |
|---|-------|-----------|
| C1 | `flutter` fora do PATH e SDK preso a `...\.toolchain\flutter`; `android/local.properties` é **excluído** do repositório pelo `sync-repository.ps1`, e o `settings.gradle.kts` **explode** sem ele | ambas (build) |
| C2 | Sem Chrome instalado (`-d chrome` falha) e o `build/web` gerado usa `<base href="/">`, que não funciona por `file://` nem sob subcaminho de URL | WEB |
| C3 | Sem `emulator`, sem `system-images`, sem nenhuma AVD, sem `.android/`; o único artefato é `app-debug.apk` de 169 MB assinado em debug, nunca instalado em aparelho | Android |

## 2. Mapa do que existe na máquina

```
D:\rolym\Documents\ChatGPT\Dino_Control_Lab\   <- único lugar onde o build funciona
├── .toolchain\flutter        (Flutter 3.50.1, revisão ae9b586f34, Dart 3.14)
├── .toolchain\android        (SDK: platform-tools, platforms;android-36, build-tools;36.0.0, ndk;28.2.13676358, cmake)
├── .toolchain\gradle         (GRADLE_USER_HOME)
├── app\                      <- checkout de STAGING: tem .dart_tool\ e android\local.properties
├── build-android.ps1         (seta ANDROID_HOME/JAVA_HOME/GRADLE_USER_HOME e roda flutter build apk --debug --no-pub)
├── setup-android.ps1         (baixa cmdline-tools e instala pacotes Android)
└── sync-repository.ps1       (robocopy app -> D:\Repos\Dino_Control_Lab)

D:\Repos\Dino_Control_Lab\    <- checkout de REPOSITÓRIO: cópia idêntica do código (0/20 .dart divergem)
                                   mas SEM .dart_tool e SEM android\local.properties
```

O `sync-repository.ps1` faz `robocopy /E /XD .git .dart_tool build .idea .gradle ... /XF local.properties`. Isso é correto para versionar, mas tem um efeito colateral fatal: **torna o diretório do repositório incapaz de compilar Android por Gradle**, porque `android/settings.gradle.kts` começa com

```kotlin
val properties = java.util.Properties()
file("local.properties").inputStream().use { properties.load(it) }   // FileNotFoundException se faltar
val flutterSdkPath = properties.getProperty("flutter.sdk")
require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
```

## 3. Por que a WEB não abre

1. **Não há servidor.** `flutter build web` gera um app que *exige* HTTP. O `build/web/index.html` gerado tem `<base href="/">`: aberto com duplo clique (`file:///D:/Repos/.../build/web/index.html`) ou servido de um subcaminho (ex.: `https://usuario.github.io/Dino_Control_Lab/`), o navegador pede `flutter_bootstrap.js`, `main.dart.js` e `canvaskit/*` na **raiz do domínio** → 404 → **tela branca**, sem erro visível na página.
2. **Não há hospedagem.** `docs/DEVELOPMENT.md` afirma "Nenhuma hospedagem foi publicada", e o repositório GitHub contém só o `README.md`, então não existe URL para abrir.
3. **Chrome ausente.** O único navegador instalado é o Edge (`msedge.exe` em `C:\Program Files (x86)\Microsoft\Edge\`). `flutter run -d chrome` falha com "Unable to find Chrome binary" — a forma padrão de abrir a versão web nesta máquina não funciona.
4. O bundle em si está **correto e completo**: 46 arquivos, inclui `index.html`, `main.dart.js` (2,8 MB), `version.json`, `flutter_bootstrap.js` e `canvaskit/` local, com `useLocalCanvasKit: true` (não depende do CDN da Google). Servido na raiz por HTTP com MIME `application/wasm`, ele funciona.
5. **Riscos próprios do código na web** (seção 5): B1 (`dart:io` no grafo) e B3 (`compute` sem isolate real) podem dar tela branca/congelamento; B2 (quota do `localStorage`) quebra depois de ~30–80 sessões salvas.

## 4. Por que o Android não abre

1. **Nenhum alvo Android existe.** Em `...\.toolchain\android` há `platform-tools`, `platforms`, `build-tools`, `ndk`, `cmake`, mas **não** há `emulator/` nem `system-images/`; não há `C:\Users\rolym\.android\avd` nem `D:\rolym\.android`. Ou seja: nenhuma AVD, nenhum emulador, e o `flutter devices` só mostraria aparelho físico.
2. **adb não sobe nesta sessão.** `adb devices` falhou com "could not read ok from ADB Server / cannot connect to daemon" no ambiente isolado; num aparelho físico é preciso habilitar Depuração USB e aprovar o prompt de autorização — sem isso o `flutter run` fica em "Waiting for device" (efeito prático: "não abre").
3. **Só existe APK de debug.** `build/app/outputs/flutter-apk/app-debug.apk`, 169.382.016 bytes, assinado com chave de debug, contendo `arm64-v8a`, `armeabi-v7a` e `x86_64` (logo é instalável por sideload). Não há `key.properties` nem keystore do projeto, e o `buildTypes.release` continua usando `signingConfigs.getByName("debug")` (com `// TODO` do template). Um APK release assinado em debug **não coexiste** com uma instalação anterior de assinatura diferente: o Android responde `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, que o usuário percebe como "o app não instala/não abre".
4. **minSdk herdado do SDK.** `minSdk = flutter.minSdkVersion` amarra o app à versão do Flutter usada no build; em aparelhos antigos isso vira "app não é compatível com o seu dispositivo". Vale fixar explicitamente (ex.: `minSdk = 24`) e documentar.
5. `android/local.properties` ausente no repositório (C1) faz qualquer build Gradle *daquele diretório* falhar antes de chegar no aparelho.

## 5. Achados de código

Gravidade: **alta** = impede/quebra em runtime · **média** = degrada ou quebrará · **baixa** = higiene.

| ID | G | Local | Problema | Correção |
|----|---|-------|----------|----------|
| B1 | alta | `lib/data/export.dart:2` | `import 'dart:io'` dentro do grafo do app (`results.dart → export.dart`). O dart2js **aceita** e stubs (por isso o build passou), mas `Platform`/`File` lançam em runtime na web e `flutter build web --wasm` (dart2wasm) **recusa** `dart:io`. Hoje a única coisa impedindo o erro é o curto-circuito `if (kIsWeb)`/`!kIsWeb &&` | Isolar por import condicional: `export_io.dart` (`dart:io`) e `export_web.dart`, unidos por `export_stub.dart` com `if (dart.library.io) 'export_io.dart' else 'export_web.dart'` |
| B2 | alta | `lib/main.dart:7-11`, `lib/data/store.dart:10-31`, `lib/data/session.dart:19-33`, `lib/domain/config.dart:81-95` | `AppStore` é construído **antes** do `runApp` e sem `try/catch`. O construtor faz `ThemeMode.values.byName(...)`, `Session.fromJson` com casts estritos (`j['classic'] as bool`, `j['score'] as int`) e `CharacterKind.values.byName(...)`. Qualquer dado persistido de versão anterior (ou truncado) lança antes do primeiro frame: **web = tela branca; Android = abre e fecha**. O `schema_version: 1` é escrito mas nunca validado | Envolver o parse em `try/catch`, checar `schema_version` e descartar/ migrar registros inválidos; usar `int.tryParse`/`as num? ?? 0`; registrar `FlutterError.onError` + `PlatformDispatcher.instance.onError`; exibir uma tela de erro em vez de deixar o lançamento vazar |
| B3 | alta | `lib/ui/lab_panel.dart:35` | `compute(compareControllers, ...)` na web executa **no mesmo isolate** (a implementação web de `compute` apenas chama o callback). São 4 controladores × 60 s a 120 Hz, com MPC avaliando 6 atrasos × horizonte × obstáculos: a aba congela por segundos e parece travada/não aberta | Fatiar o trabalho em `Future.microtask` com `await` entre controladores e/ou reduzir o passo de simulação na web (ex.: 60 Hz) e notificar progresso; manter `compute` só em nativo (`kIsWeb ? loop : compute`) |
| B4 | média | `lib/data/store.dart:41-48` | Toda partida reescreve o JSON do histórico inteiro. Na web, `localStorage` tem quota (~5 MB) e as sessões são grandes (as de `evidence/*.json` têm ~146 KB com indentação); depois de dezenas de sessões `setString` lança `QuotaExceededError` dentro de um `unawaited(...)` → erro não tratado | Guardar as últimas N sessões (ex.: 50), amostrar `samples`, e capturar a exceção; considerar `IndexedDB` na web |
| B5 | média | `lib/ui/game_page.dart:33-35` | `Timer.periodic(100ms)` chamando `setState` para a página inteira, mesmo pausada/crashada. Custo desnecessário de rebuild 10×/s na web | Reconstruir só o HUD (um `ValueListenableBuilder`/`Consumer` alimentado pelo `DinoGame`) e pausar o ticker quando `userPaused`/`crashed` |
| B6 | média | `lib/ui/results.dart:45,108` | `selected ??= sessions.firstOrNull` nunca invalida uma seleção antiga; `selected!` é desembrulho forçado. Com histórico esvaziado/modificado entre builds, pode lançar `NullCheckOperator` | Reconstruir `selected` quando não pertencer mais à lista e usar `final s = selected; if (s == null) return ...` |
| B7 | baixa | `pubspec.yaml:5-6` | `environment.sdk: '>=3.13.0'` permite um Flutter/Dart mais velho do que o `pubspec.lock` exige (`flutter: ">=3.47.0"`). A divergência entre pubspec, lock e o "3.50.1/Dart 3.14" do README é o tipo de coisa que produz "aqui compilou, lá não" | Fixar `environment: { sdk: ^3.14.0, flutter: ">=3.50.0 <4.0.0" }` e manter README/lock alinhados |
| B8 | baixa | `web/index.html:21,38,44` · `web/manifest.json` | Metadados do template permanecem: `description "A new Flutter project."`, `title dino_control_lab`, `background_color #0175C2`, `orientation portrait-primary` (o jogo se beneficia de paisagem) | Preencher nome/descrição/cores reais; revisar orientação |
| B9 | baixa | `assets/audio/` só `.wav` (12,8 KB) | Ok offline, mas o `audioplayers` na web depende de decodificação HTTP Range; se o servidor não suportar `Range`/`Accept-Ranges`, o som falha silenciosamente (o código já mostra "Som indisponível") | Manter, só garantir servidor compatível |
| B10 | baixa | `lib/domain/controller.dart:47` (`[double.infinity, 0.0, ...]`) e `lib/game/dino_game.dart:97` (`math.max(scale, .45)`) | Em telas estreitas, o fator mínimo corta a prévia dos obstáculos (mundo de 1000 px não cabe); não impede abrir, mas degrada o primeiro uso no telefone | Ajustar o mundo virtual para caber (escala por largura) ou reduzir `Obstacle(1000, ...)` para a largura visível |

Pontos fortes que a auditoria confirmou: separação domínio/Flame/UI sem ciclagem, motor de passo fixo com semente própria e LCG determinístico, `Session` serializável com eventos por tick e replay reproduzível, switches exaustivos sobre enums (sem `default` engolidor), ausência de `print`/dados inventados, 19 testes passando em duas larguras e dois temas, `flutter analyze` limpo.

## 6. Abrir agora (caminho mais curto, na sua máquina)

**Web (Edge, sem precisar de Chrome):**

```powershell
$env:Path = "D:\rolym\Documents\ChatGPT\Dino_Control_Lab\.toolchain\flutter\bin;" + $env:Path
cd D:\rolym\Documents\ChatGPT\Dino_Control_Lab\app
flutter run -d edge --web-renderer canvaskit
```

Ou, para o bundle já pronto, servir na raiz (nunca abrir por `file://`):

```powershell
cd D:\Repos\Dino_Control_Lab\build\web
npx --yes http-server -p 8080 -a 127.0.0.1 -c-1 --mime-type ".wasm:application/wasm" .
# abrir http://127.0.0.1:8080/  (o Edge já está instalado)
```

Se for publicar em subpasta (GitHub Pages, Netlify com pasta, etc.), reconstrua com o base-href correspondente:

```powershell
flutter build web --release --base-href /Dino_Control_Lab/ --no-web-resources-cdn
```

**Android (aparelho físico, pois não existe emulador):**

```powershell
$adb = "D:\rolym\Documents\ChatGPT\Dino_Control_Lab\.toolchain\android\platform-tools\adb.exe"
& $adb devices                                  # aceite o prompt "Permitir depuração USB" no celular
& $adb install -r "D:\Repos\Dino_Control_Lab\build\app\outputs\flutter-apk\app-debug.apk"
```

Sem cabo: transfira o `app-debug.apk` para o celular e instale permitindo "instalar apps desconhecidos". Se aparecer falha de assinatura, desinstale a versão anterior primeiro (B/§4.3).

**Instalar um emulador (opcional, resolve C3 de vez):**

```powershell
$env:ANDROID_HOME = "D:\rolym\Documents\ChatGPT\Dino_Control_Lab\.toolchain\android"
& "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" "platform-tools" "emulator" "system-images;android-36;google_apis;x86_64"
```

## 7. Correções permanentes (ordem sugerida)

1. Tornar o repositório auto-suficiente: commitar o código (hoje só o README está versionado) e adicionar um `android/local.properties.example` + um `tool/bootstrap.ps1` que detecta/instala a toolchain e escreve `local.properties`; ou mudar o `settings.gradle.kts` para aceitar `FLUTTER_ROOT`/`ANDROID_HOME` quando o arquivo faltar (com mensagem clara).
2. Colocar o Flutter num caminho estável e no PATH (ex.: `D:\toolchains\flutter\bin`) — fora de `Documents\ChatGPT\`, que é um local volátil por natureza.
3. Corrigir B1, B2 e B3 (os três com potencial de tela branca/congelamento).
4. Assinar release de verdade (`key.properties` fora do git + `signingConfigs` próprio) e fixar `minSdk`.
5. Publicar a web (GitHub Pages com `--base-href` ou qualquer estático com HTTP + MIME de `.wasm`) e registrar a URL no README; hoje não existe nenhum endereço para "abrir".
6. Rodar a validação manual listada em `docs/DEVELOPMENT.md` §"Validação manual pendente" e só então marcar o produto como aceito.

## 8. O que esta auditoria não pôde verificar

* Executar o app num navegador real: o contêiner de terminal desta sessão **não tem rede nem interface de loopback alcançável** (`node` escuta, mas o navegador do app não chega; portas em escuta: nenhuma visível) e o navegador embutido recusa `file://` por política. A análise do bundle web foi estática (HTML/bootstrap/zip/asset manifest).
* Executar em aparelho ou emulador Android: não há emulador e o `adb` não sobe no ambiente isolado. A análise do APK foi por inspeção do conteúdo (ABIs, `kernel_blob.bin`, assinaturas, 546 entradas).
* iOS/macOS: exigem Xcode; o próprio projeto registra isso como pendente.
