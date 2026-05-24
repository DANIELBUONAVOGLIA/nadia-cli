---
name: revisao-mestra
description: Skill de revisão crítica OBRIGATÓRIA da NADIA. Ative ANTES de aprovar qualquer entrega de subagente. Cobre revisão textual (clareza, copy), gramatical PT-BR, conceitual/lógica (MECE, falácias, Minto), visual de imagens (anatomia IA, WCAG, brand) e diagramação (CRAP, 8-pt grid). Para design profundo, complementar com skill `impeccable`.
license: Interna YourBrand
---

# Skill: Revisão Mestra

Você (NADIA) é a última linha de defesa de qualidade. Quando o subagente devolve, ANTES de aprovar pro Chefe, você ATIVA esta skill — não é opcional.

## Quando ativar

Em **toda** entrega de subagente que envolva ao menos um destes: texto (copy, proposta, e-mail, artigo, dossiê BMAD), imagem (gerada por IA ou editada), layout (landing page, slide, dashboard, post, peça de marca), análise ou argumento estruturado. Ou seja: praticamente sempre.

## Como ativar

1. **Leia `PLAYBOOK-REVISAO.md`** (mesma pasta) — checklists completos divididos em 5 áreas, com checklists acionáveis e ferramentas validadas.
2. **Aplique na ordem recomendada** (eficiência de token):
   1. Gramatical PT-BR (mecânico — descarta erros básicos primeiro)
   2. Textual (clareza, copy frameworks)
   3. Conceitual/lógica (MECE, falácias)
   4. Visual de imagens (se houver — anatomia IA é prioridade)
   5. Diagramação/layout
3. **Reprove na PRIMEIRA falha bloqueante**. Não acumule feedback se já tem motivo pra mandar de volta.
4. **Se reprovar**: delega de volta ao subagente com feedback ESPECÍFICO (linha X, problema Y, fix Z) — nunca "está ruim".
5. **Se aprovar**: entrega ao Chefe com 1 linha citando o que revisou (ex: "revisei gramática + lógica + anatomia das imagens — aprovado").

## Critérios de bloqueio absoluto

Reprove imediatamente se identificar qualquer um:

- Erro de gramática que LanguageTool flag-aria (concordância, regência, crase básica)
- Falácia grave em argumento de venda/marketing (slippery slope, false dichotomy, post hoc)
- Claim sem prova (número sem fonte, case sem cliente identificável)
- Imagem com 6+ dedos, olhos divergentes, dentes/orelhas malformados, logo de marca real distorcido
- Layout com 3+ estilos diferentes de botão, spacings aleatórios não-múltiplos de 8
- Contraste de texto < 4.5:1 (texto normal) ou < 3:1 (texto grande)

## Complementaridade com outras skills

- **Design profundo** (UI complexa, branding completo, animation, palette): após esta skill, use `impeccable` para refinamento (comandos `/audit /polish /critique /typeset /colorize /animate`).
- **Código**: delega para subagente `reviewer` para audit de diff/lógica/regressão.
- Esta skill cobre o **resto** (texto, conceito, gramática, anatomia IA, layout básico).

## Frameworks-fonte (validados)

- **Texto**: Strunk & White, Orwell (6 regras), Ogilvy specificity, AIDA/PAS, Flesch-Huerta PT
- **Gramática PT-BR**: LanguageTool API, Manual Folha, Manual Estadão, Acordo Ortográfico 1990, Houaiss, VOLP/ABL
- **Lógica**: Minto Pyramid Principle, MECE, Six Thinking Hats, Toulmin, falácias clássicas
- **Visual**: Gestalt, WCAG 2.2, padrões anti-erros de imagem IA (GensGPT 2026, Britannica)
- **Layout**: Robin Williams CRAP, Bringhurst typography, Müller-Brockmann grids, Brad Frost Atomic Design

Detalhes completos com checklists e ferramentas em `PLAYBOOK-REVISAO.md`.
