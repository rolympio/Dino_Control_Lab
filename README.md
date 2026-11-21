# Dino_Control_Lab
Dino Control Lab é um jogo para Android e iOS inspirado no dinossauro do Chrome. Jogue manualmente com o dedo ou barra de espaço, escolha personagens e ajuste sua física. Experimente quatro controladores (ON/OFF, adaptativo, fuzzy e MPC), edite gráficos interativos, compare desempenhos e exporte dados CSV para análise.

## Implementação

Flutter + Flame, com Modo Clássico manual e Laboratório de Controle. Menu em português, física editável, quatro controladores, editor fuzzy por toque/mouse, resultados, experimentos locais e exportação CSV/JSON. Dinossauro e sons são desenhados/gerados localmente; o aplicativo nativo não depende de rede.

## Início

```sh
flutter pub get
flutter run
```

SDK usado na validação: Flutter 3.50.1 / Dart 3.14. Dependências fixadas em pubspec.lock.

- [Prompt master](docs/PROMPT_MASTER.md)
- [Arquitetura e unidades físicas](docs/ARCHITECTURE.md)
- [Compilação, iOS e análise em Python/MATLAB](docs/DEVELOPMENT.md)
- [Evidências e pendências de validação](docs/VALIDATION.md)
- [Comparação real dos quatro controladores](evidence/comparison.json)

O Modo Clássico usa Espaço/↑ ou toque para pular, ↓ ou botão mantido para abaixar e P/Esc para pausa. O laboratório permite alterações ao vivo; a semente entra em vigor ao reiniciar.

A aceitação integral permanece pendente de testes manuais nas plataformas. A estrutura iOS foi preparada, mas precisa de macOS/Xcode para compilação. Nenhum push, merge ou release foi realizado.
