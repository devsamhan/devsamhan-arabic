"""SPEC_VERSION regression for the 1.0.1 clarification."""

from devsamhan_arabic_text import SPEC_VERSION


def test_spec_version_is_1_0_1() -> None:
    assert SPEC_VERSION == "1.0.1"
