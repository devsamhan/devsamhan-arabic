#!/usr/bin/env python3
"""Assert built Python artifacts contain the PEP 561 marker.

Usage:
  python tools/packaging/check_python_artifacts.py <wheel> <sdist>
"""
from __future__ import annotations

import sys
import tarfile
import zipfile
from pathlib import Path


def check_wheel(path: Path) -> None:
    with zipfile.ZipFile(path) as zf:
        names = zf.namelist()
        marker = "devsamhan_arabic_text/py.typed"
        assert marker in names, f"{path}: missing {marker}"
        assert any(name.endswith(".dist-info/METADATA") for name in names), path
        metadata = zf.read(next(name for name in names if name.endswith("METADATA"))).decode("utf-8")
        assert "Typing :: Typed" in metadata, f"{path}: typed classifier missing"


def check_sdist(path: Path) -> None:
    with tarfile.open(path) as tf:
        names = tf.getnames()
        assert any(name.endswith("/devsamhan_arabic_text/py.typed") for name in names), (
            f"{path}: missing package py.typed"
        )


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__)
        return 2
    wheel, sdist = Path(argv[1]), Path(argv[2])
    check_wheel(wheel)
    check_sdist(sdist)
    print("PYTHON_ARTIFACTS PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
