#!/usr/bin/env python3
"""Fail-closed cross-language parity comparator for Arabic text fixtures.

The comparator validates corpus shape, per-port schema, exact key sets,
duplicates, inputs, seed, codepoints, and cross-port outputs. It never uses an
intersection of keys to decide what to compare.

Exit codes:
  0 = all validations and comparisons passed
  1 = valid schemas but output/divergence mismatch
  2 = schema, completeness, duplicate, seed, input, or codepoint validation error
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

CODEPOINT_RE = r"^U\+[0-9A-F]{4,6}( U\+[0-9A-F]{4,6})*$"


class ValidationError(Exception):
    """Raised when a corpus or result file is structurally invalid."""


def _is_scalar(cp: int) -> bool:
    return 0 <= cp <= 0x10FFFF and not (0xD800 <= cp <= 0xDFFF)


def validate_scalar_text(value: str, label: str) -> None:
    for index, ch in enumerate(value):
        if not _is_scalar(ord(ch)):
            raise ValidationError(
                f"{label}: invalid Unicode scalar at character {index}: U+{ord(ch):04X}"
            )


def codepoints(value: str) -> str:
    """Return canonical Unicode scalar-value tokens for *value*."""
    validate_scalar_text(value, "output")
    return " ".join(f"U+{ord(ch):04X}" for ch in value)


def validate_codepoint_text(value: str, label: str) -> None:
    if value == "":
        return
    if not re.fullmatch(CODEPOINT_RE, value):
        raise ValidationError(f"{label}: malformed codepoint token sequence")
    for token in value.split(" "):
        cp = int(token[2:], 16)
        if not _is_scalar(cp):
            raise ValidationError(f"{label}: invalid Unicode scalar {token}")


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except FileNotFoundError as exc:
        raise ValidationError(f"missing file: {path}") from exc
    except UnicodeDecodeError as exc:
        raise ValidationError(f"invalid UTF-8 in {path}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise ValidationError(f"invalid JSON in {path}: {exc}") from exc


def validate_corpus(corpus: dict[str, Any]) -> tuple[int, list[str], list[str], list[dict[str, Any]]]:
    if not isinstance(corpus, dict):
        raise ValidationError("corpus must be a JSON object")
    seed = corpus.get("seed")
    if not isinstance(seed, int) or isinstance(seed, bool):
        raise ValidationError("corpus.seed must be an integer (bool is not accepted)")
    operations = corpus.get("operations")
    if not isinstance(operations, list) or not operations:
        raise ValidationError("corpus.operations must be a non-empty list")
    if not all(isinstance(op, str) and op for op in operations):
        raise ValidationError("corpus.operations must contain non-empty strings")
    if len(set(operations)) != len(operations):
        raise ValidationError("corpus.operations contains duplicates")
    inputs = corpus.get("inputs")
    if not isinstance(inputs, list) or not inputs:
        raise ValidationError("corpus.inputs must be a non-empty list")
    ids: list[str] = []
    for item in inputs:
        if not isinstance(item, dict) or not isinstance(item.get("id"), str):
            raise ValidationError("every corpus input must have a string id")
        if not isinstance(item.get("text"), str):
            raise ValidationError(f"corpus input {item.get('id')} must have string text")
        validate_scalar_text(item["text"], f"corpus input {item['id']}")
        ids.append(item["id"])
    if len(set(ids)) != len(ids):
        raise ValidationError("corpus.inputs contains duplicate ids")
    return seed, operations, ids, inputs


def expected_keys(corpus: dict[str, Any]) -> set[tuple[str, str]]:
    _, operations, _, inputs = validate_corpus(corpus)
    return {(item["id"], op) for item in inputs for op in operations}


def validate_port(
    name: str,
    payload: Any,
    corpus: dict[str, Any],
    expected: set[tuple[str, str]],
) -> tuple[list[dict[str, Any]], list[str]]:
    """Validate one port and return rows plus errors.

    Duplicate detection happens before any dict materialization.
    """
    errors: list[str] = []
    if not isinstance(payload, dict):
        raise ValidationError(f"{name}: result payload must be an object")
    if payload.get("impl") != name:
        errors.append(f"{name}: impl must be {name!r}, got {payload.get('impl')!r}")
    seed, _, _, inputs = validate_corpus(corpus)
    payload_seed = payload.get("seed")
    if not isinstance(payload_seed, int) or isinstance(payload_seed, bool):
        errors.append(f"{name}: seed must be an integer, got {payload_seed!r}")
    elif payload_seed != seed:
        errors.append(f"{name}: seed must be {seed}, got {payload_seed!r}")
    rows = payload.get("results")
    if not isinstance(rows, list):
        raise ValidationError(f"{name}: results must be a list")

    by_id = {item["id"]: item["text"] for item in inputs}
    seen: set[tuple[str, str]] = set()
    valid_rows: list[dict[str, Any]] = []
    for index, row in enumerate(rows):
        prefix = f"{name}: row {index}"
        if not isinstance(row, dict):
            errors.append(f"{prefix}: must be an object")
            continue
        required = {"id", "operation", "input", "output", "codepoints"}
        missing = required - set(row)
        if missing:
            errors.append(f"{prefix}: missing keys {sorted(missing)}")
            continue
        if not all(isinstance(row[k], str) for k in required):
            errors.append(f"{prefix}: all fields must be strings")
            continue
        key = (row["id"], row["operation"])
        if key in seen:
            errors.append(f"{name}: duplicate key {key}")
            continue
        seen.add(key)
        if key not in expected:
            errors.append(f"{name}: extra key {key}")
            continue
        if row["id"] not in by_id:
            errors.append(f"{name}: unknown input id {row['id']}")
            continue
        try:
            validate_scalar_text(row["input"], f"{name}: input {key}")
            computed = codepoints(row["output"])
            validate_codepoint_text(row["codepoints"], f"{name}: codepoints {key}")
        except ValidationError as exc:
            errors.append(str(exc))
            continue
        if row["input"] != by_id[row["id"]]:
            errors.append(
                f"{name}: input mismatch for {key}: expected {by_id[row['id']]!r}, got {row['input']!r}"
            )
            continue
        if row["codepoints"] != computed:
            errors.append(
                f"{name}: codepoint mismatch for {key}: expected {computed!r}, got {row['codepoints']!r}"
            )
            continue
        valid_rows.append(row)

    missing_keys = expected - seen
    for key in sorted(missing_keys):
        errors.append(f"{name}: missing key {key}")

    if len(rows) != len(expected):
        errors.append(
            f"{name}: result count {len(rows)} does not match expected {len(expected)}"
        )
    return valid_rows, errors


def compare(corpus: dict[str, Any], payloads: dict[str, Any]) -> dict[str, Any]:
    seed, operations, ids, inputs = validate_corpus(corpus)
    expected = expected_keys(corpus)
    required_ports = {"dart", "typescript", "python"}
    errors: list[str] = []
    zero_data: list[str] = []

    missing_ports = required_ports - set(payloads)
    extra_ports = set(payloads) - required_ports
    for name in sorted(missing_ports):
        errors.append(f"missing port: {name}")
    for name in sorted(extra_ports):
        errors.append(f"unexpected port: {name}")

    rows_by_port: dict[str, list[dict[str, Any]]] = {}
    for name in sorted(required_ports):
        if name not in payloads:
            continue
        rows, port_errors = validate_port(name, payloads[name], corpus, expected)
        rows_by_port[name] = rows
        errors.extend(port_errors)

    divergences: list[dict[str, Any]] = []
    compared_keys = 0
    if len(rows_by_port) == 3:
        maps = {
            name: {(row["id"], row["operation"]): row for row in rows}
            for name, rows in rows_by_port.items()
        }
        for key in sorted(expected):
            values = {name: maps[name].get(key) for name in maps}
            if any(v is None for v in values.values()):
                continue  # already reported as missing
            compared_keys += 1
            outputs = {name: v["output"] for name, v in values.items() if v}
            if len(set(outputs.values())) != 1:
                divergences.append({
                    "id": key[0],
                    "operation": key[1],
                    "outputs": outputs,
                    "codepoints": {name: v["codepoints"] for name, v in values.items() if v},
                })

    status = "PASS" if not errors and not divergences else "FAIL"
    return {
        "status": status,
        "seed": seed,
        "expected_operations": len(operations),
        "expected_inputs": len(ids),
        "expected_keys": len(expected),
        "expected_rows_per_port": len(expected),
        "ports": {
            name: {
                "rows": len(rows_by_port.get(name, [])),
                "unique_keys": len({(r["id"], r["operation"]) for r in rows_by_port.get(name, [])}),
            }
            for name in sorted(rows_by_port)
        },
        "compared_rows": compared_keys,
        "errors": errors,
        "divergences": divergences,
    }


def _write_reports(result: dict[str, Any], out_json: Path, out_md: Path) -> None:
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(result, ensure_ascii=True, indent=1), encoding="utf-8")
    lines = [
        "# Cross-language parity report",
        "",
        f"- Status: **{result['status']}**",
        f"- Seed: `{result['seed']}`",
        f"- Expected inputs: {result['expected_inputs']}",
        f"- Expected operations: {result['expected_operations']}",
        f"- Expected rows per port: {result['expected_rows_per_port']}",
        f"- Compared rows: {result['compared_rows']}",
        f"- Errors: {len(result['errors'])}",
        f"- Divergences: {len(result['divergences'])}",
        "",
        "| Port | Valid rows | Unique keys |",
        "|---|---:|---:|",
    ]
    for name, stats in result["ports"].items():
        lines.append(f"| {name} | {stats['rows']} | {stats['unique_keys']} |")
    if result["errors"]:
        lines += ["", "## Errors", ""] + [f"- {e}" for e in result["errors"]]
    if result["divergences"]:
        lines += ["", "## Divergences", ""]
        for d in result["divergences"]:
            lines.append(f"- `{d['id']}` / `{d['operation']}`: `{d['outputs']}`")
    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", required=True, type=Path)
    parser.add_argument("--port", action="append", default=[], metavar="NAME=PATH")
    parser.add_argument("--out-json", type=Path, default=Path("parity_results.json"))
    parser.add_argument("--out-md", type=Path, default=Path("parity_summary.md"))
    args = parser.parse_args(argv)

    payloads: dict[str, Any] = {}
    try:
        corpus = _load_json(args.corpus)
        for spec in args.port:
            if "=" not in spec:
                raise ValidationError(f"invalid --port value: {spec}")
            name, raw_path = spec.split("=", 1)
            if name in payloads:
                raise ValidationError(f"duplicate --port: {name}")
            payloads[name] = _load_json(Path(raw_path))
        result = compare(corpus, payloads)
    except ValidationError as exc:
        result = {
            "status": "FAIL",
            "seed": None,
            "expected_operations": 0,
            "expected_inputs": 0,
            "expected_keys": 0,
            "expected_rows_per_port": 0,
            "ports": {},
            "compared_rows": 0,
            "errors": [str(exc)],
            "divergences": [],
        }
        _write_reports(result, args.out_json, args.out_md)
        print("PARITY_RESULT FAIL")
        print(f"ERROR {exc}")
        return 2
    _write_reports(result, args.out_json, args.out_md)
    print(f"PARITY_RESULT {result['status']}")
    print(f"COMPARED {result['compared_rows']} DIVERGENCES {len(result['divergences'])}")
    for error in result["errors"]:
        print(f"ERROR {error}")
    if result["errors"]:
        return 2
    if result["divergences"]:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
