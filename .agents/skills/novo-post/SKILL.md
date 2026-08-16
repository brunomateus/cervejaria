---
name: novo-post
description: Generate a new "Brassagem" blog post from a BrewFather recipe JSON export, photos, and short notes staged in assets/img/_incoming/ — or finish a post left pending fermentation results with a later drop of notes/photos in the same folder. Use when the user wants to draft a new brewing post, finalize/complete a pending brassagem post, mentions a BrewFather export, or asks to run "/novo-post".
---

# Novo Post

Turns a BrewFather recipe export + photos + short notes into a ready-to-review post in `_posts/`, following this blog's established "Brassagem" template. Also handles the common follow-up: fermentation finishes weeks later, and the post gets its final numbers, tasting notes, and glass photos added then. **Stops after writing/editing the file — never runs `git add`/`commit`.**

## Mode detection

Everything needed lives in `assets/_incoming/` (gitignored staging, cleared at the end of a successful run). What's staged there decides the mode:

- **JSON export present** → *novo post* mode (below): a fresh Brassagem post from scratch.
- **No JSON export** (only `notas.md` and/or photos/videos) → *finalizar* mode (below): completing a post that's still waiting on fermentation results.

If `_incoming/` is empty or has neither a JSON nor `notas.md`/photos, say what to drop there and stop — don't guess at missing inputs.

## Process — novo post

1. **Confirm the brew date.** It's not always the day the skill is run. A BATCH export already carries it as `meta.brew_date` (step 3) — offer that as the default instead of asking cold. Only a RECIPE export leaves it unknown, and then you do have to ask.

2. **Next batch number**: `python3 .agents/skills/novo-post/next_batch_number.py` → prints `<ROMAN> <int>` (e.g. `XXVII 27`), derived from existing `_posts` titles.

3. **Extract the recipe**: `python3 .agents/skills/novo-post/extract_recipe.py <path-to-json>` → `{"meta": ..., "tables": ...}`. Both BrewFather export shapes work — `Brewfather_RECIPE_*.json` (recipe at the top level) and `Brewfather_BATCH_*.json` (recipe nested under `.recipe`, which is the usual export here). `meta.source` says which one it read. The tables always describe the **recipe as planned**, identical either way; a BATCH export additionally fills `meta.brew_date` (step 1) and `meta.measured` (step 8.7). If it warns on stderr that no fermentables were found, stop — the export isn't one of the two shapes, and every table will be empty. Read this instead of the raw JSON — it's already formatted to this blog's table style and saves you from parsing a ~40KB export by hand. `tables.mash` / `tables.fermentation` step names come straight from BrewFather (generic English) — localize them to this blog's phrasing while assembling the post (e.g. "Diacetil rest" → "Descanso do diacetil", a bare "Cold"/"Cold 1" → "Cold Crash"), keeping the temp/duration values as extracted.

4. **BJCP quote**: if `meta.style.is_bjcp_2021` is true, fetch `meta.style.guessed_bjcp_url` (`WebFetch`) and pull the "Impressão Geral" section — same text pattern already quoted in existing posts after "De acordo com o [BJCP de 2021](https://bjcp-brasil.github.io/bjcp-2021-pt-br/), temos que uma *Estilo* deve ser:". Show it to the user to **accept / edit / skip** — the URL is a good guess from the recipe's category/style fields, not a guarantee (site restructures, unusual style names). If `is_bjcp_2021` is false, or the fetch/extraction fails, ask the user directly instead: offer the guessed link if there is one, and let them paste a corrected link, dictate the quote themselves, or skip the paragraph.

5. **Curso / confraria** — ask, multi-select: *Nenhum / PFC / Confraria Bingo / Outro*.
   - **PFC**: add tag `pfc`; intro mentions it's beer N of the course — match the phrasing already used (`grep -l pfc _posts/*.md` for real examples).
   - **Confraria Bingo**: add tag `bingo`; if `notas.md` doesn't already say which styles were defined for this round, ask. Intro sentence along the lines of: *"cerveja brassada para o Bingo, o estilo foi escolhido pelo FULANO."*
   - **Outro**: ask for a short label; slugify it for the tag; ask for one sentence to fold into the intro.

