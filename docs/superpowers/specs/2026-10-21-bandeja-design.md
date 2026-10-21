# Bandeja do Windows 11 para o COSMIC — design

Data: 2026-10-21 · Repositório: `~/Projetos/tray` → `github.com/Aenes0/cosmic-ext-applet-tray` (público,
como os outros forks).

## Intenção

O canto do painel perto do relógio deve se comportar como o do Windows 11 para os apps que rodam em
segundo plano (os ícones de bandeja, StatusNotifierItem — hoje, por exemplo, um "Σ" e um teclado):
alguns ficam **visíveis direto na barra**, os outros ficam **escondidos numa caixa que abre pela seta
para cima (^)**, e quem decide quem vai onde é o usuário, **arrastando**, como no Windows.

Por quê: a bandeja do COSMIC mostra todo app em segundo plano enfileirado no painel; com vários, a
fila cresce e o painel fica poluído. O usuário quer o painel limpo e o controle do que aparece.

## Ponto de partida (o que já existe e é reaproveitado)

Fork do applet `cosmic-applet-status-area` do `pop-os/cosmic-applets`, **versão 1.10.0** (a instalada:
pacote `cosmic-applets 1:1.10.0`; fonte em `~/.cargo/git/checkouts/cosmic-applets-*/406d1b7/
cosmic-applet-status-area`, GPL-3.0). Ele já faz:

- a conversa com os apps (StatusNotifierItem via D-Bus) e os menus deles (`com.canonical.dbusmenu`);
- um modo recolhido: quando o espaço dado pelo painel acaba, mostra só parte dos ícones e um botão
  de seta (`go-up-symbolic` com o painel embaixo) que abre um popup com o resto
  (`overflow_index`, `view_overflow_popup`, `Msg::ToggleOverflow` em `src/components/app.rs`).

O serviço que coleta os ícones (`com.system76.CosmicStatusNotifierWatcher`, unidade systemd de
usuário do próprio pacote) **continua sendo o do sistema**: o fork não o substitui nem o inicia.

O padrão de projeto segue o da barra de tarefas (`~/Projetos/taskbar`, fork do `cosmic-app-list`):
crate próprio, mesmas fixações de versão do `cosmic-applets epoch-1.10.0` no `Cargo.toml`
(libcosmic, `sctk 0.20.0`, `cosmic-protocols rev c0cff4d`), `install.sh` para `~/.local`,
`setup.sh` para trocar no painel e `setup.sh --undo` para voltar, README em português.

## Comportamento

### No painel

- Da esquerda para a direita: os ícones dos apps **escolhidos como visíveis**, na ordem escolhida,
  e então o botão **^**.
- Quando **não há nenhum app escondido**, o botão ^ some (como no Windows). *(decisão minha)*
- Sem nenhum app em segundo plano, o applet não mostra nada.

### Na caixa (abre pelo ^)

- Os apps escondidos em **grade de até 5 por linha**, ícones do mesmo tamanho dos do painel.
- Ao passar o mouse, o **nome do app** (Title do item; na falta, o Id) numa dica.
- Fecha ao clicar fora, ao clicar de novo no ^, ou ao abrir um app/menu de dentro dela.

### Cliques (na barra e na caixa, iguais)

- **Esquerdo:** ativa o app (`Activate` do StatusNotifierItem — o que o upstream já faz na barra).
  Na caixa o upstream abre o menu com qualquer clique; isso muda para ativar.
- **Direito:** abre o menu do próprio app (o popup de dbusmenu que o upstream já tem).
- Item que não implementa `Activate` (alguns só têm menu): o clique esquerdo abre o menu, como o
  upstream faz quando a ativação falha. *(decisão minha; conferir o comportamento atual no fonte)*

### Escolher quem fica na barra: arrastar

- Arrastar um ícone **da caixa para a barra** o torna visível, na posição em que for solto.
- Arrastar **da barra para a caixa** (soltar sobre o ^ ou dentro da caixa aberta) o esconde.
- Arrastar **ao longo da barra** reordena os visíveis. *(decisão minha)*
- Durante o arrasto, um espaço se abre onde o ícone vai cair (como na barra de tarefas).
- Implementação: DnD do Wayland com `dnd_source` / `DndDestination` do libcosmic, que funciona
  entre superfícies do mesmo programa — a caixa (popup) e o applet no painel. A barra de tarefas
  já usa esse mecanismo para reordenar (`taskbar/src/app.rs`: `DndSource::with_id`,
  `drag_content`, mensagens `DndEnter/DndMotion/DndLeave/DndData/DndDropFinished`). O conteúdo
  arrastado é o identificador do app (abaixo), num tipo MIME próprio, para não aceitar arrastos de
  outros programas.
- Arrastar e soltar fora de qualquer destino não muda nada.
- **Esconder com tudo visível** (a ^ sumiu): ao começar a arrastar um ícone da barra, a ^ aparece
  como alvo, como no Windows. *(decisão minha)*
