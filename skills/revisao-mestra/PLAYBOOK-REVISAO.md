# Playbook NADIA — Revisão Crítica de Material

Reference operacional consultada via skill `revisao-mestra`. Cada área tem checklists acionáveis, fontes validadas e ferramentas confiáveis.

---

## 1. Revisão Textual (clareza, concisão, fluxo)

### Princípios validados

- **Orwell — "Politics and the English Language" (1946)**: 6 regras universais para prosa clara.
- **Strunk & White — "The Elements of Style" (1959, 4ª ed. 1999)**: "Omit needless words", uso de voz ativa, frases positivas.
- **Hemingway editor (heurística)**: frases curtas, evitar advérbios, evitar voz passiva, vocabulário simples.
- **Plain Language Movement (plainlanguage.gov, EUA)**: padrão governamental para comunicação pública.

### Frameworks de copywriting

- **AIDA** (Elias St. Elmo Lewis, 1898): Atenção → Interesse → Desejo → Ação.
- **PAS** (popularizado por Dan Kennedy): Problema → Agitação → Solução. Melhor para retargeting / fundo de funil.
- **4Ps** (Henry Hoke / direct response): Promessa → Pintura (visualização) → Prova → Pitch.
- **Ogilvy — "Confessions of an Advertising Man" (1963)** e *"Ogilvy on Advertising"* (1983): headline carrega 80% do peso; específico vence genérico; fatos vencem adjetivos.

### Métricas de legibilidade

- **Flesch Reading Ease** (Rudolf Flesch, 1948): 0–100, quanto maior, mais fácil. Para inglês.
- **Fernández-Huerta (1959)**: adaptação para espanhol — fórmula `206.84 − (0.60 × P) − (1.02 × F)`. Usada como proxy para PT-BR.
- **Flesch adaptado por Martins et al. (1996)** para português do Brasil.
- **ALT (Avaliador de Legibilidade de Textos)** — UPorto, específico para PT.
- **Alvo prático em copy de marketing PT-BR**: Flesch-Huerta ≥ 70 (fácil).

### Checklist NADIA — texto

- [ ] **Corte 1 — gordura**: para cada frase, pergunte "se eu remover esta palavra, perde sentido?". Se não, remova. Alvo: −20% no comprimento.
- [ ] **Corte 2 — voz passiva**: marcar toda construção `ser/estar + particípio` ("foi feito", "é considerado"). Reescrever em ativa salvo razão clara.
- [ ] **Corte 3 — clichês e jargão**: banir "soluções inovadoras", "experiência única", "no mundo de hoje", "alavancar sinergia". Trocar por verbo concreto + número.
- [ ] **Corte 4 — frases longas**: nenhuma frase passa de 25 palavras sem justificativa. Quebrar em duas.
- [ ] **Corte 5 — advérbios em -mente**: limitar a 1 por parágrafo. "Trabalha rapidamente" → "entrega em 48h".
- [ ] **Headline test**: a primeira linha responde "por que devo continuar lendo?". Se não, reescrever.
- [ ] **AIDA/PAS check em copy de anúncio**: identificar explicitamente cada estágio. Se faltar Ação clara (CTA), reprovar.
- [ ] **Specificity test (Ogilvy)**: trocar adjetivos vagos por fato verificável ("rápido" → "em 3 minutos"; "muitos clientes" → "1.200 empresas").

### Ferramentas

- **LanguageTool** (open source, API): cobre estilo além de gramática.
- **Hemingway App** (heurística — apenas inglês, mas lógica adaptável).
- **textstat** (Python): calcula Flesch e variantes, inclusive PT.

---

## 2. Revisão Gramatical em Português BR

### Manuais de referência (padrão indústria)

- **Manual de Redação da Folha de S.Paulo** (Publifolha, ed. revista 2018; atualização IA 2024).
- **Manual de Redação e Estilo do Estadão** (Eduardo Martins).
- **Dicionário Houaiss da Língua Portuguesa** (2009, atualizado pós-Acordo).
- **Acordo Ortográfico de 1990** (vigência obrigatória no Brasil desde 2016).
- **Nova Gramática do Português Contemporâneo** — Celso Cunha & Lindley Cintra.
- **Moderna Gramática Portuguesa** — Evanildo Bechara.

