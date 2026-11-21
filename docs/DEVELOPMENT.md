# Executar e validar

Requisitos: Flutter 3.50.1 / Dart 3.14 ou compatível com o lockfile, JDK 17 e SDK Android 36. As dependências estão em `pubspec.lock`. Interface Material usa o pacote oficial `material_ui`.

Nesta máquina, o SDK usado fica em `D:\rolym\Documents\ChatGPT\Dino_Control_Lab\.toolchain\flutter`. Caso `flutter` não esteja no PATH, use o executável `bin\flutter.bat` dessa pasta. O checkout do aplicativo está em `D:\Repos\Dino_Control_Lab`.

```sh
flutter pub get
flutter analyze
flutter test
dart run tool/benchmark.dart
flutter run -d windows
flutter build apk --debug
```

Windows precisa de Visual Studio com C++ desktop e suporte a links simbólicos (Modo de Desenvolvedor ou execução elevada) para compilar os plugins desktop. Isso não é requisito do aparelho Android. Linux precisa dos pré-requisitos Flutter e do backend de áudio do audioplayers.

O projeto usa `kotlin.incremental=false` em `android/gradle.properties`: nesta instalação Windows, Kotlin 2.4.20 falhou ao fechar caches incrementais de quatro plugins. A opção realiza a compilação Kotlin sem esses caches; não altera o comportamento do aplicativo. Referência: https://kotlinlang.org/docs/gradle-compilation-and-caches.html#incremental-compilation.

## Web

Desenvolvimento: `flutter run -d chrome`, ou `flutter run -d edge` quando só o Edge estiver instalado.

O bundle de `flutter build web` **precisa de HTTP**. Aberto por `file://`, ou servido num caminho diferente do `--base-href` usado no build, o navegador mostra tela branca. Para testar localmente:

```powershell
powershell -File tool/build-web.ps1 -BaseHref /
powershell -File tool/serve-web.ps1        # http://127.0.0.1:8080/
```

Publicação: `.github/workflows/pages.yml` roda os testes e publica no GitHub Pages a cada push na `main`, com `--base-href /<repositório>/`. Isso exige ativar uma vez, em *Settings → Pages → Build and deployment → Source*, a opção **GitHub Actions**. Endereço: `https://rolympio.github.io/Dino_Control_Lab/`.

`.github/workflows/ci.yml` roda `flutter analyze` e `flutter test` em todo push e pull request.

## iOS em macOS

O scaffold oficial contém Runner, projeto/workspace Xcode, assets, Info.plist, AppDelegate e testes nativos. Em um Mac com Flutter, Xcode e ferramentas da plataforma:

```sh
flutter pub get
flutter build ios --simulator
flutter run -d <id-do-simulador>
flutter build ios --no-codesign
```

Abrir `ios/Runner.xcworkspace`, escolher a equipe de assinatura para aparelho real e validar toque, botão mantido pressionado, pausa por troca de app, som offline e exportação via folha de compartilhamento. iPad recebe uma origem explícita para o popover. Não foi feita assinatura ou distribuição.

## Análise de arquivos

Python, somente biblioteca padrão:

```python
import csv, json
with open('onOff.csv', encoding='utf-8') as f:
    samples = list(csv.DictReader(f))
with open('onOff.json', encoding='utf-8') as f:
    session = json.load(f)
print(session['initial'], len(samples))
```

MATLAB:

```matlab
T = readtable('onOff.csv');
S = jsondecode(fileread('onOff.json'));
plot(T.time_s, T.height_px);
xlabel('Tempo simulado (s)'); ylabel('Altura (px)');
```

`dart run tool/benchmark.dart` produz arquivos reais em `evidence/`, executa os quatro controladores com semente 42 e verifica a igualdade das séries temporais após serialização JSON e reprodução.

## Validação manual pendente

- Android: instalar o APK em aparelho ou emulador; pular, abaixar, colidir, reiniciar, pausar/retomar e reabrir para conferir recorde/histórico.
- Desktop: conferir Espaço/↑/↓, foco após usar botões e troca de janela.
- Editor: arrastar entrada e saída fuzzy com mouse e toque; conferir os quatro formatos de entrada e saídas triangulares.
- Exportar CSV e JSON usando o diálogo real de cada sistema e abrir em Python/MATLAB.
- Telas em 390 e 1440 px, temas claro/escuro, rolagem e textos longos.
- iOS/macOS: executar os comandos acima e validar os mesmos fluxos.