6. **Draft the narrative** from `notas.md` into the section skeleton below. Match the voice of existing posts — first person, informal, PT-BR; skim one or two recent `_posts/*.md` first if unsure of tone. If `notas.md`'s `Fermentação` section is still open-ended (final gravity/attenuation not known yet — normal, fermentation isn't done), draft it as what's known so far (inoculation temp, early behavior); the *finalizar* flow below rewrites this paragraph once the outcome is known, so don't invent an ending.

7. **Place the photos.** List every file in `_incoming/` other than the JSON and `notas.md`. Match each filename (ignore extension and numeric suffixes) against this vocabulary:

   | filename contains | goes in | default caption |
   |---|---|---|
   | `rotulo` | header image (not a `<figure>` — the `<img style="width: 50%; margin: auto">` used today) | "Rótulo da \<Nome\>" |
   | `mostura` | Notas de produção → Mostura | "Foto do início da mostura" |
   | `fervura` | Notas de produção → Fervura | "Foto durante a fervura" |
   | `whirlpool` / `whirpool` | Notas de produção → Fervura | "Adição de lúpulo no whirlpool" |
   | `fermentacao` / `fermentação` (image) | Notas de produção → Fermentação | "Gráfico da fermentação" |
   | `.mp4` / `.mov` | same section as the closest matching still, else Notas de produção | (ask) |
   | `no-copo` / `no_copo` | A cerveja no copo | "Foto da cerveja no copo" |
   | anything else | — | — |

   Matched files: place with the default caption (still just a draft — user reviews everything at the end). Unmatched files: ask which section (offer the skeleton's section list) and what caption. (This same vocabulary is reused as-is by the *finalizar* flow for photos that arrive later.)

8. **Assemble `_posts/<date>-<slug>.md`.**
   - Slug: `meta.name_slug` from the extractor, unless the recipe name is messy/generic — then pick something readable, matching how existing slugs read (`tripel`, `session-ipa`, `barleywine`).
   - Frontmatter:
     ```yaml
     title: Brassagem <ROMAN> - <Nome>
     date: <brew date>
     categories: [Blogging, Brassagem]
     tags: [receita, <style-or-name-slug>, <course tags...>]
     fermentacao_pendente: true
     ```
     `fermentacao_pendente: true` marks this post as awaiting a later *finalizar* run once fermentation is done. It's internal bookkeeping only — never rendered, and the *finalizar* flow removes it on completion.
   - Body sections, in order (this matches every post since 2024 — skip "Parti-gyle" unless `notas.md` mentions a second brew off the same mash):
     1. `### 🍺 A cerveja - <Nome>` — rótulo image, intro paragraph, BJCP blockquote (or nothing if skipped).
     2. `### 🌾 Fermentáveis` — `tables.fermentables` + `tables.fermentables_total`.
     3. `### 🔥 Perfil de mostura` — `tables.mash` + a sentence on the mash approach, from `notas.md`.
     4. `### 🌿 Lupulagem (boil steps / adições) e 🫚 Especiarias` — `tables.hops_and_spices` + notes.
     5. `### 🌡️ Perfil de fermentação` — `tables.fermentation`. This is BrewFather's *planned* schedule — it's never edited later, even if the actual fermentation deviated; deviations belong in the "Notas de produção → Fermentação" prose instead.
     6. `### 🧬 Levedura` — `tables.yeast`.
     7. `### ⚖️ Comparativo: Estimado (receita) × Medido (lote)` — `tables.comparativo_estimado`. Leave FG/ABV/IBU/EBC "Medido" as `—` (they need fermentation to finish). **OG is the exception**: it's known same brew day, so fill it in now instead of leaving it `—` — from `notas.md` (e.g. "OG medida no fim: 1.048"), or from `meta.measured.og` on a BATCH export. If both exist and disagree, `notas.md` wins (it's what you actually wrote down) — say so in the report. `meta.measured` also carries `mash_ph`, `pre_boil_gravity`, `post_boil_gravity` and `boil_size_l`, which belong in the "Notas de produção" prose, not in this table. It deliberately omits BrewFather's `measuredAbv`/`measuredAttenuation`: mid-fermentation those are projections, not measurements, so never publish them as "Medido".
     8. `### 📝 Notas de produção`, with `####` subsections drafted from `notas.md` (typically Mostura, Lavagem, Fervura, Fermentação), each carrying its matched photo(s).
     9. `### 🍺 A cerveja no copo` — "Em breve trago atualizações." unless `notas.md`/a `no-copo` photo says otherwise.
     10. `### Pontos a melhorar` — checklist drafted from anything in `notas.md` flagged as a lesson learned; just the empty heading if nothing applies.
   - Every image/video `src` stays a **literal path with no baseurl** — either `/assets/img/brassagem-<ROMAN>/<filename>` or `../assets/img/brassagem-<ROMAN>/<filename>` (the relative form is what the VS Code preview resolves inside raw HTML `<img>` tags; prefer it). Never add a `/cervejaria` prefix, never wrap it in `relative_url` — `_plugins/baseurl-asset-fix.rb` normalizes both forms and applies the baseurl at build time, locally and in production.

