from __future__ import annotations

from .reshaper import reshape

# Arabic-dominant threshold: letter-only ratio > 0.5.
# Counts U+0621–U+063A and U+0641–U+064A divided by non-whitespace char count.
# Differs from the TypeScript port which counts all U+0600–U+06FF / total.
def _arabic_letter_ratio(text: str) -> float:
    letters = 0
    non_ws = 0
    for ch in text:
        if ch in ' \t\n\r':
            continue
        non_ws += 1
        cp = ord(ch)
        if (0x0621 <= cp <= 0x063A) or (0x0641 <= cp <= 0x064A):
            letters += 1
    return letters / non_ws if non_ws > 0 else 0.0


def _classify(cp: int) -> str:
    # Arabic letters U+0621–U+063A, tatweel U+0640, tashkeel U+064B–U+065F
    if 0x0621 <= cp <= 0x065F:
        return 'arabic'
    if (0x41 <= cp <= 0x5A) or (0x61 <= cp <= 0x7A):
        return 'latin'
    # ASCII 0–9, Eastern Arabic U+0660–U+0669, Persian U+06F0–U+06F9
    if (0x30 <= cp <= 0x39) or (0x0660 <= cp <= 0x0669) or (0x06F0 <= cp <= 0x06F9):
        return 'number'
    if cp in (0x20, 0x09, 0x0A, 0x0D):
        return 'space'
    return 'punctuation'


def _split_runs(text: str) -> list[tuple[str, str]]:
    if not text:
        return []
    chars = list(text)
    runs: list[tuple[str, str]] = []
    current_type = _classify(ord(chars[0]))
    start = 0
    for i in range(1, len(chars)):
        t = _classify(ord(chars[i]))
        if t != current_type:
            runs.append((current_type, ''.join(chars[start:i])))
            start = i
            current_type = t
    runs.append((current_type, ''.join(chars[start:])))
    return runs


def prepare_for_terminal(
    text: str,
    *,
    do_reshape: bool = True,
    reorder: bool = True,
    use_lam_alef_ligatures: bool = False,
) -> str:
    if not text:
        return text

    runs = _split_runs(text)

    if do_reshape:
        runs = [
            ('arabic', reshape(content, use_lam_alef_ligatures=use_lam_alef_ligatures))
            if run_type == 'arabic'
            else (run_type, content)
            for run_type, content in runs
        ]

    if reorder and _arabic_letter_ratio(text) > 0.5:
        runs = list(reversed(runs))

    return ''.join(content for _, content in runs)


def print_arabic(
    text: str,
    *,
    do_reshape: bool = True,
    reorder: bool = True,
    use_lam_alef_ligatures: bool = False,
) -> None:
    print(prepare_for_terminal(
        text,
        do_reshape=do_reshape,
        reorder=reorder,
        use_lam_alef_ligatures=use_lam_alef_ligatures,
    ))


def detect_direction(text: str) -> str:
    if not text:
        return 'ltr'
    arabic = 0
    latin = 0
    for ch in text:
        cp = ord(ch)
        if 0x0600 <= cp <= 0x06FF:
            arabic += 1
        if (0x41 <= cp <= 0x5A) or (0x61 <= cp <= 0x7A):
            latin += 1
    total = arabic + latin
    if total == 0:
        return 'ltr'
    if arabic / total >= 0.8:
        return 'rtl'
    if latin / total >= 0.8:
        return 'ltr'
    return 'mixed'
