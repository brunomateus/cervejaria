---
name: novo-post
description: Generate a new "Brassagem" blog post from a BrewFather recipe JSON export, photos, and short notes staged in assets/img/_incoming/. Use when the user wants to draft a new brewing post, mentions a BrewFather export, or asks to run "/novo-post".
---

# Novo Post

Turns a BrewFather recipe export + photos + short notes into a ready-to-review post in `_posts/`, following this blog's established "Brassagem" template. **Stops after writing the file — never runs `git add`/`commit`.**

## Precondition

Everything needed lives in `assets/img/_incoming/` (gitignored staging, cleared at the end of a successful run):

- one `Brewfather_RECIPE_*.json` export
- photos/videos, already named meaningfully (e.g. `fervura.jpg`, `mostura.jpg`, `rotulo.png`, `no-copo.jpg`)
- `notas.md` — short bullet notes about brew day, used to draft the narrative (see [notas.example.md](notas.example.md) for the expected shape and level of detail)

If any of these is missing, say what to drop in `_incoming/` and stop — don't guess at missing inputs.

## Process

1. **Ask the brew date.** It's not always the day the skill is run.

2. **Next batch number**: `python3 .agents/skills/novo-post/next_batch_number.py` → prints `<ROMAN> <int>` (e.g. `XXVII 27`), derived from existing `_posts` titles.

3. **Extract the recipe**: `python3 .agents/skills/novo-post/extract_recipe.py <path-to-json>` → `{"meta": ..., "tables": ...}`. Read this instead of the raw JSON — it's already formatted to this blog's table style and saves you from parsing a ~40KB export by hand. `tables.mash` / `tables.fermentation` step names come straight from BrewFather (generic English) — localize them to this blog's phrasing while assembling the post (e.g. "Diacetil rest" → "Descanso do diacetil", a bare "Cold"/"Cold 1" → "Cold Crash"), keeping the temp/duration values as extracted.

4. **BJCP quote**: if `meta.style.is_bjcp_2021` is true, fetch `meta.style.guessed_bjcp_url` (`WebFetch`) and pull the "Impressão Geral" section — same text pattern already quoted in existing posts after "De acordo com o [BJCP de 2021](https://bjcp-brasil.github.io/bjcp-2021-pt-br/), temos que uma *Estilo* deve ser:". Show it to the user to **accept / edit / skip** — the URL is a good guess from the recipe's category/style fields, not a guarantee (site restructures, unusual style names). If `is_bjcp_2021` is false, or the fetch/extraction fails, ask the user directly instead: offer the guessed link if there is one, and let them paste a corrected link, dictate the quote themselves, or skip the paragraph.

5. **Curso / confraria** — ask, multi-select: *Nenhum / PFC / Confraria Bingo / Outro*.
   - **PFC**: add tag `pfc`; intro mentions it's beer N of the course — match the phrasing already used (`grep -l pfc _posts/*.md` for real examples).
   - **Confraria Bingo**: add tag `bingo`; if `notas.md` doesn't already say which styles were defined for this round, ask. Intro sentence along the lines of: *"cerveja brassada para o Bingo, o estilo foi escolhido pelo FULANO."*
   - **Outro**: ask for a short label; slugify it for the tag; ask for one sentence to fold into the intro.

6. **Draft the narrative** from `notas.md` into the section skeleton below. Match the voice of existing posts — first person, informal, PT-BR; skim one or two recent `_posts/*.md` first if unsure of tone.

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

   Matched files: place with the default caption (still just a draft — user reviews everything at the end). Unmatched files: ask which section (offer the skeleton's section list) and what caption.

8. **Assemble `_posts/<date>-<slug>.md`.**
   - Slug: `meta.name_slug` from the extractor, unless the recipe name is messy/generic — then pick something readable, matching how existing slugs read (`tripel`, `session-ipa`, `barleywine`).
   - Frontmatter:
     ```yaml
     title: Brassagem <ROMAN> - <Nome>
     date: <brew date>
     categories: [Blogging, Brassagem]
     tags: [receita, <style-or-name-slug>, <course tags...>]
     ```
   - Body sections, in order (this matches every post since 2024 — skip "Parti-gyle" unless `notas.md` mentions a second brew off the same mash):
     1. `### 🍺 A cerveja - <Nome>` — rótulo image, intro paragraph, BJCP blockquote (or nothing if skipped).
     2. `### 🌾 Fermentáveis` — `tables.fermentables` + `tables.fermentables_total`.
     3. `### 🔥 Perfil de mostura` — `tables.mash` + a sentence on the mash approach, from `notas.md`.
     4. `### 🌿 Lupulagem (boil steps / adições) e 🫚 Especiarias` — `tables.hops_and_spices` + notes.
     5. `### 🌡️ Perfil de fermentação` — `tables.fermentation`.
     6. `### 🧬 Levedura` — `tables.yeast`.
     7. `### ⚖️ Comparativo: Estimado (receita) × Medido (lote)` — `tables.comparativo_estimado`; leave the "Medido" column as `—` (no batch data exists yet).
     8. `### 📝 Notas de produção`, with `####` subsections drafted from `notas.md` (typically Mostura, Lavagem, Fervura, Fermentação), each carrying its matched photo(s).
     9. `### 🍺 A cerveja no copo` — "Em breve trago atualizações." unless `notas.md`/a `no-copo` photo says otherwise.
     10. `### Pontos a melhorar` — checklist drafted from anything in `notas.md` flagged as a lesson learned; just the empty heading if nothing applies.
   - Every image/video `src` stays a **literal root-relative path** — `/assets/img/brassagem-<ROMAN>/<filename>`. Never add a `/cervejaria` prefix, never wrap it in `relative_url` — `_plugins/baseurl-asset-fix.rb` rewrites it automatically at build time, locally and in production.

9. **Move files.** Create `assets/img/brassagem-<ROMAN>/`, copy every photo/video from `_incoming/` there under its exact original filename.

10. **Clean up `_incoming/`.** Only after the post file and every image have been written successfully: delete the JSON, the photos/videos, and `notas.md` from `_incoming/`.

11. **Stop and report.** Point the user at `_posts/<file>`. Flag what needs a second look: the BJCP quote if auto-fetched, any photo placed by a guessed section/caption, the always-empty "Medido" column, and the localized mash/fermentation step labels. Do not stage or commit anything.
