# NFS-e Nacional — Alice Gussoni (spec mestre)

> **STATUS: PARADO — retomar depois.** Código já portado e no repo (backend + emissor
> local + esta spec). Falta a identidade fiscal da Alice (ver "O que falta para operar").
> **Não deployar/ativar até decidirmos retomar.**

Sistema de emissão automática de **Nota Fiscal de Serviço Eletrônica** (padrão
nacional SEFIN/Receita) para cada vaga paga de oficina (Descoberta/Imersão).
Emite 1 nota por pessoa pagante, no valor que ela pagou, e envia por e-mail.

Portado do repo irmão da padaria (`ferrarijonas/paodeverdade`, commit `a988f68`).
O que muda aqui é só a **identidade fiscal da Alice** (ver "O que falta").

## Arquitetura

```
Planilha Google (aba Inscritos/Pedidos)
   │  ?acao=notaspendentes  (fila de pagos sem nota)
   ▼
emissor.py (PC local, certificado A1)
   │  DPS → assinatura XMLDSIG → gzip+b64 → POST mTLS
   ▼
SEFIN Nacional (https://sefin.nfse.gov.br/SefinNacional/nfse)
   │  NFS-e + chave de acesso + XML
   ▼
   ├─ baixar DANFSe (ADN) ou gerar PDF local → enviarnotaemail (backend → Gmail)
   └─ marcarnota (coluna Nota na aba Inscritos)
```

## Componentes

