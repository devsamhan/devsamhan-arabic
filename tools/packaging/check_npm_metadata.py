#!/usr/bin/env python3
"""Assert npm package/lock root metadata consistency without dependency drift."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main(argv: list[str]) -> int:
    root = Path(argv[1]) if len(argv) > 1 else Path("packages/arabic_text/js")
    package = json.loads((root / "package.json").read_text(encoding="utf-8"))
    lock = json.loads((root / "package-lock.json").read_text(encoding="utf-8"))
    assert lock["version"] == package["version"], (
        f"lock root {lock['version']} != package {package['version']}"
    )
    assert lock["packages"][""]["version"] == package["version"], (
        "lock packages[''] version mismatch"
    )
    assert package.get("main") == "dist/index.js"
    assert package.get("types") == "dist/index.d.ts"
    print("NPM_METADATA PASS", package["version"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
