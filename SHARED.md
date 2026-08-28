# Arquivos compartilhados (herdados do upstream)

Este repo é um **downstream** de `https://github.com/ferrarijonas/paodeverdade` (o site da padaria).

## Regra

Os arquivos abaixo **nunca são editados aqui** — eles são copiados do upstream
(padaria) automaticamente. Corrigiu/evoluiu lá → chega aqui sozinho.

| Arquivo | Por quê |
|---|---|
| `assets/js/main.js` / `.min.js` | menu mobile, rodapé, feed do Instagram |
| `assets/js/analytics.js` / `.min.js` | rastreador leve (sem cookies) |

> `lotada.js` foi **removido** do sync: é a trava de compra, mas tinha os cursos
> (`['Pão','Pizza']`) embutidos. Está forkado localmente com os cursos da Alice.

## Como sincronizar

- **Manual:** `powershell -File tools/sync-upstream.ps1` na raiz, revisar, `git add -A && git commit -m "sync upstream" && git push`.
- **Automático:** GitHub Action `sync-upstream` roda todo dia 06:00 UTC (+ manual). Commita com a hash do upstream; sem mudança, não faz commit.

## O que NÃO é compartilhado (fork por marca)

Cursos, preços, textos e marca da Alice são dela e divergem de propósito:

- `backend/Code.gs`, `backend/painel.html` — a lógica de vagas/pagamento é a base, mas os cursos (`Pão`/`Pizza`), a marca e as URLs estão embutidos e precisam ser **parameterizados** (ver abaixo).
- `assets/js/checkout.js`, `inscricao.js`, `espera.js`, `inscricao-config.js` — cursos/preços/horários embutidos.
- `assets/css/*`, todos os `.html`, `assets/img/*`, `assets/data/*`.

## Caminho para "evoluir junto de verdade"

Hoje o específico é fork (editado aqui + na padaria). Para os dois sites passarem
a compartilhar o específico sem conflito, refatore **no repo da Alice** para
config-driven: cursos, preços, horários e marca saindo de `PDV_CONFIG` (front)
e Script Properties (backend), mantendo a estrutura 1:1 com a padaria. Depois,
adoção na padaria e o sync cobre tudo.