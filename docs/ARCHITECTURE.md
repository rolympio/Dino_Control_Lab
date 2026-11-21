# Arquitetura e modelo científico

`lib/domain`: estado de simulação em Dart puro, configuração tipada, funções de pertinência e controladores.
`lib/game`: adaptação Flame, acumulador de tempo e desenho vetorial animado.
`lib/ui`: páginas e controles Flutter/Material. O clássico nunca chama o controlador.
`lib/data`: persistência, sessão, reprodução, CSV e JSON.

## Motor

Passo fixo de 1/120 s; renderização desacoplada. O acumulador limita a recuperação de um frame a 100 ms para evitar saltos de simulação quando a aplicação trava. O relógio científico é tempo simulado, não tempo de parede. Pausa e perda de atividade não avançam a simulação.

Coordenadas de mundo em pixels, tempo em segundos, massa em kg. Impulso em kg·px/s; gravidade em px/s²; arrasto em kg/s. Não se deve interpretar um pixel como um metro sem definir uma escala externa.

Integração semi-implícita de Euler: `v += (-g - c*v/m)*dt`, `y += v*dt`. O impulso inicial define `v = J/m`. O chão limita y a zero. A geometria usa caixas com tolerância de 3 px. A velocidade horizontal cresce de 300 até 650 px/s. Um gerador congruencial de 32 bits, definido no código, torna a sequência de obstáculos independente do gerador aleatório de cada plataforma.

## Controladores

- ON/OFF: compara o tempo até contato horizontal com um limiar editável.
- Adaptativo: atualiza uma antecipação estimada usando a física atual, altura/largura do obstáculo e ganho de adaptação. É adaptação paramétrica baseada no modelo, sem treinamento por aprendizado de máquina.
- Fuzzy: inferência Mamdani sobre tempo até impacto. A pertinência de proximidade ativa a saída pular e seu complemento ativa correr. Agregação máximo/mínimo e centroide discretizado em 101 pontos. Ambas as saídas permanecem triangulares; centros e largura são editáveis.
- MPC: avalia seis sequências candidatas de pulo adiado/ausente em um horizonte finito, penalizando colisão e esforço. Recalcula a decisão e executa apenas a primeira ação. É MPC discreto por enumeração, sem otimizador contínuo.

Obstáculos aéreos usam uma regra comum de abaixar quando necessário. O laboratório aceita combinações de física que tornam um obstáculo impossível; esses insucessos são resultados do experimento.

## Dados

CSV registra amostras em 10 Hz mais a colisão final. JSON versão 1 inclui motor `fixed-step-v1`, passo, semente, configuração inicial, ações e mudanças de parâmetros indexadas por tick. Ações referem-se ao tick que acaba de ser integrado; alterações de configuração são aplicadas antes do próximo tick. `lib/data/replay.dart` reconstrói a trajetória com essas convenções.

A comparação executa cada controlador por até 60 segundos simulados, parando na primeira colisão. A interface mostra pontuação, duração, pulos e causa de término. Resultados dependem da semente e da física; uma comparação isolada não estabelece superioridade geral.

Recorde, configurações, experimentos e histórico de sessões são persistidos localmente com SharedPreferences. Não há servidor nem conta. Para históricos extensos, exporte os arquivos; a implementação inicial mantém as sessões em memória e no armazenamento de preferências, sem compressão ou banco dedicado.
