# Checklist: Android não abre

Três planos diferentes: **build**, **instalação**, **execução**. A causa mais frequente
não é nenhuma das três: é não haver *onde* executar (sem emulador, sem aparelho, APK de
debug que ninguém consegue instalar por fora do projeto).

## 0. Onde o app deveria abrir

```
node scripts/survey_env.ps1 -ProjectRoot <pasta>     # SDK, componentes, AVDs, adb
adb devices -l
```

| Situação | Diagnóstico | Próximo passo |
| --- | --- | --- |
| `sdkmanager` sem `emulator` e sem `system-images` | impossível abrir em emulador | instalar componentes + `avdmanager create avd`; ou usar aparelho real |
| Sem `~/.android/avd` | nenhum AVD | idem |
| `adb devices` vazio com cabo ligado | depuração USB off / driver / `adb` de outra versão | `adb kill-server; adb start-server`; ativar USB debugging |
| Aparelho listando `unauthorized` | usuário não aceitou o prompt RSA | aceitar no aparelho |
| Projeto sem `android/` (só staging) | o `flutter create .` nunca foi rodado no destino | gerar e revisar `local.properties`, `settings.gradle.kts` |

## 1. Build

- `android/local.properties` com `flutter.sdk=` — `settings.gradle.kts` do template faz
  `require(flutterSdkPath != null)`. Script de sync que exclui esse arquivo quebra o build
  em qualquer outra máquina **antes de qualquer erro de código**.
- `build.gradle.kts`: se `signingConfig = signingConfigs.getByName("debug")` no bloco
  `release`, o "release" é assinado com a chave de debug — não publicável, e às vezes
  recusado por lojas/MDM.
- `flutter build apk --release` vs `--debug`: debug contém `kernel_blob.bin` (JIT), é
  maior e exige o SDK correspondente no aparelho.
- Falta de NDK/JDK: Java do template vs JDK exigido pelo Gradle; `JAVA_HOME` pode apontar
  para outro JDK no terminal Manus do que na sessão do usuário.

## 2. Instalação

```
node scripts/inspect_apk.js build\app\outputs\flutter-apk\app-debug.apk
adb install -r -g build/app/outputs/flutter-apk/app-release.apk
```

- `INSTALL_FAILED_UPDATE_INCOMPATIBLE` → assinatura diferente do app já instalado:
  `adb uninstall <package>` antes de reinstalar.
- `INSTALL_FAILED_OLDER_SDK` → `minSdk` do APK acima do Android do aparelho.
- `INSTALL_FAILED_NO_MATCHING_ABIS` → APK sem a ABI do aparelho (ex.: só `arm64-v8a` em
  aparelho antigo `armeabi-v7a`, ou x86_64 em emulador ARM).
- `adb install` sem `-g` pode recusar permissões dinâmicas e o app fecha no primeiro
  acesso a arquivo/microfone.
- APK > 150 MB ou transferido por via insegura (WhatsApp/e-mail comprime/renomeia) →
  cópia corrompida: instalar por `adb` ou verificação de hash.

## 3. Execução (fecha imediatamente / tela preta)

Ordem de coleta de evidência:

```
adb logcat -c
adb shell am start -n <package>/<activity>     # ou abra pelo launcher
adb logcat -v time *:E AndroidRuntime:* flutter:*
```

| Padrão no log | Causa provável |
| --- | --- |
| `FATAL EXCEPTION` em `MainActivity` / `DartError` | exceção no boot (ver checklist-web, itens de `runApp`) |
| `libc: Fatal signal 11` com `libflutter.so` ausente da ABI | ABI sem bibliotecas nativas |
| `MissingPluginException` | plugin sem implementação no Android ou minSdk baixo demais |
| `Resources$NotFoundException` de asset | `flutter: assets:` ausente ou `tree-shake-icons`/remoção de assets |
| `V8/Dart: Failed to initialize` + `kernel_blob.bin` em release | APK misto: build errado |
| Tela preta por 10 s sem log | `compute()`/operação bloqueante antes do primeiro frame |
| App abre e volta ao launcher sem log | exceção capturada silenciosa + `runApp` com `try` engolindo; checar `debugPrint` |

## 4. Coisas que **não** são a causa

- Testes unitários passando e `flutter analyze` limpo: quase nunca o motivo de "não abre"
  (na auditoria real: 19 testes OK, "No issues found" → ambiente era a causa).
- Nome do pacote/`applicationId` diferente: atrapalha `adb` se você usar o errado, mas não
  impede o app de abrir.
- Aviso de Gradle obsoleto ou `flutter --version` antigo no PATH: só importam se o build falhou.
