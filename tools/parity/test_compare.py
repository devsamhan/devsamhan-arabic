"""Fail-closed comparator tests: positive and negative cases.

Run from the repository root:
  python -m pytest tools/parity/test_compare.py -q
or:
  python -m unittest tools/parity/test_compare.py
"""
from __future__ import annotations

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from compare import ValidationError, codepoints, compare, main

CORPUS = {
    "seed": 7,
    "operations": ["toSearchKey", "digitsEastern"],
    "inputs": [
        {"id": "a", "text": "فاطمة"},
        {"id": "b", "text": "۱۲۳"},
    ],
}


def port_rows(port: str = "dart") -> list[dict[str, str]]:
    rows = []
    for item in CORPUS["inputs"]:
        for op in CORPUS["operations"]:
            output = item["text"] if op == "toSearchKey" else "١٢٣"
            rows.append({
                "id": item["id"],
                "operation": op,
                "input": item["text"],
                "output": output,
                "codepoints": codepoints(output),
            })
    return rows


def payload(name: str) -> dict:
    return {"impl": name, "seed": CORPUS["seed"], "results": port_rows(name)}


def base_payloads() -> dict[str, dict]:
    return {name: payload(name) for name in ("dart", "typescript", "python")}


class ComparatorTests(unittest.TestCase):
    def test_positive(self) -> None:
        result = compare(copy.deepcopy(CORPUS), base_payloads())
        self.assertEqual(result["status"], "PASS", result)
        self.assertEqual(result["compared_rows"], 4)
        self.assertEqual(result["ports"]["dart"]["rows"], 4)

    def test_missing_row(self) -> None:
        p = base_payloads()
        p["dart"]["results"].pop()
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("missing key" in e or "result count" in e for e in result["errors"]))

    def test_extra_row(self) -> None:
        p = base_payloads()
        p["dart"]["results"].append({
            "id": "zzz", "operation": "toSearchKey", "input": "x",
            "output": "x", "codepoints": "U+0078",
        })
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("extra key" in e for e in result["errors"]))

    def test_duplicate_row(self) -> None:
        p = base_payloads()
        p["dart"]["results"].append(copy.deepcopy(p["dart"]["results"][0]))
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("duplicate key" in e for e in result["errors"]))

    def test_wrong_seed(self) -> None:
        p = base_payloads()
        p["typescript"]["seed"] = 8
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("seed" in e for e in result["errors"]))

    def test_wrong_input(self) -> None:
        p = base_payloads()
        p["python"]["results"][0]["input"] = "wrong"
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("input mismatch" in e for e in result["errors"]))

    def test_altered_output_is_divergence(self) -> None:
        p = base_payloads()
        row = p["dart"]["results"][0]
        row["output"] = "changed"
        row["codepoints"] = codepoints("changed")
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(len(result["divergences"]), 1)

    def test_corrupt_codepoints(self) -> None:
        p = base_payloads()
        p["typescript"]["results"][0]["codepoints"] = "U+FFFF"
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("codepoint mismatch" in e for e in result["errors"]))

    def test_missing_port(self) -> None:
        p = base_payloads()
        del p["python"]
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("missing port" in e for e in result["errors"]))

    def test_lone_surrogate_output(self) -> None:
        p = base_payloads()
        p["dart"]["results"][0]["output"] = "\ud800"
        p["dart"]["results"][0]["codepoints"] = "U+D800"
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("invalid Unicode scalar" in e for e in result["errors"]))

    def test_surrogate_corpus_input(self) -> None:
        corpus = copy.deepcopy(CORPUS)
        corpus["inputs"][0]["text"] = "\ud800"
        with self.assertRaises(ValidationError):
            compare(corpus, base_payloads())

    def test_malformed_codepoint_tokens(self) -> None:
        p = base_payloads()
        p["dart"]["results"][0]["codepoints"] = "u+0078"
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("malformed codepoint" in e for e in result["errors"]))

    def test_bool_seed_rejected(self) -> None:
        corpus = copy.deepcopy(CORPUS)
        corpus["seed"] = True
        with self.assertRaises(ValidationError):
            compare(corpus, base_payloads())
        p = base_payloads()
        p["dart"]["seed"] = True
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("seed must be an integer" in e for e in result["errors"]))

    def test_compared_rows_uses_actual_comparable_keys(self) -> None:
        corpus = copy.deepcopy(CORPUS)
        corpus["inputs"].append({"id": "c", "text": "third"})
        p = base_payloads()
        for name in p:
            output = "third"
            p[name]["results"].append({
                "id": "c", "operation": "toSearchKey", "input": "third",
                "output": output, "codepoints": codepoints(output),
            })
        p["dart"]["results"].pop()
        result = compare(corpus, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["expected_keys"], 6)
        self.assertLess(result["compared_rows"], result["expected_keys"])
        self.assertGreater(result["compared_rows"], 0)

    def test_duplicate_corpus_ids(self) -> None:
        corpus = copy.deepcopy(CORPUS)
        corpus["inputs"].append({"id": "a", "text": "x"})
        with self.assertRaises(ValidationError):
            compare(corpus, base_payloads())

    def test_non_string_output(self) -> None:
        p = base_payloads()
        p["dart"]["results"][0]["output"] = 1
        result = compare(CORPUS, p)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("must be strings" in e for e in result["errors"]))

    def test_invalid_json_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            bad = root / "bad.json"
            bad.write_text("{not json", encoding="utf-8")
            corpus_path = root / "corpus.json"
            corpus_path.write_text(json.dumps(CORPUS), encoding="utf-8")
            args = [
                "--corpus", str(corpus_path),
                "--port", f"dart={bad}",
                "--port", "typescript=missing.json",
                "--port", "python=missing.json",
                "--out-json", str(root / "out.json"),
                "--out-md", str(root / "out.md"),
            ]
            self.assertEqual(main(args), 2)

    def test_cli_exit_codes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            corpus_path = root / "corpus.json"
            corpus_path.write_text(json.dumps(CORPUS), encoding="utf-8")
            paths = {}
            for name, data in base_payloads().items():
                path = root / f"{name}.json"
                path.write_text(json.dumps(data), encoding="utf-8")
                paths[name] = path
            args = [
                "--corpus", str(corpus_path),
                "--port", f"dart={paths['dart']}",
                "--port", f"typescript={paths['typescript']}",
                "--port", f"python={paths['python']}",
                "--out-json", str(root / "out.json"),
                "--out-md", str(root / "out.md"),
            ]
            self.assertEqual(main(args), 0)

            p = base_payloads()
            p["dart"]["results"].pop()
            paths["dart"].write_text(json.dumps(p["dart"]), encoding="utf-8")
            self.assertEqual(main(args), 2)

            p = base_payloads()
            p["dart"]["results"][0]["output"] = "changed"
            p["dart"]["results"][0]["codepoints"] = codepoints("changed")
            paths["dart"].write_text(json.dumps(p["dart"]), encoding="utf-8")
            self.assertEqual(main(args), 1)


if __name__ == "__main__":
    unittest.main()