### Erros mais comuns que revisores profissionais checam

- **Concordância verbal**: "fazem dois anos" (errado — "faz" é impessoal); "houveram problemas" (errado — "houve").
- **Concordância nominal**: "a medida foi criticados" (gênero/número), adjetivo após substantivos heterogêneos.
- **Regência verbal**: "assistir o filme" (correto: "assistir ao filme"); "implicar em" (correto: "implicar algo"); "visar a"; "preferir A a B" (não "do que B").
- **Crase**: "à medida que" vs "na medida em que"; crase antes de nome próprio feminino; "às vezes" sempre com crase.
- **"Ao invés de" vs "em vez de"**: o primeiro só para oposição literal; em copy, quase sempre é "em vez de".
- **Pronomes oblíquos**: "para mim fazer" (errado — "para eu fazer"); colocação de "se" e "lhe".
- **Acordo 2009**: queda do trema, hífen ("autoescola", não "auto-escola"), acentos perdidos ("ideia", "voo", "leem").
- **Mas/Mais**: confusão recorrente em copy informal.
- **A/Há**: "há dois anos" (passado, tempo) vs "a duas quadras" (distância/futuro).
- **Onde/aonde**: "aonde" exige movimento (verbo de direção).

### Checklist NADIA — gramática PT-BR

- [ ] **Rodar LanguageTool API** com `language=pt-BR` em todo o texto antes de revisão humana.
- [ ] **Buscar padrões de alto risco**: regex de `(faz|fazem) \d+ ano`, `houveram?`, `assistir o`, `ao invés de`, `para mim [verbo]`, `(à|a) medida`.
- [ ] **Validar crase em todo "à/às"**: se substituível por "para a/o" mantém sentido = ok; se "para" basta, não tem crase.
- [ ] **Verificar Acordo Ortográfico 2009**: nenhum trema, hífen conforme regra, sem acento em "ideia/joia/heroico".
- [ ] **Concordância em listas**: quando um adjetivo segue lista de substantivos de gêneros diferentes, conferir norma (Folha: masc. plural ou próximo).
- [ ] **Marca/produto estrangeiro**: validar grafia oficial e itálico se for o padrão do cliente.
- [ ] **Cross-check com Houaiss** quando termo for raro ou técnico (não confiar só em corretor).

### Ferramentas/APIs

- **LanguageTool** (`api.languagetool.org`) — suporta `pt-BR`, `pt-PT`, `pt-AO`, `pt-MZ`. Open source, self-hostable.
- **Microsoft Editor API** (parte do Microsoft 365) — bom para PT-BR, requer licença.
- **VOLP — Vocabulário Ortográfico da Língua Portuguesa** (Academia Brasileira de Letras, online) — referência oficial para grafia.
- **Dicio / Houaiss online** — consulta lexical.
- Evitar: corretores de SaaS recém-lançados sem track record em PT.

---

## 3. Revisão Conceitual / Lógica

### Frameworks validados

- **Pyramid Principle — Barbara Minto** (McKinsey, "The Minto Pyramid Principle", 1987): conclusão primeiro, depois 3 argumentos de sustentação, depois evidências. Top-down.
- **MECE — Barbara Minto** (McKinsey, anos 1960): Mutually Exclusive, Collectively Exhaustive. Argumentos não se sobrepõem e cobrem o universo.
- **Six Thinking Hats — Edward de Bono** (1985): 6 perspectivas obrigatórias (factos, emoção, crítica, otimismo, criatividade, processo).
- **SCQA — Barbara Minto**: Situation, Complication, Question, Answer — abertura para qualquer documento estruturado.
- **Toulmin Model** (Stephen Toulmin, "The Uses of Argument", 1958): Claim, Grounds, Warrant, Backing, Qualifier, Rebuttal.

### Falácias mais comuns em texto persuasivo

