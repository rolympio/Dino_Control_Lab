# Checklist: ambiente e entrega

Modos de falha que **não aparecem em log de build** e costumam ser a causa real.
Vindos da auditoria do Dino_Control_Lab (Flutter/Flame, web + Android, Windows).

## Acesso e execução

| Sintoma | Causa | Como confirmar | Correção / contorno |
| --- | --- | --- | --- |
| Arquivos do projeto visíveis, mas nada roda | Terminal Manus em **conta de serviço** sem rede nem acesso a `App Data` | `Test-Path $env:USERPROFILE\AppData` → negado; `Test-Connection one.one.one.one` → false | Trocar o dispositivo de execução para o desktop do usuário; pode exigir reiniciar/atualizar o app até a execução local renegociar |
| `git` reclama de *dubious ownership* | Dono da pasta ≠ usuário do terminal | `git -C <p> status` falha | `git -c safe.directory=C:/caminho/do/repo -C <p> status` (por comando, não global) |
| `flutter`/`dart` "não existem" | Engine fora do PATH, instalada dentro do projeto | `Get-Command flutter` vazio; `Get-ChildItem <projeto>\.toolchain -Directory` | Usar o caminho absoluto `.toolchain\flutter\bin\flutter.bat` e **registrar isso no relatório** |
| Escrita em pasta de skills/config falha com *Access denied* | ACL do diretório-pai não permite criar subpasta | `New-Item -ItemType Directory <folha> -EA Stop` (teste direto) | Trabalhar no workspace e entregar `.skill`/arquivo para o usuário instalar |
| Python/Node "ausentes" | Só o launcher do Windows no PATH | `where.exe python`; procurar `D:\AI\**\python.exe`, LibreOffice Portable | Usar o interpretador portátil achado; testar a stdlib antes (`python -c "import zipfile,json"`) |

**Regra:** confirmar cada suposição de ambiente com um comando curto antes de construir
uma tese. Duas hipóteses erradas caíram assim: "o projeto é Godot" (era Flutter) e
"`material_ui` é pacote inventado" (é oficial do Flutter — verifiquei em `pub.dev`).

## Entrega do código

- Repositório remoto com **1 commit e só `README.md`** → o app "não abre na web" porque
  **não existe código publicado**. Comparar `git ls-files` com a contagem de arquivos local.
- Script de sincronização que exclui arquivos necessários: `local.properties` é
  **obrigatório** no Android do Flutter (`android/settings.gradle.kts` lê `flutter.sdk`
  de lá e faz `require(flutterSdkPath != null)`; sem ele o build morre antes de começar).
- `.gitignore` com artefatos comitados (`build/`, `.apk`) ou, ao contrário, excluindo
  `assets/**` (aí o app abre com tela preta/erro de asset não encontrado).
- Branch do usuário ≠ branch analisado. Checar `git branch -a`, `git log -1 --date=iso`.

## Web

| Causa | Evidência | Correção |
| --- | --- | --- |
| Abrir `index.html` em `file://` | URL no navegador | Servir: `python -m http.server 8080 -d build/web` e abrir `http://localhost:8080` |
| `<base href="/">` + subpasta | `inspect_web_bundle.js` | `flutter build web --base-href=/nome/` |
| Hospedagem inexistente (sem Pages, sem servidor) | `gh api repos/<d>/<r>/pages` → 404 | Habilitar GitHub Pages ou publicar no servidor real |
| Só Edge instalado, comando pede Chrome | `flutter run -d chrome` → *Chrome not found* | `flutter run -d edge` ou definir `FLUTTER_BROWSER` |
| `chrome.exe` ausente em conta de serviço | `survey_env.ps1` → `browsers` só `msedge.exe` | Instruir o usuário a rodar na sessão dele |

## Android

| Causa | Evidência | Correção |
| --- | --- | --- |
| Sem emulador: falta `emulator` e `system-images` | `survey_env.ps1` → `android.components`, `avds` vazio | `sdkmanager "emulator" "platform-tools" "system-images;android-34;google_apis;x86_64"` + `avdmanager create avd` |
| Só existe `app-debug.apk` | `inspect_apk.js` → `kernel_blob.bin`, modo DEBUG | `flutter build apk --release` |
| `signingConfig` do release aponta para o debug do template | `android/app/build.gradle.kts` | Keystore próprio + `key.properties` fora do VCS |
| Aparelho real não lista no `adb` | `adb devices -l` vazio | Ativar depuração USB; `adb kill-server && adb start-server`; instalar driver |
| Instalação recusada por permissões | `INSTALL_FAILED_*` no `adb install` | `adb install -r -g app-release.apk` |

## O que declarar como não verificado

Se não deu para abrir o app de verdade (sem navegador, sem emulador, sem rede), escreva
uma seção **"Limites desta auditoria"** listando exatamente o que faltou e o comando que
o usuário roda para fechar a lacuna. Isso vale mais do que uma conclusão não provada.
## Armadilhas da própria investigação

- Reescrever um `.ps1`/`.md` em UTF-8 com Windows PowerShell 5.1 (`Get-Content` sem
  `-Encoding UTF8`, `Set-Content -Encoding UTF8`) converte acentos para mojibake
  (`não` → `nÃ£o`). Leia com `-Encoding UTF8` e grave com
  `[IO.File]::WriteAllLines($path,$linhas,(New-Object Text.UTF8Encoding($false)))`.
- PowerShell ignora diferença de maiúsculas: `$deep` e o switch `-Deep` são a **mesma**
  variável — o valor vira `False` silenciosamente e a coleta fica vazia.
- Recursão total em `build/` com `-Force` pode levar minutos sob conta restrita: prefira
  as pastas onde a engine escreve artefatos (`build/app/outputs/...`, `build/web`, `dist`)
  com `-Depth 3`.
- Redirecionar saída para `Select-Object -First N` pode travar o processo filho escrevendo
  em pipe fechado; grave em arquivo e leia o arquivo.
