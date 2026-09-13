# Plano 1:1 — trazer os avanços do repo irmão (padaria) para o site da Alice

**Escopo combinado:** Certificado · Próxima turma dinâmica · Gate de venda (TURMA_ATIVA) · Performance.
**Parado para depois:** NFS-e — código pronto, aguardando os dados fiscais da Alice (ver `docs/NFS-E.md`).
**Fora de escopo:** Método/Timer/Receitas, TTS/voz (só panificação).

Repo irmão: `C:\Padaria\mkt\site` (remote `ferrarijonas/paodeverdade`). Cada fase é um commit do upstream citado.

---

## Fase 0 — Pré-requisitos (bloqueiam TODAS as outras)

Backend NOVO criado na conta `paodeverdadeudi@gmail.com` (script próprio, nunca o da padaria):

- [x] Script novo + planilha nova vinculada; `.clasp.json` novo + `pdv-clasp/` (os IDs ficam no `.clasp.json`, gitignored — não no doc público).
- [x] `clasp push --force` + `clasp deploy` → deploy `AKfycbxJC4_OTv_lJDf4Dbh6LPIqDQByYIgPHj5hMY5J4gaqYpJwGSgGX8RO9SV86VtMB2Ib` (`ANYONE_ANONYMOUS` / `USER_DEPLOYING`).
- [x] `inscricao-config.js` com a `WEB_APP_URL` nova + `admin.html` lendo `PDV_CONFIG` (parou de apontar pra padaria).
- [x] Fallbacks da padaria removidos do backend (`getSheetId` usa a planilha vinculada; `getNotificarEmail` vazio).
- [ ] **Autorizar o script** (só o dono): abrir a URL do Web App logado em `paodeverdadeudi@gmail.com` e aceitar as permissões. Sem isso, o Web App responde 403 "Acesso negado".
- [ ] Gravar Script Properties: `PAINEL_SENHA` (**obrigatório antes de divulgar a URL**), `MP_ACCESS_TOKEN`, `NOTIFICAR_EMAIL`, `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID`, `PIX_KEY`.
- [ ] Rodar `criarAbas` (ou `?acao=setup`) e conferir `?acao=diagnostico`.
- [ ] `git push` do frontend (só depois de autorizar + senha).

**Dados da Alice:** senha do painel, token MP, chave Pix, e-mail de notificação, bot Telegram.

---

## Fase 1 — Próxima turma dinâmica  ·  upstream `8e53532` + `d24c81f`

Hoje as datas estão **hardcoded** (ex.: `curso-descoberta.html` "Próxima turma: sábado, 19/09/2026").
Passa a vir da planilha (aba `Turmas`).

- Backend: `proximasTurmas()` + rota pública `?acao=proximas`; helper `parseDataRegistro`; `filtrarTurmasAtivas` (usa o gate da Fase 2).
- Front: novo `assets/js/proximas.js` (+`.min`, copiado do irmão e adaptado: cursos Descoberta/Imersão, cores).
- Páginas: `index.html`, `agenda.html`, `curso-descoberta.html`, `curso-imersao.html` → renderizam a próxima turma do endpoint; **checkout sem data fixa**.
- Verificação: `?acao=proximas` ordena por data e reflete `Turmas`; home/agenda/curso mostram a mesma data.

**Depende de:** Fase 0. (A Fase 3 depende desta.)

---

## Fase 2 — Gate de venda TURMA_ATIVA  ·  upstream `78ea784`

Uma oficina por vez; turma encerrada bloqueada no front **e** no backend (fail-closed).

- Backend: `turmasAtivas()` / `turmaAtiva()`, gate em `criarPedido` (recusa antes do claim), `filtrarTurmasAtivas` em `listarTurmas`, whitelist `TURMA_ATIVA` na ação `config`.
- Front: `assets/js/checkout.js` trata `turma_nao_aberta`; páginas só mostram turmas ativas.
- Config: Script Property `TURMA_ATIVA` = `"Descoberta|dd/mm/aaaa;Imersão|dd/mm/aaaa"` (vazia = nada à venda).
- Verificação: turma fora da lista é recusada; `?acao=turmas` só devolve ativas.

**Dados da Alice:** quais turmas estão à venda agora.

---

## Fase 3 — Performance  ·  upstream `33fbc18`

- Backend: cache `turmas_vagas` de 60s → **300s** (planilha lê 1×/5min para todos).
- Front: remover o `<script src="assets/js/lotada.min.js">` das páginas (o `proximas.js` cobre ocupação) → **1 request por página**.
- Verificação: 1 chamada de rede por página; ocupação ainda correta.

**Depende de:** Fase 1 (proximas.js no ar).

---

## Fase 4 — Certificado  ·  upstream `d5edcdc` + `2546f9f` + `a069e3f` + `24c760c` + `e3b9a0b`

PDF gerado **no navegador** do aluno (html2canvas + jspdf), nº de registro atribuído pelo backend, e-mail automático.

- Backend: `gerarCertificado(token,curso,data)` + rota pública `?acao=gerarcertificado`; `proximoNumeroCertificado`; `registrarCertificados` + rota admin `?acao=registrarcertificados`; `autoConcluirTurmasPassadas`; e-mail **por pessoa** (`enviarEmailCertificadoRow`, `jaEnviouEmailCertificado`); trigger diário 6h `rotinaCertificadosAutomatica`; whitelist `SITE_URL` (+ `CERT_*` se usados).
- Front `aluno.html`: botão "Baixar certificado" gera o PDF no navegador; nº vem do backend; lazy-load das libs (~550KB) só quando clica.
- Front `admin.html`: mostra o nº do certificado e botão "enviar e-mail".
- Assets: `assets/js/html2canvas.min.js`, `assets/js/jspdf.umd.min.js`, `assets/img/assinatura.svg`/`.png` (**assinatura da Alice**), `assets/img/linha.png`.
- Config: Script Property `SITE_URL` (GitHub Pages da Alice) para o link do e-mail.
- Verificação: nº idempotente (2 cliques = 1 número); e-mail 1× por pessoa (dupla recebe 2); só após pagamento + oficina passada.

**Dados da Alice:** assinatura (imagem), `SITE_URL`, texto/marca do certificado, prefixo do número (`PDV-2026-XXX` → definir, ex.: `ALICE-2026-XXX`).

---

## Fase 5 — NFS-e  ·  PARADO (retomar depois)

Backend + `docs/NFS-E.md` + emissor local em `C:\Alice\mkt\Cursos\emissor-nfse\` já prontos.
Pendências em `docs/NFS-E.md` → "O que falta para operar". **Não ativar até decidirmos.**

---

## Verificação geral (sem framework)

Scripts temporários em `C:\Users\Alice\AppData\Local\Temp\opencode` (fora do repo). Por fase:
próximas ordena por data · gate recusa turma encerrada · 1 request/página · certificado idempotente e
e-mail 1×/pessoa · NFS-e em dry-run.

## Dados que preciso da Alice (consolidado)

- [ ] Acesso ao script/planilha dela + senha do painel (Fase 0)
- [ ] Token MP + bot Telegram (Fase 0)
- [ ] Quais turmas estão à venda (Fase 2)
- [ ] Assinatura (imagem) + `SITE_URL` + marca do certificado (Fase 4)
- [ ] Dados fiscais da NFS-e: certificado A1, CNPJ/IM, endereço, alíquota + código de serviço (contadora) — ver `docs/NFS-E.md`
