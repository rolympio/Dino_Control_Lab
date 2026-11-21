---
name: app-launch-triage
description: "Investiga por que um app compilado não abre: tela branca (blank white screen), crash ao iniciar (crash on launch), 'o app parou de funcionar', build web que não carrega, APK que não instala ou fecha imediatamente, 'não compila', 'não roda'. Trilha o processo da auditoria real (Dino_Control_Lab): provar o estado de código e artefato, separar causas de ambiente (toolchain, permissão, navegador ausente, emulador, hospedagem, repositório vazio) de causas de código, e entregar relatório com causas-raiz ordenadas, evidências e correções. Use quando o usuário disser 'não abre', 'abre e fecha', 'fica em branco', 'não compila', 'audite meu projeto', 'build web/android falha', 'white screen', 'apk won't install', em projeto Flutter, Godot, Unity, React/Vite ou nativo."
---

# App Launch Triage

Descobrir **por que** um app não abre sem acreditar na primeira hipótese. O entregável
não é uma correção às cegas: é uma lista ordenada de causas com evidência, separando
"o código está errado" de "o ambiente/entrega está errado" — que é o caso mais comum
e o mais ignorado.

Princípio que resolveu a auditoria real: **um artefato sano pode ser incapaz de abrir**.
Build verde + ambiente errado produz tela branca idêntica à de um bug de código. Nunca
afirme uma causa sem evidência, e nunca presuma engine, plataforma ou navegador antes
de olhar.

## Fluxo

```
1 Contexto   → 2 Ambiente      → 3 Artefato   → 4 Código      → 5 Runtime (se der) → 6 Relatório
   remoto?       survey_env.ps1    inspetores     análise         servidor / adb /     templates/
   local?         + acesso          .js/.ps1       estática        emulador             triage-report.md
   engine?
```

Execute 1→4 sempre. A etapa 5 é condicional: se o ambiente não permite rodar, diga isso
no relatório em vez de fingir que testou — é a diferença entre auditoria confiável e
achismo.

## 1. Contexto: o que existe de fato

Fixe três coisas com comando, não com suposição.

- **Onde está o código**: repositório remoto (branch, commit, lista de arquivos) ou só
  local. Compare os dois — se o remoto tem 1 commit com `README.md` e o local tem 20
  arquivos `.dart`, "não abre na web" nem é problema de código: nada foi publicado.
- **Qual é a engine**: não confie no nome do projeto, no README nem na conversa. Leia
  `pubspec.yaml` (Flutter), `project.godot` (Godot), `ProjectSettings.asset` (Unity),
  `package.json` (web). Na auditoria real a hipótese "é Godot" estava errada: Flutter + Flame.
- **Qual plataforma o "não abre" significa**: web servida, web em `file://`, APK instalado,
  emulador ou `flutter run`? São quatro perguntas com quatro respostas diferentes.

Se existe remoto, cheque a **integridade da sincronia** (`.gitignore`, arquivos
obrigatórios ausentes, binários comitados). Um script de sync que exclui
`local.properties` quebra o build em qualquer outra máquina.

## 2. Ambiente

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/survey_env.ps1 -ProjectRoot <pasta> [-Json]
```

Lista engines no PATH, toolchains fora do PATH, componentes do SDK Android, AVDs,
navegadores presentes, estado do git (com `safe.directory` para conta de serviço) e
artefatos com data. Leia `references/checklist-environment.md` antes de concluir: ele
traz os modos de falha invisíveis em log de build (terminal em conta de serviço sem rede
nem acesso a `App Data`; engine dentro de `.toolchain\` do projeto; só Edge instalado;
SDK sem `emulator`/`system-images`; ACL que impede criar pasta de destino).

Teste permissão por tentativa direta — saber que `New-Item` falha com *Access denied*
economiza a hora gasta num script que "não funciona".

## 3. Artefato

O artefato pronto responde melhor que o código-fonte. Node puro, sem dependências:

```
node scripts/inspect_web_bundle.js <build\web | bundle.zip> [--json]
node scripts/inspect_apk.js <app-release.apk | app-debug.apk> [--json]
```

Saída legível, código de saída ≠ 0 quando há problema grave (usável em CI). Cobrem as
causas de tela branca mesmo com compilação limpa: `<base href="/">` em subpasta,
`version.json` ausente, CanvasKit dependendo de CDN sem cópia local, service worker
servindo versão velha, APK assinado em debug, ABI sem `libflutter.so`, `minSdk` acima do
aparelho, `kernel_blob.bin` dentro de release.

Para web, **sirva o bundle** antes de julgar. Abrir `index.html` com duplo clique
(`file://`) quebra o Flutter web de propósito: nesse caso a causa é entrega, não código.

