#!/usr/bin/env python3
"""Static checks for the arabic_text workflow: triggers, parity, permissions, pins.

The workflow must run on every pull request (no pull_request path filter) so the
four required branch-protection checks always report, while push runs stay
path-filtered to the arabic_text release surface.

Run the negative regression suite with:
    python tools/ci/check_workflow.py --self-test
"""
import re
import sys
from pathlib import Path
from typing import Optional

REQUIRED_PUSH_PATHS = (
    "packages/arabic_text/**",
    "test_fixtures/**",
    "tools/**",
    ".github/workflows/arabic_text.yml",
)
REQUIRED_JOBS = ("dart", "typescript", "python", "parity")
PARITY_COMMANDS = (
    "tools/parity/run_python.py",
    "tools/parity/run_dart.dart",
    "tools/parity/run_javascript.cjs",
    "tools/parity/compare.py",
)


def event_block(text: str, event: str) -> Optional[str]:
    """Return the indented body of a top-level event under ``on:``."""
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if line == f"  {event}:":
            block = []
            for nxt in lines[index + 1:]:
                if nxt.strip() and not nxt.startswith("    "):
                    break
                block.append(nxt)
            return "\n".join(block)
    return None


def job_block(text: str, job: str) -> Optional[str]:
    """Return the indented body of a job under ``jobs:``."""
    marker = f"\n  {job}:\n"
    if marker not in text:
        return None
    block = []
    for line in text.split(marker, 1)[1].splitlines():
        if line.strip() and not line.startswith("    "):
            break
        block.append(line)
    return "\n".join(block)


def validate(text: str) -> list[str]:
    errors: list[str] = []

    push = event_block(text, "push")
    pull_request = event_block(text, "pull_request")
    if push is None:
        errors.append("missing push event")
    if pull_request is None:
        errors.append("missing pull_request event")

    if push is not None:
        if "paths:" not in push:
            errors.append("push event must keep path filters")
        for required in REQUIRED_PUSH_PATHS:
            if f"'{required}'" not in push:
                errors.append(f"push paths missing: {required}")

    if pull_request is not None:
        if "paths:" in pull_request or "paths-ignore:" in pull_request:
            errors.append("pull_request must not use paths or paths-ignore filters")

    if "permissions:\n  contents: read" not in text:
        errors.append("contents: read permission missing")

    if text.count("persist-credentials: false") < len(REQUIRED_JOBS):
        errors.append("persist-credentials: false must appear in every job")

    for job in REQUIRED_JOBS:
        block = job_block(text, job)
        if block is None:
            errors.append(f"required job missing: {job}")
        elif "timeout-minutes: 20" not in block:
            errors.append(f"job timeout missing: {job}")

    parity = job_block(text, "parity") or ""
    for command in PARITY_COMMANDS:
        if command not in parity:
            errors.append(f"parity command missing: {command}")
    if "python -m unittest discover -s tools/parity -p test_compare.py -q" not in parity:
        errors.append("parity job must use stdlib unittest for comparator tests")
    if "pytest" in parity:
        errors.append("parity job must not rely on undeclared pytest")

    if "npm ci" not in text:
        errors.append("npm ci missing")

    refs = re.findall(r"uses:\s*([^\s#]+)", text)
    for ref in refs:
        if not re.search(r"@[0-9a-f]{40}$", ref):
            errors.append(f"action not SHA-pinned: {ref}")

    return errors


def _mutate(text: str, old: str, new: str) -> str:
    if old not in text:
        raise RuntimeError(f"self-test mutation anchor not found: {old!r}")
    return text.replace(old, new, 1)


def self_test(workflow_text: str) -> int:
    cases = [
        (
            "pull_request.paths reintroduced",
            "pull_request must not use paths",
            _mutate(
                workflow_text,
                "  pull_request:\n",
                "  pull_request:\n    paths:\n      - 'README.md'\n",
            ),
        ),
        (
            "pull_request.paths-ignore added",
            "pull_request must not use paths",
            _mutate(
                workflow_text,
                "  pull_request:\n",
                "  pull_request:\n    paths-ignore:\n      - 'docs/**'\n",
            ),
        ),
        (
            "push tools path removed",
            "push paths missing: tools/**",
            _mutate(workflow_text, "      - 'tools/**'\n", ""),
        ),
        (
            "action unpinned",
            "action not SHA-pinned",
            _mutate(
                workflow_text,
                "actions/checkout@11d5960a326750d5838078e36cf38b85af677262",
                "actions/checkout@v4",
            ),
        ),
        (
            "parity job removed",
            "required job missing: parity",
            _mutate(workflow_text, "\n  parity:\n", "\n  parity_disabled:\n"),
        ),
        (
            "job timeout weakened",
            "job timeout missing: dart",
            _mutate(workflow_text, "    timeout-minutes: 20", "    timeout-minutes: 5"),
        ),
        (
            "persist-credentials removed",
            "persist-credentials",
            _mutate(workflow_text, "          persist-credentials: false\n", ""),
        ),
        (
            "contents permission removed",
            "contents: read permission missing",
            _mutate(workflow_text, "permissions:\n  contents: read\n", ""),
        ),
        (
            "pull_request event removed",
            "missing pull_request event",
            _mutate(workflow_text, "  pull_request:\n", ""),
        ),
        (
            "parity command removed",
            "parity command missing: tools/parity/compare.py",
            _mutate(workflow_text, "tools/parity/compare.py", "tools/parity/missing.py"),
        ),
    ]

    failures = 0
    for name, expected, mutated in cases:
        errors = validate(mutated)
        ok = any(expected in error for error in errors)
        print(f"SELF_TEST {name}: {'PASS' if ok else 'FAIL'}")
        if not ok:
            failures += 1
            print(f"  expected error containing {expected!r}; got {errors}")

    positive = validate(workflow_text)
    print(f"SELF_TEST positive control: {'PASS' if not positive else 'FAIL'}")
    if positive:
        failures += 1
        print(f"  unexpected errors: {positive}")

    print("WORKFLOW_SELF_TEST", "PASS" if failures == 0 else "FAIL")
    return 0 if failures == 0 else 1


def main() -> int:
    args = [arg for arg in sys.argv[1:] if arg != "--self-test"]
    default = Path(".github/workflows/arabic_text.yml")
    path = Path(args[0]) if args else default
    if "--self-test" in sys.argv[1:]:
        return self_test(path.read_text(encoding="utf-8"))

    errors = validate(path.read_text(encoding="utf-8"))
    print("WORKFLOW_CHECK", "PASS" if not errors else "FAIL")
    for error in errors:
        print("ERROR", error)
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
