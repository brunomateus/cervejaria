#!/usr/bin/env python3
"""Distill a BrewFather recipe JSON export into the data + markdown table
snippets used by the blog's post template. Run standalone:

    python3 extract_recipe.py path/to/Brewfather_RECIPE_*.json

Prints a single JSON object to stdout: {"meta": {...}, "tables": {...}}.
The `novo-post` skill reads this instead of the raw BrewFather export so a
lot less gets fed into the model.
"""
import json
import re
import sys
import unicodedata


def slugify(text):
    if not text:
        return ""
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    text = re.sub(r"[^a-zA-Z0-9]+", "-", text).strip("-").lower()
    return text


def fmt_kg(amount):
    return f"{amount:.2f}".rstrip("0").rstrip(".").replace(".", ",") + " kg"


def fmt_amount(amount, unit):
    if amount is None:
        return "—"
    if float(amount).is_integer():
        return f"{int(amount)} {unit}"
    return f"{amount:.2f}".rstrip("0").rstrip(".").replace(".", ",") + f" {unit}"


def fmt_pct(pct):
    if pct is None:
        return "—"
    return f"{pct:.2f}".replace(".", ",") + "%"


def fmt_temp(temp):
    if temp is None:
        return "—"
    return f"{temp:g} °C".replace(".", ",")


def fmt_duration(minutes, unit="min"):
    if minutes in (None, 0) and unit == "min":
        return "0 min"
    if minutes is None:
        return "—"
    if float(minutes).is_integer():
        return f"{int(minutes)} {unit}"
    return f"{minutes:g} {unit}".replace(".", ",")


def markdown_table(headers, aligns, rows):
    def sep(a):
        return {"l": "---", "r": "---:", "c": ":---:"}[a]

    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join(sep(a) for a in aligns) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(row) + " |")
    return "\n".join(lines)


def build_fermentables(data):
    fermentables = data.get("fermentables", [])
    total = sum(f.get("amount", 0) for f in fermentables)
    rows = [
        [
            f["name"],
            fmt_kg(f.get("amount", 0)),
            fmt_pct(f.get("percentage")),
        ]
        for f in fermentables
    ]
    table = markdown_table(
        ["Nome", "Quantidade", "% na receita"], ["l", "r", "r"], rows
    )
    total_str = f"{total:.2f}".rstrip("0").rstrip(".").replace(".", ",")
    return table, f"Total de grãos/extratos: **{total_str} kg**"


def build_mash(data):
    steps = data.get("mash", {}).get("steps", [])
    rows = [
        [
            s.get("name", s.get("type", "Etapa")),
            fmt_temp(s.get("displayStepTemp", s.get("stepTemp"))),
            fmt_duration(s.get("stepTime")),
        ]
        for s in steps
    ]
    return markdown_table(
        ["Etapa / Nome da mostura", "Temperatura", "Duração"], ["l", "r", "r"], rows
    )


BOIL_MISC_USES = {"Boil", "Aroma", "Whirlpool", "First Wort"}


def build_hops_and_spices(data):
    rows = []
    for h in data.get("hops", []):
        alpha = h.get("alpha")
        alpha_str = f" ({alpha:g}% AA)".replace(".", ",") if alpha else ""
        time_unit = "dias" if h.get("timeIsDays") else "min"
        rows.append(
            (
                h.get("time") if h.get("time") is not None else -1,
                [
                    f"{h['name']}{alpha_str}",
                    fmt_amount(h.get("amount"), h.get("unit", "g") or "g"),
                    fmt_duration(h.get("time"), time_unit),
                ],
            )
        )
    for m in data.get("miscs", []):
        if m.get("use") not in BOIL_MISC_USES:
            continue
        time_unit = "dias" if m.get("timeIsDays") else "min"
        rows.append(
            (
                m.get("time") if m.get("time") is not None else -1,
                [
                    m["name"],
                    fmt_amount(m.get("amount"), m.get("unit", "g") or "g"),
                    fmt_duration(m.get("time"), time_unit),
                ],
            )
        )
    rows.sort(key=lambda r: r[0], reverse=True)
    return markdown_table(
        ["Nome", "Quantidade", "Tempo de adição"],
        ["l", "l", "l"],
        [r[1] for r in rows],
    )


