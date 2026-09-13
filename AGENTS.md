# AGENTS.md — Alice Gussoni (protocolo do harness)

Protocolo **obrigatório** para qualquer agente/sessão que opere este projeto. Leia antes de qualquer mudança.

## O que é o projeto
Site estático (GitHub Pages) + backend **Google Apps Script** + planilha Google + **Mercado Pago**.
Venda de vagas em cursos de cerâmica da Alice Gussoni, em Uberlândia/MG.
**Repo downstream da padaria** (`ferrarijonas/paodeverdade`): veja `SHARED.md` antes de editar qualquer `.js` compartilhado.

## Arquitetura em 3 camadas (importante!)
| Camada | Onde vive | Fica no git? |
|---|---|---|
| Código (este repo) | `C:\Alice\Cursos\Site` | ✅ sim |
| Dados (planilha) | Drive Google (`SHEET_ID`) | ❌ não (nuvem) |
| Segredos/config | **Script Properties** do Apps Script (`MP_ACCESS_TOKEN`, `PAINEL_SENHA`, `SHEET_ID`, `NOTIFICAR_EMAIL`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `WEB_APP_URL`) | ❌ não (nuvem, de propósito) |
| Config pública | `assets/js/inscricao-config.js` (`PDV_CONFIG`: WEB_APP_URL, PIX_KEY, WHATSAPP) | ✅ sim (é público mesmo) |

**Regra:** NUNCA commitar segredo. Dados e chaves vivem na nuvem; mover a pasta não move eles.

## Stack / mapa
- Backend FONTE: `backend/Code.gs` (Apps Script) — herdado da padaria; cursos/marca **ainda embutidos** (refatorar para config-driven, ver `SHARED.md`).
- Espelho de deploy: `pdv-clasp/Code.js` (gerado por cópia; `.clasp.json` e `pdv-clasp/` são gitignored). **Criar `.clasp.json` NOVO** apontando para o script DA ALICE — nunca o da padaria.
- Frontend: `index.html`, páginas de curso (a traduzir), `agenda.html`, `checkout.html`, `admin.html`, `aluno.html`.
- JS: fontes em `assets/js/` → min em `.min.js` (regenerar com terser). Páginas usam os `.min.js`.
- **Compartilhados (não editar):** `assets/js/main.js`, `analytics.js`, `lotada.js` (+ `.min`) — vêm do upstream por sync (ver `SHARED.md`).

## Deploy
1. **Backend:** edite `backend/Code.gs` → copie para `pdv-clasp/Code.js` → `clasp push --force` (na raiz) → `clasp deploy -i <ID_DO_DEPLOY_DA_ALICE> -d "descrição"`.
2. **Frontend:** edite `.js` → gere `.min.js` (terser) → `git add/commit/push origin main` → GitHub Pages (delay ~1 min). Páginas usam os `.min.js`.

## Como EU (harness) leio os dados — "braço do projeto"
Web App: `https://script.google.com/macros/s/AKfycbxJC4_OTv_lJDf4Dbh6LPIqDQByYIgPHj5hMY5J4gaqYpJwGSgGX8RO9SV86VtMB2Ib/exec` (deploy id = último segmento da URL; script id fica no `.clasp.json`, gitignored). Acesso com senha (PAINEL_SENHA). Endpoints (JSONP ok via `&callback=`):
- `?acao=dados&senha=` → inscritos, turmas (com vagas/ocupadas/restantes), pedidos, cupons, listaEspera
- `?acao=diagnostico&senha=` → **saúde do sistema**: resumo, turmas, erros recentes (ler no início da sessão)
- `?acao=logs&senha=&n=` → eventos recentes (Logs)
- `?acao=insights&senha=` → funil/vendas/por curso
- `?acao=analiticas&senha=` → **analítica de uso**
- `?acao=turmas` (público, cache 60s) → ocupação
- `?acao=listaespera` (público) · `?acao=logs` · `?acao=backup&senha=` · `?acao=criartriggerbackup&senha=` · `?acao=telegramtest&senha=` · `?acao=config&senha=&chave=&valor=` (whitelist de chaves)
- **NFS-e:** `?acao=notaspendentes&senha=` (fila) · `?acao=proximonumero&senha=` · `?acao=marcarnota&senha=&rowId=&chave=|erro=|motivo=` · `?acao=limparnota&senha=&rowId=` · `?acao=notaporid&senha=&rowId=` · `enviarnotaemail` (POST, emissor local)

