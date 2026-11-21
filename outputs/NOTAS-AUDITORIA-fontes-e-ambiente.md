# Fontes externas consultadas (auditoria Dino Control Lab, 20/11/2026)

- https://pub.dev/packages/material_ui — pacote oficial (publisher verificado `flutter.dev`), publicado ~3 dias antes da consulta, v1.11.1. Confirma que o Material saiu do core do Flutter para o pacote `material_ui`; exige migração de imports (`package:flutter/material.dart` → `package:material_ui/material_ui.dart`) e existe `MaterialUiCompatibilityBridge` para pacotes legados. Dependências: collection, cupertino_ui, flutter, flutter_localizations, intl ^0.20.2, material_color_utilities, vector_math. Licença BSD-3.
- https://github.com/dart-lang/sdk/issues/55048 — "dart2js (dart compile js) allows compiling with dart:io import": o dart2js **permite** importar `dart:io` (por isso `flutter build web` passou com `lib/data/export.dart` importando dart:io), enquanto DDC/build_web_compilers recusam.
- https://github.com/dart-lang/webdev/issues/2686 — descreve o comportamento atual como "Support compiling with dart:io but bad failure modes: dart2js and Flutter today"; ou seja, risco de falha em runtime, não erro de compilação.
- https://stackoverflow.com/questions/74164386/flutter-web-shows-blank-page-on-github-deployment e https://www.reddit.com/r/flutterhelp/comments/15q5uju/ — tela branca do Flutter web publicado em subpasta (GitHub Pages) resolvida com `--base-href`.
- https://github.com/flutter/flutter/issues/153340 — `[Web 3.24.0] canvaskit loading not honoring --base-href`: bug conhecido de carregamento do CanvasKit em subcaminho, reforçando a necessidade de testar o bundle servido no路径 final.
- https://docs.flutter.dev/platform-integration/web/wasm — dart2wasm não tem suporte a `dart:io`; builds `--wasm` falham com o código atual.

## Estado do ambiente (para reuso da skill app-launch-triage)

- Máquina: NITROV15, Windows, conta real `rolym` (SID ...-1001); terminal Manus roda como `nitrov15\mso_l5sfeofpai3kmbzo` (SID ...-1009), **sem rede** (falha ao conectar em github.com:443), sem loopback alcançável por processos de fora, sem acesso de leitura a `C:\Users\rolym\**` e sem permissão de escrita fora do workspace.
- Git: exige `-c safe.directory=D:/Repos/Dino_Control_Lab` para operar no repo do usuário (ownership diferente). `credential.helper = manager` está habilitado (máquina), mas sem rede não há push a partir do terminal Manus.
- Python: nenhum no PATH. Intermediários portáteis úteis: `D:\AI\ocr\python\cpython-3.13.18-windows-x86_64-none\python.exe` (3.13.18, stdlib ok, sem PyYAML). Também existem `D:\AI\MicroscopiaAI\compilacao-dupla\ambientes\python312\Scripts\python.exe` e o python do LibreOffice Portable.
- Node: `C:\Program Files\nodejs\node.exe` v26.13.0. Também há Git Bash (`C:\Program Files\Git\bin\bash.exe`) e perl.
- Java: Temurin 17.0.21 (no PATH do serviço). Flutter: ausente do PATH; existe em `D:\rolym\Documents\ChatGPT\Dino_Control_Lab\.toolchain\flutter`. Android SDK idem em `.toolchain\android` (sem `emulator` e sem `system-images`). Navegadores: só Edge (`C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`); Chrome ausente.
- Permissão de escrita em `C:\Users\rolym\.manus\user-skills`: PowerShell criou o diretório, mas o Python do D:\AI recebeu `[WinError 5] Acesso negado` ao criar subdiretório dentro dele.