def build_fermentation(data):
    steps = data.get("fermentation", {}).get("steps", [])
    rows = [
        [
            s.get("name", s.get("type", "Etapa")),
            fmt_temp(s.get("displayStepTemp", s.get("stepTemp"))),
            fmt_duration(s.get("stepTime"), "dias") if s.get("stepTime") else "—",
        ]
        for s in steps
    ]
    return markdown_table(["Etapa", "Temperatura", "Duração"], ["l", "l", "l"], rows)


def build_yeast(data):
    yeasts = data.get("yeasts", [])
    if not yeasts:
        return "", {}
    y = yeasts[0]
    lines = [
        f"* **Nome:** {y.get('name', '—')}.",
        f"* **Laboratório:** {y.get('laboratory', '—')}",
        f"* **Quantidade usada no lote:** {fmt_amount(y.get('amount'), y.get('unit', 'pkg'))} "
        "(revisar/completar com detalhes do starter, se houver).",
    ]
    min_att, max_att = y.get("minAttenuation"), y.get("maxAttenuation")
    if min_att or max_att:
        lines.append(f"* **Attenuation (informada):** ~{min_att}-{max_att}%")
    min_t, max_t = y.get("minTemp"), y.get("maxTemp")
    if min_t or max_t:
        lines.append(f"* **Temperatura mínima/máxima indicada:** ~{min_t}–{max_t} °C.")
    return "\n".join(lines), y


def build_estimado(data):
    def og_fg(v):
        return f"{v:.3f}" if v is not None else "—"

    return markdown_table(
        ["Parâmetro", "Estimado", "Medido"],
        ["l", "l", "l"],
        [
            ["OG", og_fg(data.get("og")), "—"],
            ["FG", og_fg(data.get("fg")), "—"],
            ["ABV", f"{data.get('abv', '—')}%" if data.get("abv") else "—", "—"],
            ["IBU", str(round(data.get("ibu", 0))) if data.get("ibu") else "—", "—"],
            [
                "EBC",
                f"{data.get('color'):.1f}".replace(".", ",")
                if data.get("color") is not None
                else "—",
                "—",
            ],
        ],
    )


def main():
    if len(sys.argv) != 2:
        print("uso: extract_recipe.py <recipe.json>", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)

    style = data.get("style") or {}
    fermentables_table, total_line = build_fermentables(data)
    yeast_table, yeast_raw = build_yeast(data)

    bjcp_url = None
    is_bjcp_2021 = (style.get("styleGuide") or "").strip().upper() == "BJCP 2021"
    if is_bjcp_2021 and style.get("categoryNumber") and style.get("styleLetter") and style.get("category"):
        cat_slug = f"{style['categoryNumber']}-{slugify(style['category'])}"
        sub_slug = f"{style['categoryNumber'].lower()}{style['styleLetter'].lower()}-{slugify(style.get('name', ''))}"
        bjcp_url = f"https://bjcp-brasil.github.io/bjcp-2021-pt-br/{cat_slug}/{sub_slug}/"

    out = {
        "meta": {
            "name": data.get("name"),
            "name_slug": slugify(data.get("name")),
            "batch_size_l": data.get("batchSize"),
            "style": {
                "name": style.get("name"),
                "name_slug": slugify(style.get("name")),
                "category_number": style.get("categoryNumber"),
                "style_letter": style.get("styleLetter"),
                "category": style.get("category"),
                "style_guide": style.get("styleGuide"),
                "is_bjcp_2021": is_bjcp_2021,
                "guessed_bjcp_url": bjcp_url,
            },
        },
        "tables": {
            "fermentables": fermentables_table,
            "fermentables_total": total_line,
            "mash": build_mash(data),
            "hops_and_spices": build_hops_and_spices(data),
            "fermentation": build_fermentation(data),
            "yeast": yeast_table,
            "comparativo_estimado": build_estimado(data),
        },
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