Sempre use `-G --data-urlencode` com curl no PowerShell (a forma inline `?acao=x` falha intermitente).

## Regras de negócio (VAGAS — vigente, mesma base da padaria)
- **1 vaga = 1 pessoa × 1 curso numa data** (quem faz dois cursos usa 2 vagas). Dupla máx = 2 pessoas/pedido.
- Turma = `curso + dataTurma`. Capacidade = coluna `Vagas` na aba `Turmas` (default 10).
- **Ocupadas = `pago` + `aguardando` com ≤ 30min** (janela rolante).
- Bloqueio em `criarPedido`, dentro de LockService (idempotência + vagas).
- `?acao=setarvagas&senha=&curso=&dataTurma=&vagas=` para ajustar.
- Aba `ListaEspera` + `?acao=listaespera` (dedup) + `?acao=excluirespera&senha=&id=`.
- **Idempotência:** `client_order_id` único por tentativa; LockService + CacheService + checagem na aba Pedidos.

## NFS-e (nota fiscal de serviço — padrão nacional SEFIN)
- **1 vaga paga = 1 NFS-e** (dupla = 2 notas; valor por vaga = total do pedido ÷ nº pessoas). Emissão no **`emissor.py` local** (PC, `C:\Alice\mkt\Cursos\emissor-nfse\` — FORA do git, tem certificado A1 + senha do painel). Backend só monta a fila, numera, registra e envia e-mail. **Spec mestre: `docs/NFS-E.md`.**
- Endpoints (com `senha`): `notaspendentes` (fila de pagos sem nota, com `motivo`: vazio/cpf_invalido/pedido_nao_pago/valor_zero), `proximonumero`, `marcarnota`, `limparnota`, `notaporid`, `enviarnotaemail` (POST). Coluna **`Nota`** (aba Inscritos, col 25): `emitida:CHAVE` / `erro:MSG` (retry) / `isenta:` / `bloqueado:`.
- **Poka-yoke:** nDPS determinístico = sufixo do rowId; `existe_dps` antes de emitir (nunca duplica); e-mail ANTES de marcar (falha de e-mail re-tenta); `E0207` (CPF inexistente na Receita) → `bloqueado` (final). **O checkout valida só os dígitos do CPF, não a existência** — CPF fabricado passa e é pego na emissão.
- Alíquota `p_tot_trib_sn` = **4,00%** (DAS 07/2026, Anexo I Comércio) — **confirmar com a contadora da Alice** (MEI/Simples e anexo podem divergir).
- Tarefa agendada Windows `EmissorNFSe` (diária 06:00) roda `emissor.py --emitir`. Modos: `--testa-cpf` (valida CPF truncado em homologação), `--reenviar <rowId>`.

## Convenções
- Backend: padrões herdados — `getSheet`, `normalizarCurso`/`normalizarData`, `formatDate`, `responder(obj, callback)` (JSONP), erros em PT-BR, **sem comentários de código** (apenas blocos `/* --- */` de contexto).
- `finalizarPedido(pedidoId)` = ponto único onde venda vira paga; dispara log + backup por venda + notificação Telegram (guard `jaEraPago`).
- Backup: copia planilha → pasta Drive, mantém **30** cópias; trigger diário 6h.
- Erros do MP: `Logger.log` sempre; `registrarLog('erro', ...)` para eu ver no `diagnostico`.

## Ritual de início de sessão (obrigatório)
1. `git log --oneline -5` (contexto recente).
2. `?acao=diagnostico&senha=...` (saúde + turmas + erros) — quando o backend existir.
3. Se preciso, `?acao=logs&senha=&n=30`.

## Testes
Sem framework. Scripts temporários em `C:\Users\Alice\AppData\Local\Temp\opencode` (fora do repo). Valide pelo menos: criarpedido dupla bloqueada quando restantes==1, turma_cheia em 10/10, listaespera dedup, replay idempotente.