| Componente | Onde | Papel |
|---|---|---|
| `backend/Code.gs` | Google Apps Script | fila, numeração, registro, e-mail |
| `emissor.py` | `C:\Alice\mkt\Cursos\emissor-nfse\` (PC, fora do git) | emissão via SEFIN com certificado A1 |
| `config.json` | junto ao `emissor.py` | segredos + ambiente + alíquota (**não commitar**) |
| Tarefa `EmissorNFSe` | Windows Task Scheduler, diária 06:00 | roda `emissor.py --emitir` |

## Backend (endpoints, todos com `senha`)

| Ação | Função | Descrição |
|---|---|---|
| `notaspendentes` | `notasPendentes()` | fila: inscritos `pago` sem nota. Calcula **valor por vaga = total do pedido ÷ nº pessoas**. Classifica `motivo`: vazio (pronto) · `cpf_invalido` · `pedido_nao_pago` · `valor_zero`. Pula linhas com `emitida:`/`isenta:`/`bloqueado:`; **`erro:` volta pra fila** (retry). |
| `proximonumero` | `proximoNumeroDPS()` | contador atômico (LockService) — fallback de numeração |
| `marcarnota` | `marcarNota(p)` | grava `emitida:CHAVE` / `erro:MSG` / `isenta:MOTIVO`. Nunca sobrescreve `emitida:`/`isenta:` (poka-yoke). |
| `limparnota` | `limparNota(rowId)` | limpa a coluna Nota (reprocessar uma linha) |
| `notaporid` | `notaPorId(rowId)` | retorna dados da linha + chave (usado no `--reenviar`) |
| `enviarnotaemail` | `enviarNotaEmail(b)` (POST) | e-mail com a NFS-e (PDF anexo) pelo GmailApp |

**Coluna `Nota`** (aba Inscritos, coluna 25): `emitida:<chave>` (final) ·
`erro:<msg>` (retry) · `isenta:<motivo>` / `bloqueado:...` (final, exige ação).

## emissor.py (modos)

```
emissor.py                    # dry-run (mostra o plano, emite nada)
emissor.py --emitir           # executa (ambiente do config.json)
emissor.py --emitir --limit 1 # 1 vaga
emissor.py --testa-cpf        # valida CPFs truncados em HOMOLOGAÇÃO
emissor.py --reenviar <rowId> # reenvia a nota de uma vaga já emitida
```

Fluxo por vaga (à prova de erro):
1. `nDPS` **determinístico** = sufixo numérico do `rowId` → reexecutar nunca duplica.
2. `existe_dps(did)` antes de emitir → se já emitida, resgata a chave (idempotência em retries).
3. Emite (3 tentativas com backoff em falha de rede).
4. PDF: tenta o **DANFSe oficial** do ADN; se falhar, **gera localmente** do XML.
5. **Envia e-mail antes de marcar** → se o e-mail falhar, a linha fica pendente e o
   próximo run reenvia (self-healing). Nunca re-emite (item 2).
6. `marcarnota` grava a chave.
7. Falha com `E0207` (CPF inexistente na Receita) → marca `bloqueado` (final, exige
   CPF correto); demais erros → `erro:` (retry).

## Regras de negócio

- **1 vaga = 1 pessoa = 1 NFS-e.** Dupla → 2 notas; cada uma vale `total do pedido ÷ nº pessoas` (descontos duo/cupom já embutidos).
- **Tomador** = aluno (CPF + nome + e-mail). CPF deve **existir na Receita** (o SEFIN rejeita com `E0207`).
- **Serviço**: cTribNac `080201` (item 8.02 LC 116) · NBS `122051900` (1.2205.19.00) · descrição "Oficina de Descoberta/Imersão - curso presencial". **Confirmar o código com a contadora** — cerâmica pode ter enquadramento diferente.
- **Data de competência** = data da turma. **Local** = Uberlândia (IBGE 3170206).
- **Prestador**: Simples Nacional ME/EPP (`opSimpNac=3`, `regApTribSN=1`), ISS não retido, `pTotTribSN` = alíquota efetiva do DAS (**confirmar com a contadora**).
- **Numeração oficial** (`nNFSe`) é atribuída pelo SEFIN; lida do XML de retorno e impressa no DANFSe.

## Poka-yoke (camadas)

1. Checkout: máscara 11 dígitos + checagem de dígito verificador (front e `criarPedido`).
2. Fila: `notaspendentes` re-valida CPF e bloqueia os inválidos.
3. Emissão: `existe_dps` impede duplicidade; `nDPS` determinístico.
4. Existência real: o SEFIN (`E0207`) valida contra a Receita — **o checkout só valida os dígitos, não a existência**; por isso CPF fabricado passa no checkout e é pego aqui (fica `bloqueado` e o emissor reporta).
5. E-mail: enviado antes de marcar → falha de e-mail re-tenta no próximo run.

## Operação

- `testar-dry.bat` — mostra o plano. `rodar-notas.bat` — executa produção.
- Tarefa agendada `EmissorNFSe` — diária 06:00 (alinhada ao backup).
- Log: `emissor-nfse\emissor.log`.
- **Produção**: `config.json` → `"ambiente": "producao"`. Homologação: `"homologacao"`.
- Reprocessar uma linha: corrija o dado → `?acao=limparnota&senha=&rowId=` → rode.

## Troubleshooting

| Situação | Causa | Ação |
|---|---|---|
| `cpf_invalido` na fila | CPF faltando/truncado/fabricado | pedir CPF real ao aluno; `?acao=atualizar&id=&cpf=` |
| `pedido_nao_pago` | inscrito pago sem linha de Pedidos (fluxo antigo) | criar/ajustar pedido na planilha |
| `E0207` | CPF não existe na Receita | corrigir CPF; `limparnota` + `atualizar` |
| e-mail não chega | enviado antes de marcar → fila re-tenta | rodar de novo ou `--reenviar <rowId>` |
| DANFSe oficial fora | ADN instável | fallback local automático (PDF gerado do XML) |

## O que falta para operar (dados da Alice)

1. **Certificado A1** (`.pfx`) + senha — no PC, em `emissor-nfse\`.
2. **CNPJ/MEI + razão social + Inscrição Municipal** do prestador.
3. **Endereço fiscal** (CEP, logradouro, número, bairro) e **município IBGE** (3170206 Uberlândia).
4. **Enquadramento fiscal** (MEI ou Simples/ME) + **alíquota efetiva do DAS** (`p_tot_trib_sn`) + **código de serviço** (cTribNac/NBS) — **confirmar com a contadora**.
5. **WEB_APP_URL** e **PAINEL_SENHA** do backend dela (para o emissor falar com o Apps Script).
6. Criar o **`.clasp.json` novo** apontando para o script DA ALICE (nunca o da padaria) e fazer o deploy do backend.

> Enquanto os itens 1–5 não existirem, `emissor.py` roda só em **dry-run** (não emite nada).
