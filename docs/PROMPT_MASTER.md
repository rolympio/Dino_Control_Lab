# Prompt master — Dino Control Lab

Atualização recebida em 20/11/2026. Esta especificação define o produto; o estado de validação está em `VALIDATION.md`.

## Repositório e tecnologia

- Projeto: Dino_Control_Lab; GitHub: rolympio/Dino_Control_Lab.
- Repositório oficial: https://github.com/rolympio/Dino_Control_Lab.
- Flutter + Flame; Android, iOS e desktop.
- Inspecionar e preservar arquivos existentes. Inicializar a arquitetura se não houver aplicativo.
- Não executar push, merge ou publicação de releases sem autorização.
- Checkout local oficial: `D:\Repos\Dino_Control_Lab`.

## Modo Clássico obrigatório

Disponível diretamente no menu. Mecânica inspirada no Chrome Dino, sem controlador automático e sem configuração de controladores.

- Android/iOS: tocar para pular; manter pressionado um botão dedicado para abaixar.
- Desktop: Espaço/↑ para pular, ↓ para abaixar.
- Pausar, retomar e reiniciar após colisão.
- Dinossauro clássico inicial, cactos e obstáculos aéreos.
- Velocidade progressiva, pontuação, recorde pessoal, animações, colisões e som.
- Funcionamento offline.

## Modo Laboratório

- Controladores ON/OFF, adaptativo, fuzzy e MPC operacionais.
- Seleção de personagens, massas e propriedades físicas.
- Edição de parâmetros em tempo real.
- Entradas fuzzy triangulares, trapezoidais, gaussianas e sigmoidais.
- Saídas fuzzy exclusivamente triangulares.
- Gráficos interativos com arraste por dedo e mouse.
- Comparação de desempenho, simulações reproduzíveis e exportação CSV/JSON para Python/MATLAB.

## Menu

1. Jogar — Modo Clássico
2. Laboratório de Controle
3. Personagens e Física
4. Resultados e Gráficos
5. Experimentos Salvos
6. Configurações

## Aceitação

O projeto só é considerado funcional após validar jogo clássico completo sem controlador, toque e Espaço nas plataformas compatíveis, os quatro controladores, edição fuzzy por toque/mouse, exportação por sessão, compilação Android e estrutura iOS preparada para validação em macOS.

Ordem: clássico → física parametrizável → controladores → laboratório gráfico → exportação científica.

Não foram fornecidos outros documentos de requisitos anteriores além da lista desta atualização e do README inicial. Requisitos anteriores adicionais precisam ser reconciliados se forem apresentados.