- **Destino para esconder é a ^**, não o interior da caixa aberta: a caixa fecha com clique fora
  (popup com grab), e o clique que começa um arrasto na barra a fecharia. Arrastar **de dentro** da
  caixa para a barra deve funcionar (o arrasto começa dentro do popup); a caixa fecha ao soltar.
  Se o ícone arrastado era o último escondido, a ^ some depois do solto. *(decisão minha)*
- **Primeira tarefa do plano: provar o arrasto entre superfícies** (do popup da caixa para o applet
  no painel) no cosmic-comp. A barra de tarefas só arrasta dentro de uma superfície, então isso
  não está provado aqui.
- **Plano B, se o arrasto entre superfícies não funcionar** (decisão do usuário): no menu do clique
  direito de cada ícone, um item próprio no fim — "Mostrar na barra" (para os da caixa) / "Esconder
  na caixa" (para os da barra). O reordenar ao longo da barra (mesma superfície) continua por
  arrasto. O plano B é implementado só se a prova falhar.

### Apps novos

- Um app que aparece pela **primeira vez** em segundo plano vai **escondido na caixa**
  (padrão do Windows 11).

### Memória da escolha

- A lista ordenada dos **visíveis** é guardada em cosmic-config, num id próprio do applet
  (`io.github.Aenes0.CosmicTray`, chave `visible: Vec<String>`), e vale para todos os monitores
  (as três instâncias do applet leem e observam a mesma configuração; mudar numa reflete nas
  outras).
- Tudo o que não está em `visible` está escondido; não é preciso guardar a lista dos escondidos.
- **Identidade de um app:** a propriedade `Id` do StatusNotifierItem (estável entre execuções, ex.:
  o nome do app); se vier vazia, o `Title`. Não usar o nome D-Bus do serviço (muda a cada execução).
  *(decisão minha)*
- Dois itens com o mesmo Id (raro: duas instâncias do mesmo app) seguem juntos a mesma escolha.
- O proxy do upstream não lê `Id` nem `Title`: o fork passa a lê-los, de forma assíncrona, depois
  do registro do item. **Até a identidade chegar, o item fica na caixa**, e a identidade fica
  **fixa na primeira leitura** (um `NewTitle` depois não muda a chave). *(decisão minha)*

### Quando falta espaço no painel

- A divisão visível/escondido é do usuário, mas o painel ainda limita a largura do applet
  (`suggested_bounds`). **Se os visíveis não couberem, os que sobram (do fim da ordem) vão para a
  caixa**, sem mudar a escolha guardada — nenhum app pode sumir. *(decisão minha)*
- Se o próprio painel mandar o applet inteiro para o overflow dele, o applet segue funcionando
  como o upstream nesse caso (a ^ e a caixa abrem a partir dali); sem tratamento especial além
  disso. *(decisão minha)*

## Identidade e instalação

- App ID: `io.github.Aenes0.CosmicTray`; binário `cosmic-ext-applet-tray`; nome no painel
  "Bandeja" (inglês: "Tray"); `.desktop` com `X-CosmicApplet=true` e as mesmas chaves de overflow do
  upstream (`X-CosmicHoverPopup=Auto`, `X-OverflowPriority`, `X-OverflowMinSize`) revistas para o
  novo comportamento.
- `setup.sh`: troca `com.system76.CosmicAppletStatusArea` por `io.github.Aenes0.CosmicTray` em
  `plugins_wings`/`plugins_center` do painel; `--undo` devolve. Não mexe no serviço do watcher.
- Idiomas: português e inglês, conforme o sistema (como os outros applets).

## Metas, não-metas, anti-metas

- **Metas:** painel limpo; escolher por arrasto o que aparece; caixa da ^ igual à do Windows 11;
  nada dos menus e da ativação dos apps pode piorar em relação à bandeja do COSMIC.
- **Não-metas:** página de configurações para escolher os ícones (o Windows tem; aqui só arrastar);
  animações além do espaço que se abre no arrasto; mexer no serviço watcher.
- **Anti-metas (seria fracasso mesmo funcionando):**
  - perder a escolha do usuário ao reiniciar o app, o painel ou o computador;
  - um app em segundo plano que some (nem na barra, nem na caixa);
  - o applet gastar CPU parado (a medição dos outros applets é a régua: nenhuma acordada em
    repouso além das que os apps provocam);
  - quebrar menus de apps que funcionam na bandeja do COSMIC.

## Restrições

- Mesmas versões do painel instalado (cosmic-applets 1.10.0); não atualizar libcosmic por conta.
- Ambiente: o shell do Claude roda em sandbox Flatpak; compilar e instalar com `flatpak-spawn --host`.
- Saída de erro: um processo do painel pode perder a stderr; não usar `eprintln!` e configurar o
  tracing com `log_internal_errors(false)` (lição do menu Iniciar, commit `fa174b4`).

## Deixado para quem constrói

- Estrutura interna do código, nomes, e como dividir as mudanças em `app.rs`.
- Detalhes visuais finos da caixa (espaçamentos, raio), seguindo o `popup_container` do applet.
- Como testar o arrasto (provavelmente manual, com print); a lógica de lista visível/escondida,
  ordem e identidade deve ter testes unitários.