## 4. Código (estática)

Três lentes, com as causas de maior taxa de acerto. Detalhes em
`references/checklist-web.md` e `references/checklist-android.md`.

- **executado antes do primeiro frame**: `ensureInitialized`/`SharedPreferences` fora de
  `runApp`, store construída com leitura de storage no construtor, `ThemeMode.values.byName`
  com valor obsoleto, cast estrito em `fromJson` sem validar `schema_version` → abre e fecha.
- **código de desktop no grafo da web**: `dart:io`, `Platform.isX`, plugin sem suporte web.
  O dart2js **compila com isso** e só falha em runtime — build verde não é prova de nada.
- **concorrência e timing na web**: `compute()` roda no mesmo isolate no navegador
  (congela a UI), `Timer.periodic` curto travando o frame, cota de `localStorage` (~5 MB)
  estourada sem `try/catch`.

Rode `flutter analyze`/`dart analyze`/`flutter test` quando houver engine e **guarde a
saída** (`evidence/analyze.txt`, `evidence/tests.txt`). Na auditoria real, 19 testes
passando e "No issues found" provaram que a causa não era o código e redirecionaram a
investigação para ambiente.

Antes de afirmar que uma dependência é fictícia, consulte o registro (`pub.dev`, npm):
`material_ui` parecia inventado e é oficial do Flutter.

## 5. Runtime (quando possível)

Ordem de custo crescente: servidor estático → navegador real → `adb install` → emulador.
Se faltar uma peça, escreva o comando exato para o usuário ver a falha ao vivo (console
do navegador, `adb logcat`) em vez de adivinhar o stack trace.

Comandos que fecharam a parte Android: `adb devices -l`, `adb install -r -g <apk>`,
`adb shell pm list packages | findstr`, `adb logcat -v time *:E`. Para web:
`python -m http.server 8080 -d build/web` e abrir `http://localhost:8080`.

## 6. Relatório

Copie `templates/triage-report.md` para `outputs/AUDITORIA-<projeto>.md` e preencha.
Regras que tornam o relatório acionável:

- causas nomeadas **C1, C2, C3** com severidade, evidência (arquivo:linha, trecho de log,
  tamanho real do artefato) e **correção permanente + contorno imediato**;
- bugs de código em tabela **B1…Bn** com `arquivo:linha`, sintoma e gravidade;
- seção **"O que não foi possível verificar"** — sem ela o leitor presume que tudo foi testado;
- seção de **comandos para o usuário rodar** na máquina dele, com caminhos reais;
- registre as hipóteses corrigidas pelo caminho; evita retrabalho na próxima sessão.

Entregue o arquivo com link absoluto. Scripts descartáveis vão para `.work/`; o que o
usuário precisa reutilizar (servidor local, script de build) fica fora de `.work/`.

## Estrutura

```
SKILL.md
scripts/inspect_web_bundle.js   zip ou pasta: base-href, CDN, service worker, assets, wasm
scripts/inspect_apk.js          ABIs, debug vs release, assinatura v1, minSdk/targetSdk via AXML
scripts/survey_env.ps1          engines, SDK, AVD, navegadores, git, artefatos
references/checklist-environment.md  falhas de máquina/permissão/entrega (as causas C1–C3 reais)
references/checklist-web.md          tela branca: base href, file://, CDN, SW, MIME de .wasm
references/checklist-android.md      APK, assinatura, ABI, minSdk, emulador, adb
templates/triage-report.md           formato de entrega
```