| Falácia | Como aparece em copy |
|---|---|
| **Slippery slope** | "Se não comprar agora, vai perder o cliente, depois o time, depois o negócio" |
| **Ad hominem** | Atacar concorrente em vez de comparar produto |
| **Straw man** | Distorcer objeção do prospect para refutar versão fácil |
| **False dichotomy** | "Ou você usa nosso método ou continua estagnado" |
| **Appeal to authority** | Citar "expert" sem credencial real ou fora do domínio |
| **Bandwagon (ad populum)** | "Todo mundo está fazendo isso" sem dado |
| **Post hoc** | "Cliente X cresceu 300% depois de nos contratar" sem isolar variável |
| **Hasty generalization** | 1 case → afirmação universal |
| **Begging the question** | Conclusão embutida na premissa |
| **Cherry picking** | Mostrar só métricas favoráveis |

Fontes: *Internet Encyclopedia of Philosophy*, UNC Writing Center, Toulmin (1958), Walton — "Informal Logic" (1989).

### Checklist NADIA — lógica

- [ ] **Teste do "Porque": ladder de 3 níveis**: pegue a tese principal, pergunte "por quê?" 3 vezes. Se em algum nível a resposta é vazia, premissa está faltando.
- [ ] **MECE check**: listar todos os argumentos. Há sobreposição? Há um caso óbvio que ficou fora? Reprovar até cobrir.
- [ ] **Pyramid check**: a primeira linha do bloco contém a conclusão? Se o leitor parar ali, levou a mensagem? Se não, reordenar top-down.
- [ ] **Caçada de falácias**: passar a lista acima e marcar cada ocorrência. Slippery slope e false dichotomy são as mais frequentes em copy emocional.
- [ ] **Premissa não declarada (warrant Toulmin)**: para cada claim, escrever em uma frase a premissa implícita. Se ela é frágil ou polêmica, exigir explicitação ou prova.
- [ ] **Teste de contradição interna**: pegar 2 afirmações distantes no texto e verificar compatibilidade. Em propostas comerciais é onde aparece (escopo vs prazo vs preço).
- [ ] **Six Hats em análise BMAD de Instagram**: forçar passagem pelos 6 chapéus — não aprovar análise que só usou o chapéu otimista (verde/amarelo).
- [ ] **Prova check**: cada número precisa de fonte; cada case precisa de cliente identificável ou anonimato declarado; cada citação precisa de autor + ano.

---

## 4. Revisão Visual de Imagens

### Princípios validados

- **Gestalt** (Wertheimer, Köhler, Koffka — anos 1920): proximidade, similaridade, fechamento, continuidade, figura/fundo, destino comum.
- **WCAG 2.2** (W3C, 2023): SC 1.4.3 — contraste mínimo 4.5:1 para texto normal, 3:1 para texto grande (≥18pt ou 14pt bold) e para componentes/gráficos (SC 1.4.11). Alt text obrigatório (SC 1.1.1).
- **Rule of thirds, leading lines, focal hierarchy**: cânone fotográfico clássico (Bruce Block — "The Visual Story", 2001).
- **Brand consistency**: paleta, tipografia, tom — definidos em design system / brand guidelines do cliente.

### Erros típicos em imagens geradas por IA (GensGPT 2026, Britannica)

- **Mãos**: 6+ dedos, dedos fundidos, palma com dedos saindo do lugar errado, polegar invertido, mão flutuando sem pulso.
- **Olhos**: pupilas assimétricas, reflexos inconsistentes entre os dois olhos, íris com cores diferentes não intencionais, olhar divergente.
- **Dentes**: número errado, fileiras duplicadas, dentes fundidos, gengiva implausível.
- **Orelhas**: assimétricas, brincos só de um lado, hélice malformada.
- **Texto/logos**: letras ilegíveis, ortografia inventada, logo distorcido, marca real renderizada errada (risco jurídico).
- **Perspectiva**: linhas de fuga inconsistentes, objetos no mesmo plano com escalas diferentes.
- **Iluminação**: sombras vindo de direções incompatíveis na mesma cena; reflexos em espelho/vidro que não batem com o objeto refletido.
- **Joias/relógios**: ponteiros impossíveis, números fora de ordem.
- **Cabelo**: fios fundindo com fundo, mechas saindo de lugar anatomicamente errado.
- **Anatomia geral**: pescoço longo demais, ombros assimétricos, membros extras parcialmente ocultos por roupa, articulações invertidas.
- **Fundo**: pessoas/objetos derretendo, repetições padronizadas (wallpaper), texto em placas/sinais ininteligível.

