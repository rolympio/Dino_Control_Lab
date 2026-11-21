# Dino Control Lab — interface

Interface nativa Flutter / Material 3, em português, utilizável offline.
Prioridade: jogar imediatamente; depois ajustar física, executar experimentos e analisar resultados.

## Tokens

Tema claro: fundo #F6F7F3, tinta #202820, primária #356449.
Tema escuro: fundo #161C18, tinta #E1E8DE, primária #A0D4AD.
Tipografia: fonte de sistema; títulos 24/32, corpo 16, rótulos 14.
Espaçamento: 8, 16, 24, 32. Largura de leitura: 1080. Alvos mínimos: 48.
Material 3 fornece estados focado, pressionado, desabilitado e semântica dos controles.

## Layout e componentes

Layout: Scaffold com AppBar fixa e ListView como único dono da rolagem nas páginas de configuração.
Jogo: arena flexível, HUD e controles fixos, SafeArea em todos os dispositivos.
Laboratório: arena acima dos parâmetros; disposição vertical rolável no telefone.
Menu: uma ação primária para o Modo Clássico e cinco linhas de navegação.
Resultados: tabela rolável horizontalmente, gráfico de altura no tempo e exportação por sessão.
Editor fuzzy: gráfico com pontos arrastáveis por ponteiro/toque, acompanhado por sliders acessíveis.

## Contrato das telas

- Menu: seis destinos exigidos; Modo Clássico sem configuração prévia.
- Jogo: pontuação, recorde, pausa, reinício, pulo e botão de abaixar mantido pressionado.
- Laboratório: quatro controladores, semente, física ao vivo, edição fuzzy e comparação.
- Personagens: dinossauro, robô e corredor; massa, gravidade, impulso e arrasto.
- Resultados: métricas reais, seleção de sessão, gráfico e arquivos CSV/JSON.
- Experimentos: configurações nomeadas persistidas e reaplicáveis.
- Configurações: som e tema.

## Verificação

Verificar temas claro/escuro, larguras de telefone/desktop, teclado, toque, rolagem e estados vazios.
Referência espacial: controles nativos Material 3, sem assets remotos ou fontes de rede.
As receitas CSS/DOM das skills frontend não se aplicam ao canvas Flutter.
QA visual pendente até existir uma compilação executável.
