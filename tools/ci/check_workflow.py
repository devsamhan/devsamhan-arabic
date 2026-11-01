#!/usr/bin/env python3
"""Static checks for the arabic_text workflow: triggers, parity, permissions, pins."""
import re
import sys
from pathlib import Path

path = Path(sys.argv[1] if len(sys.argv) > 1 else ".github/workflows/arabic_text.yml")
text = path.read_text(encoding="utf-8")
errors = []

for needle in ("'tools/**'", "paths:", "push:", "pull_request:"):
    if text.count(needle) < 1:
        errors.append(f"missing {needle}")
if text.count("'tools/**'") < 2:
    errors.append("tools/** must appear in both push and pull_request paths")
if "permissions:\n  contents: read" not in text:
    errors.append("contents: read permission missing")
if "persist-credentials: false" not in text:
    errors.append("persist-credentials: false missing")
if "timeout-minutes: 20" not in text:
    errors.append("job timeout missing")
if "jobs:\n" not in text or "\n  parity:\n" not in text:
    errors.append("parity job missing")
parity = text.split("\n  parity:\n", 1)[1] if "\n  parity:\n" in text else ""
for command in ("tools/parity/run_python.py", "tools/parity/run_dart.dart",
                "tools/parity/run_javascript.cjs", "tools/parity/compare.py"):
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

print("WORKFLOW_CHECK", "PASS" if not errors else "FAIL")
for error in errors:
    print("ERROR", error)
raise SystemExit(1 if errors else 0)
