# Alice Gussoni — Cursos

Site dos cursos de **cerâmica** da Alice Gussoni — ateliê em Uberlândia/MG.

> Base herdada do site da Pão de Verdade (mesmo modelo de negócio: venda de vagas em turmas).
> Ver `SHARED.md` para o que é sincronizado do upstream e o que é fork da marca.

## Páginas

- `index.html` — Home
- `curso-pao.html` / `curso-pizza.html` — modelos a traduzir para os cursos de cerâmica
- `perguntas.html` — Perguntas Frequentes
- `quem-somos.html` — Quem Somos
- `agenda.html` / `checkout.html` / `admin.html` / `aluno.html` — funcional (vagas, pagamento, painel, área do aluno)

## Estrutura

```
assets/
├── css/style.css      → identidade visual (adaptar: paleta da Alice — ver DenaroDesignSpec.md)
├── js/                → inscricao-config.js (config pública), checkout/inscricao/espera/lotada/main/analytics
└── img/               → logo e fotos
backend/
└── Code.gs            → Apps Script (lógica de vagas/pagamento) — base herdada
tools/sync-upstream.ps1 + .github/workflows/sync-upstream.yml → sincronização com a padaria
```

## Estado atual

- **Backend:** pendente. Criar planilha + Apps Script + Mercado Pago da Alice e preencher
  `assets/js/inscricao-config.js` (ver `backend/COMO-CONFIGURAR.md`).
- **Catálogo:** pendente. Cursos/preços/datas da Alice ainda não definidos — páginas ainda têm o conteúdo-modelo da padaria.
- **Marca:** paleta/fonte já extraídas no projeto Denaro (`C:\Alice\Denaro\DenaroDesignSpec.md`).

## Deploy

Hospedado no GitHub Pages: `https://ferrarijonas.github.io/alicegussoni/`
(ideal futuro: `alicegussoni.github.io` — criar o repo na conta `alicegussoni` do GitHub e re-apontar)