### Checklist NADIA — imagem

- [ ] **Zoom 200% em mãos** (sempre): contar dedos, validar pulso conectado, polegar do lado correto.
- [ ] **Zoom em olhos**: simetria de pupila, reflexos batem (mesma fonte de luz dos dois olhos), íris coerente.
- [ ] **Boca aberta? Conferir dentes** um a um.
- [ ] **Tem texto na imagem?** Ler todas as palavras. Se ilegível ou com erro, reprovar.
- [ ] **Tem logo real?** Validar grafia, proporção, cores oficiais. Risco de marca registrada.
- [ ] **Sombra check**: identificar fonte de luz. Todas as sombras vêm do mesmo ângulo? Comprimento coerente?
- [ ] **Reflexo check**: superfícies espelhadas refletem o que está na cena? (erro clássico de IA)
- [ ] **Contraste WCAG**: rodar contrast checker (WebAIM) em qualquer texto sobre imagem. ≥4.5:1 texto normal, ≥3:1 texto grande.
- [ ] **Brand check**: paleta dentro da brand guideline (Hex match), tipografia da marca, tom visual coerente com peças anteriores.
- [ ] **Rule of thirds / hierarquia**: identificar o foco. Está no terço? Há leading lines para ele? Se foco compete com 3 elementos iguais, reprovar.
- [ ] **Alt text**: gerar descrição funcional para acessibilidade — descreve a função/conteúdo, não estilo.
- [ ] **AI detection sanity**: se a imagem precisa parecer "real" (testemunho, case), rodar detector (ex: Hive AI Detector, Sightengine) — risco reputacional alto.

### Ferramentas

- **WebAIM Contrast Checker** — `webaim.org/resources/contrastchecker`
- **Stark / axe DevTools** — auditoria WCAG.
- **Adobe Color** / **Coolors** — validar paleta.
- **Hive AI / Sightengine / Illuminarty** — detecção de imagem IA.

---

## 5. Diagramação / Layout

### Princípios validados

- **C.R.A.P. — Robin Williams, "The Non-Designer's Design Book" (1994, 4ª ed. 2015)**: Contrast, Repetition, Alignment, Proximity.
- **8-point grid** (padrão Material Design Google, Apple HIG): todos os spacings em múltiplos de 8px (8, 16, 24, 32, 48, 64). Variação 4px para densidade alta.
- **12-column grid** (Bootstrap, padrão web): divide em 1/2, 1/3, 1/4, 1/6 — flexibilidade máxima.
- **Modular scale** (Robert Bringhurst — "The Elements of Typographic Style", 1992): escala tipográfica baseada em ratio (1.125, 1.25, 1.333, 1.5, 1.618 áureo).
- **Atomic Design — Brad Frost** (atomicdesign.bradfrost.com, 2013/2016): Tokens → Atoms → Molecules → Organisms → Templates → Pages.
- **Design Tokens** (W3C Design Tokens Community Group): cor, tipografia, espaçamento, sombra como variáveis nomeadas.
- **Vertical rhythm / baseline grid** — Josef Müller-Brockmann, "Grid Systems in Graphic Design" (1981).

### Checklist NADIA — layout

