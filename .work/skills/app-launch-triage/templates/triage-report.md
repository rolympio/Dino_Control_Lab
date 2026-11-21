# Auditoria de lançamento — <PROJETO>

**Data:** <ISO> · **Analisado por:** Manus · **Repositório:** <owner/repo ou "só local">
**Engine/platform:** <Flutter 3.50 / Dart 3.14 / Flame> · **Alvos:** <web, android>
**Sintoma relatado:** "<não abre na web nem no Android>"

## Resumo executivo

<2–4 frases. Dizer a causa principal e desmontar a hipótese mais provável do usuário.
Ex.: "O código compila, os testes passam e os artefatos estão sãos. As três causas do
'não abre' são de ambiente e entrega, não de lógica: <...>.">

## Causas-raiz

### C1 — <título> · severidade <ALTA/MÉDIA/BAIXA> · <web|android|ambos>

- **Evidência:** `<arquivo>:<linha>` — <trecho>; `<byte do log>`; `Get-ChildItem` mostrou
  <tamanho/data real>.
- **Por que impede de abrir:** <mecanismo em 1–3 frases>.
- **Correção permanente:** <comando/edição exata, com caminho real>.
- **Contorno imediato:** <o que o usuário faz agora, sem rebuild>.

### C2 — ...

### C3 — ...

## Bugs de código encontrados

| ID | Local | Sintoma | Gravidade | Correção |
| --- | --- | --- | --- | --- |
| B1 | `lib/<...>.dart:2` | <import de desktop no grafo web> | Baixa (build passa; quebra `--wasm`) | <trocar por plugin cross-platform> |
| B2 | `lib/main.dart:7` | <exceção antes do primeiro frame> | **Alta** | <inicializar dentro de `runApp` + `try/catch`> |

## Artefatos verificados

| Artefato | Tamanho | Estado | Detectado por |
| --- | --- | --- | --- |
| `build/web/` | 46 arquivos | sãos, `useLocalCanvasKit: true` | `inspect_web_bundle.js` |
| `app-debug.apk` | 169,4 MB | debug, ABIs arm64-v8a/armeabi-v7a/x86_64 | `inspect_apk.js` |
| `evidence/tests.txt` | 19 testes OK | verde | `flutter test` |
| `evidence/analyze.txt` | "No issues found" | limpo | `flutter analyze` |

## Comandos para o usuário rodar

```powershell
# WEB (na sua máquina, com servidor local — não abra por file://)
python -m http.server 8080 -d "<caminho>\build\web"
# depois: http://localhost:8080   (ou Edge: msedge --app=http://localhost:8080)

# ANDROID (aparelho real, com USB debugging ativo)
adb devices -l
adb install -r -g "<caminho>\build\app\outputs\flutter-apk\app-debug.apk"
adb logcat -v time *:E AndroidRuntime:* flutter:*
```

## O que não foi possível verificar

- <ex.: execução real da web — ambiente sem navegador acessível e terminal sem rede>
- <ex.: emulador Android — SDK sem `emulator` e sem `system-images`>
- <ex.: push ao repositório — sem credenciais/redes no terminal de execução>

Para cada item, o comando acima que fecha a lacuna.

## Hipóteses corrigidas durante a investigação

Registadas para evitar retrabalho: <"projeto era Godot" → era Flutter; "pacote X
inexistente" → oficial; "dart:io quebra o build web" → dart2js permite, falha em runtime>.

## Recomendações priorizadas

1. <C1 — ação>
2. <C2 — ação>
3. <B2 — ação>
