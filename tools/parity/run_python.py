"""Source-controlled Python runner for the P0.5 cross-language corpus."""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "packages" / "arabic_text" / "python"))
import devsamhan_arabic_text as api

OPS = {
    "toSearchKey": api.to_search_key,
    "toLooseSearchKey": api.to_loose_search_key,
    "normalizeName": api.normalize_name,
    "toDisplayKey": api.to_display_key,
    "toSlug": api.to_slug,
    "removeTashkeel": api.remove_tashkeel,
    "removeTatweel": api.remove_tatweel,
    "normalizeAlef": api.normalize_alef,
    "normalizeHamza": api.normalize_hamza,
    "normalizeYa": api.normalize_ya,
    "normalizeTaMarbouta": api.normalize_ta_marbouta,
    "normalizePresentationForms": api.normalize_presentation_forms,
    "digitsWestern": lambda s: api.normalize_digits(s, "western"),
    "digitsEastern": lambda s: api.normalize_digits(s, "eastern"),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--corpus", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    corpus = json.loads(Path(args.corpus).read_text(encoding="utf-8"))
    rows = []
    for item in corpus["inputs"]:
        for name in corpus["operations"]:
            output = OPS[name](item["text"])
            rows.append({
                "id": item["id"],
                "operation": name,
                "input": item["text"],
                "output": output,
                "codepoints": " ".join(f"U+{ord(ch):04X}" for ch in output),
            })
    Path(args.out).write_text(
        json.dumps({"impl": "python", "seed": corpus["seed"], "results": rows},
                   ensure_ascii=True, indent=1),
        encoding="utf-8",
    )
    print(f"PY_RESULTS {len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
