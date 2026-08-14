#!/usr/bin/env python3
"""Scan _posts for "Brassagem <ROMAN>" titles and print the next number,
both as a roman numeral and as an int, e.g.:

    XXVII 27

Run from the repo root:  python3 .agents/skills/novo-post/next_batch_number.py
"""
import re
from pathlib import Path

ROMAN_VALUES = [
    (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
    (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
    (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
]


def to_roman(n):
    result = []
    for value, symbol in ROMAN_VALUES:
        count, n = divmod(n, value)
        result.append(symbol * count)
    return "".join(result)


def from_roman(s):
    values = {"I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000}
    total = 0
    prev = 0
    for ch in reversed(s.upper()):
        v = values[ch]
        total += -v if v < prev else v
        prev = max(prev, v)
    return total


def main():
    posts_dir = Path(__file__).resolve().parents[3] / "_posts"
    pattern = re.compile(r"^title:\s*Brassagem\s+([IVXLCDM]+)", re.MULTILINE | re.IGNORECASE)
    max_n = 0
    for post in posts_dir.glob("*.md"):
        text = post.read_text(encoding="utf-8", errors="ignore")
        m = pattern.search(text)
        if m:
            max_n = max(max_n, from_roman(m.group(1)))
    next_n = max_n + 1
    print(f"{to_roman(next_n)} {next_n}")


if __name__ == "__main__":
    main()
