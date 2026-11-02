#!/usr/bin/env python3
"""Static checks for the arabic_text workflow.

Invariants:
- pull_request is unfiltered so every PR produces the four required contexts.
- push is filtered to master and to the release paths, so feature-branch pushes
  do not duplicate PR runs.
- concurrency is scoped per workflow + event + PR/ref and cancels superseded runs.
- actions are the verified Node24-native releases, pinned to full commit SHAs.
- project test Node is 24; npm caching is explicitly disabled.
- four required jobs, read-only permissions, checkout credential controls,
  timeouts and parity steps are preserved.

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

# Verified Node24-native action releases, resolved from their upstream tags.
APPROVED_ACTION_PINS = {
    "actions/checkout": "3d3c42e5aac5ba805825da76410c181273ba90b1",      # v7.0.1
    "actions/setup-node": "949feb2413d6458794dcd2491c4babbbce0c15c1",   # v7.1.0
    "actions/setup-python": "6d4fd22b20465ccc0f7354476588e8df7c9ca0e0", # v7.1.0
    "dart-lang/setup-dart": "65eb853c7ba17dde3be364c3d2858773e7144260", # v1.7.2
}


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


def top_block(text: str, key: str) -> Optional[str]:
    """Return the indented body of a top-level mapping key."""
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if line == f"{key}:":
            block = []
            for nxt in lines[index + 1:]:
                if nxt.strip() and not nxt.startswith("  "):
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

        branch_match = re.search(r"branches:\s*\n((?:[ \t]+-[ \t]*[^\n]+\n?)+)", push)
        if not branch_match:
            errors.append("push.branches missing")
        else:
            branches = re.findall(r"-\s*'?([^'\s]+)'?", branch_match.group(1))
            if branches != ["master"]:
                errors.append(f"push.branches must be only master, got {branches}")

    if pull_request is not None:
        if "paths:" in pull_request or "paths-ignore:" in pull_request:
            errors.append("pull_request must not use paths or paths-ignore filters")

    concurrency = top_block(text, "concurrency")
    if concurrency is None:
        errors.append("workflow concurrency missing")
    else:
        if "group:" not in concurrency:
            errors.append("concurrency group missing")
        else:
            group_line = next(line for line in concurrency.splitlines() if "group:" in line)
            for token in ("github.workflow", "github.event_name"):
                if token not in group_line:
                    errors.append(f"concurrency group missing {token}")
            if "github.event.pull_request.number || github.ref" not in group_line:
                errors.append("concurrency group must scope by PR number or ref")
        if "cancel-in-progress: true" not in concurrency:
            errors.append("concurrency must cancel superseded runs")

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

    node_versions = re.findall(r"node-version:\s*['\"]?([^'\"\s]+)", text)
    if node_versions.count("24") < 2:
        errors.append("setup-node must use node-version 24 in both jobs")
    for version in node_versions:
        if version != "24":
            errors.append(f"unexpected test node version: {version}")
    if text.count("package-manager-cache: false") < 2:
        errors.append("package-manager-cache: false must be set in both setup-node steps")
    if re.search(r"^\s+cache:", text, re.M):
        errors.append("unexpected action cache configuration")

    uses_lines = [line for line in text.splitlines() if "uses:" in line]
    for line in uses_lines:
        reference = line.split("uses:", 1)[1].split("#", 1)[0].strip()
        if "#" not in line:
            errors.append(f"action version comment missing: {reference}")
        if "@" not in reference:
            errors.append(f"action not pinned: {reference}")
            continue
        action, sha = reference.split("@", 1)
        if not re.fullmatch(r"[0-9a-f]{40}", sha):
            errors.append(f"action not SHA-pinned: {reference}")
            continue
        approved = APPROVED_ACTION_PINS.get(action)
        if approved is None:
            errors.append(f"unapproved action: {action}")
        elif sha != approved:
            errors.append(f"action pin not approved: {action}@{sha}")
    for action in APPROVED_ACTION_PINS:
        if f"{action}@" not in text:
            errors.append(f"required action missing: {action}")

    return errors


def _mutate(text: str, old: str, new: str) -> str:
    if old not in text:
        raise RuntimeError(f"self-test mutation anchor not found: {old!r}")
    return text.replace(old, new, 1)


def self_test(workflow_text: str) -> int:
    cases = [
        ("pull_request.paths reintroduced", "pull_request must not use paths",
         _mutate(workflow_text, "  pull_request:\n",
                 "  pull_request:\n    paths:\n      - 'README.md'\n")),
        ("pull_request.paths-ignore added", "pull_request must not use paths",
         _mutate(workflow_text, "  pull_request:\n",
                 "  pull_request:\n    paths-ignore:\n      - 'docs/**'\n")),
        ("push tools path removed", "push paths missing: tools/**",
         _mutate(workflow_text, "      - 'tools/**'\n", "")),
        ("push feature branch added", "push.branches must be only master",
         _mutate(workflow_text, "      - master\n", "      - master\n      - feature\n")),
        ("concurrency removed", "workflow concurrency missing",
         _mutate(workflow_text, "concurrency:\n", "concurrency_disabled:\n")),
        ("concurrency group not scoped", "concurrency group must scope by PR number or ref",
         _mutate(workflow_text,
                 "${{ github.workflow }}-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}",
                 "${{ github.workflow }}-${{ github.event_name }}")),
        ("cancel-in-progress false", "concurrency must cancel superseded runs",
         _mutate(workflow_text, "cancel-in-progress: true", "cancel-in-progress: false")),
        ("action unpinned", "action not SHA-pinned",
         _mutate(workflow_text,
                 "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1",
                 "actions/checkout@v7.0.1")),
        ("action old pin", "action pin not approved",
         _mutate(workflow_text,
                 "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1",
                 "actions/checkout@11d5960a326750d5838078e36cf38b85af677262")),
        ("node version regressed", "unexpected test node version: 20",
         _mutate(workflow_text, "node-version: '24'", "node-version: '20'")),
        ("package manager cache removed", "package-manager-cache: false",
         _mutate(workflow_text, "          package-manager-cache: false\n", "")),
        ("parity job removed", "required job missing: parity",
         _mutate(workflow_text, "\n  parity:\n", "\n  parity_disabled:\n")),
        ("job timeout weakened", "job timeout missing: dart",
         _mutate(workflow_text, "    timeout-minutes: 20", "    timeout-minutes: 5")),
        ("persist-credentials removed", "persist-credentials",
         _mutate(workflow_text, "          persist-credentials: false\n", "")),
        ("contents permission removed", "contents: read permission missing",
         _mutate(workflow_text, "permissions:\n  contents: read\n", "")),
        ("pull_request event removed", "missing pull_request event",
         _mutate(workflow_text, "  pull_request:\n", "")),
        ("parity command removed", "parity command missing: tools/parity/compare.py",
         _mutate(workflow_text, "tools/parity/compare.py", "tools/parity/missing.py")),
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