9. **Move files.** Create `assets/img/brassagem-<ROMAN>/`, copy every photo/video from `_incoming/` there under its exact original filename. Then run `./tools/otimizar-imagens.sh` to generate the web-sized variants under `assets/img/brassagem-<ROMAN>/web/` — the originals stay in the repo as backup, and `_plugins/web-image-variants.rb` publishes the variants in their place. Both the originals and the variants get committed; never reference a `web/` path from the post itself.

10. **Clean up `_incoming/`.** Only after the post file and every image have been written successfully: delete the JSON, the photos/videos, and `notas.md` from `_incoming/`.

11. **Stop and report.** Point the user at `_posts/<file>`. Flag what needs a second look: the BJCP quote if auto-fetched, any photo placed by a guessed section/caption, the (mostly) empty "Medido" column, and the localized mash/fermentation step labels. Mention that the post carries `fermentacao_pendente: true` and will be picked up automatically by a later `/novo-post` run once fermentation notes/photos are dropped in `_incoming/`. Do not stage or commit anything.

## Process — finalizar

Triggers when `_incoming/` has no JSON export — only `notas.md` (reusing the same file/section shape as above, now with `Fermentação` and `Pontos a melhorar` filled in, plus a new `## A cerveja no copo` section for tasting impressions) and/or photos (most often `no-copo`/`no_copo`).

1. **Find the target post.**
   - `grep -l 'fermentacao_pendente: true' _posts/*.md`
   - One match → that's the post.
   - Several matches → list their titles/dates and ask which one this drop belongs to.
   - No match → nothing is currently pending (its flag was already cleared by an earlier finalizar run, e.g. text was finished before these photos arrived) — ask the user directly which existing post (title, date, or ROMAN numeral) this content belongs to.

2. **Read the target post in full** before editing — this is a revision of existing prose, not a fresh draft.

3. **If `notas.md` is present**, update the post:
   - `### 📝 Notas de produção → Fermentação`: rewrite the paragraph, merging the phase-1 draft (what was known at brew time) with the outcome from `notas.md` (final gravity, attenuation, timeline, anything notable) into one coherent paragraph — don't just append a second one.
   - `### Pontos a melhorar`: append any new items from `notas.md`'s `Pontos a melhorar` section below whatever's already there; leave existing items untouched.
   - `### 🍺 A cerveja no copo`: replace "Em breve trago atualizações." with the text drafted from `notas.md`'s `## A cerveja no copo` section.
   - `### ⚖️ Comparativo: Estimado × Medido`: fill FG from `notas.md`. Compute ABV as `(OG − FG) × 131.25` from the OG already in the table and the new FG. Fill IBU/EBC only if `notas.md` states a measured value; otherwise they stay `—` — these normally aren't lab-measured by a homebrewer, so don't invent a number.

4. **Place any photos/videos** using the same filename vocabulary as step 7 of the *novo post* flow — copy into the post's existing `assets/img/brassagem-<ROMAN>/` folder (create it only if it's somehow missing) and reference from the matching section. Run `./tools/otimizar-imagens.sh` afterwards, as in step 9 of the *novo post* flow.

5. **Clear the flag.** Remove `fermentacao_pendente: true` from the post's frontmatter entirely — this run closes out the pending work. (If a later drop only ever brings photos with no text left to change, this is still the run that removes the flag, the first time notas.md content is fully resolved.)

6. **Clean up `_incoming/`.** Only after the post file and every image have been written successfully: delete whatever was staged (`notas.md`, photos/videos).

7. **Stop and report.** Point the user at the updated `_posts/<file>`. Flag anything guessed: the computed ABV, any photo placed by a guessed section/caption. Do not stage or commit anything.
