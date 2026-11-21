# Registro de validação — 20/11/2026

Repositório consultado pela integração GitHub e clonado de `rolympio/Dino_Control_Lab`. O checkout continha o commit `bd48b81` e apenas README. O texto original foi preservado.

## Evidências executadas

- Flutter 3.50.1 estável, revisão `ae9b586f34`; Dart 3.14.0.
- Suíte final: 19 testes passaram, cobrindo colisão manual sem pulo automático, pulo e abaixar mantido, massa, quatro controladores, semente, fuzzy por toque/mouse, teclado, pausa/reinício, persistência e reprodução com edição ao vivo. Layouts foram exercitados em 390 e 1440 px, nos temas claro e escuro. Log: `evidence/tests.txt`.
- `flutter analyze --no-pub`: nenhuma ocorrência. Log: `evidence/analyze.txt`.
- `flutter build apk --debug --no-pub`: passou em 87,1 s após desativar os caches incrementais Kotlin. APK: `build/app/outputs/flutter-apk/app-debug.apk`, 169.382.016 bytes. SHA-256: `f87eead9798d8a00cbbad88b66b65decbd24b1b9a15eee7ad74bedc51e629795`. Log: `evidence/android-build.txt`.
- Correção demonstrada: teste de Espaço inicialmente falhou com altura 0; após impedir que o GameWidget capturasse o foco, o mesmo teste passou.
- Correção de arraste: o gesto curto de toque entregava contato inicial, mas nenhum update antes de soltar. `DragStartBehavior.down` preserva o deslocamento acumulado; testes de entrada e saída fuzzy passaram para toque e mouse.
- `dart run tool/benchmark.dart`: ON/OFF, adaptativo, fuzzy e MPC completaram 60 s simulados com semente 42. Pontuação 2249. Pulos: 25, 25, 25 e 28. Reprodução das quatro séries a partir dos JSONs: idêntica.
- `evidence/comparison.json` contém o resumo; arquivos individuais CSV/JSON contêm os dados efetivamente produzidos.
- Bundle web final compilado em 81,1 s com CanvasKit local (`flutter build web --no-pub --no-web-resources-cdn --no-wasm-dry-run`). Não foi publicado.

## Limitações e pendências

- Inspeção visual e uso manual em navegador: não realizados. A abertura de localhost foi recusada pelo controle de permissões; nenhuma outra superfície de navegador foi usada para contornar a recusa.
- Testes de widgets verificam eventos e layout; não substituem uma partida manual em aparelho Android/iOS ou desktop.
- Som real, diálogos nativos de exportação/compartilhamento e uso offline em aparelho ainda precisam da validação manual descrita em DEVELOPMENT.md.
- iOS e macOS: estruturas oficiais geradas; compilação e assinatura dependem de Mac com Xcode e não foram executadas neste Windows.
- Windows desktop: não compilado; a resolução de plugins identificou ausência de suporte a links simbólicos. Nenhuma configuração de segurança do Windows foi alterada.
- O build Android mantém um aviso de compatibilidade futura do `share_plus` com Kotlin embutido no AGP. A versão fixada compilou com o Flutter atual; esse aviso deve ser reavaliado em uma atualização do SDK.
- Aceitação integral do produto permanece pendente até concluir a validação manual nas plataformas.

## Revisão de implementação

Separação entre domínio, Flame, persistência e interface. Configurações são copiadas ao iniciar sessões; o clássico usa configuração própria e desvia totalmente dos controladores. Variantes de controlador e pertinência usam switch exaustivo. Ações e edições têm convenção de tick documentada e teste de reprodução. Resultados exibidos e exportados provêm do motor, sem dados de demonstração inventados.