- [ ] **CRAP scan** (na ordem):
  1. **Proximidade**: elementos relacionados estão agrupados (gap pequeno) e separados de não-relacionados (gap maior)? Regra prática: gap interno < gap externo.
  2. **Alinhamento**: todo elemento se alinha a outro. Nada flutuando "quase no meio". Eixo dominante claro (esquerda OU centro, não os dois).
  3. **Repetição**: cores, fontes, ícones, botões — mesmo padrão se repete. Se há 3 estilos de botão, reprovar.
  4. **Contraste**: hierarquia óbvia em 1 segundo. Título ≠ corpo ≠ legenda em peso/tamanho/cor.
- [ ] **Grid check**: todos os spacings são múltiplos de 8 (ou 4)? Medir gaps com régua. Valores aleatórios (13px, 27px) = reprovar.
- [ ] **Hierarquia tipográfica**: no máximo 3 níveis de tamanho em uma peça. Escala segue ratio (ex: 16/20/32, não 16/18/19).
- [ ] **Leading (entrelinha)**: corpo de texto entre 1.4× e 1.6× o font-size. Títulos 1.1×–1.2×.
- [ ] **Largura de linha**: 45–75 caracteres para corpo (Bringhurst). Mais que isso, cansa; menos, fragmenta.
- [ ] **White space**: nenhum bloco "encostado" na borda. Margem mínima = 2× o gap interno do bloco.
- [ ] **Visual rhythm**: scan vertical da peça. Há sequência previsível de elementos ou está aleatório?
- [ ] **Token compliance**: cores usadas pertencem à paleta tokenizada do cliente? Fontes pertencem ao stack definido?
- [ ] **Responsividade** (digital): a 320px ainda funciona? Texto não estoura, CTAs continuam tocáveis (≥44×44px, Apple HIG).
- [ ] **Hierarquia de CTA**: 1 ação primária por tela. Botões secundários menores/menos contrastados.

### Ferramentas

- **Figma** + plugin **Design Lint** / **Tokens Studio**.
- **Spec / Zeplin** — checagem de spacing.
- **Stark** — auditoria contraste e WCAG em design.
- **Modular Scale calculator** — `modularscale.com`.

---

## Ordem de execução recomendada (NADIA)

1. **Gramatical** (LanguageTool API — rápido, mecânico).
2. **Textual** (clareza/cortes — onde mais agrega valor).
3. **Conceitual** (lógica/MECE/falácias — onde texto pode passar gramática e ainda estar errado).
4. **Visual** (se houver imagem — anatomia IA primeiro, sempre).
5. **Layout** (CRAP + grid — último porque depende dos elementos finais).

Reprovar logo na primeira falha bloqueante. Não acumular feedback de 5 áreas se a primeira já invalida a entrega — eficiência de token.

---

## Fontes principais

- Orwell, G. (1946). *Politics and the English Language*.
- Strunk & White (1959). *The Elements of Style*.
- Ogilvy, D. (1983). *Ogilvy on Advertising*.
- Minto, B. (1987). *The Minto Pyramid Principle*.
- Toulmin, S. (1958). *The Uses of Argument*.
- de Bono, E. (1985). *Six Thinking Hats*.
- Williams, R. (1994/2015). *The Non-Designer's Design Book*.
- Bringhurst, R. (1992). *The Elements of Typographic Style*.
- Müller-Brockmann, J. (1981). *Grid Systems in Graphic Design*.
- Frost, B. (2016). *Atomic Design*. atomicdesign.bradfrost.com.
- Folha de S.Paulo. *Manual da Redação* (ed. revista 2018; atualização IA 2024).
- Houaiss, A. *Dicionário Houaiss da Língua Portuguesa* (2009).
- Cunha & Cintra. *Nova Gramática do Português Contemporâneo*.
- Acordo Ortográfico da Língua Portuguesa (1990, vigência BR desde 2016).
- Fernández-Huerta, J. (1959). Fórmula de legibilidade para espanhol.
- W3C (2023). *WCAG 2.2*.
- Internet Encyclopedia of Philosophy — *Fallacies*. iep.utm.edu/fallacy.
- LanguageTool — `languagetool.org/http-api`.
- WebAIM Contrast Checker — `webaim.org/resources/contrastchecker`.
- GensGPT (2026). *AI Hands, Anatomy & Body Fixes Guide*.
