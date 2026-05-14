from __future__ import annotations

_ISO, _FIN, _INI, _MED = 0, 1, 2, 3

# [isolated, final, initial, medial] — 0 = no form for that position
_FORMS: dict[int, tuple[int, int, int, int]] = {
    0x0621: (0xFE80, 0,      0,      0     ),  # ء HAMZA — U-type
    0x0622: (0xFE81, 0xFE82, 0,      0     ),  # آ ALEF MADDA — R-type
    0x0623: (0xFE83, 0xFE84, 0,      0     ),  # أ ALEF HMZ ABOVE — R-type
    0x0624: (0xFE85, 0xFE86, 0,      0     ),  # ؤ WAW HMZ — R-type
    0x0625: (0xFE87, 0xFE88, 0,      0     ),  # إ ALEF HMZ BELOW — R-type
    0x0626: (0xFE89, 0xFE8A, 0xFE8B, 0xFE8C),  # ئ YEH HMZ — D-type
    0x0627: (0xFE8D, 0xFE8E, 0,      0     ),  # ا ALEF — R-type
    0x0628: (0xFE8F, 0xFE90, 0xFE91, 0xFE92),  # ب BA — D-type
    0x0629: (0xFE93, 0xFE94, 0,      0     ),  # ة TA MARBUTA — D-type (no ini/med)
    0x062A: (0xFE95, 0xFE96, 0xFE97, 0xFE98),  # ت TA — D-type
    0x062B: (0xFE99, 0xFE9A, 0xFE9B, 0xFE9C),  # ث THA — D-type
    0x062C: (0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0),  # ج JEEM — D-type
    0x062D: (0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4),  # ح HAH — D-type
    0x062E: (0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8),  # خ KHAH — D-type
    0x062F: (0xFEA9, 0xFEAA, 0,      0     ),  # د DAL — R-type
    0x0630: (0xFEAB, 0xFEAC, 0,      0     ),  # ذ THAL — R-type
    0x0631: (0xFEAD, 0xFEAE, 0,      0     ),  # ر RA — R-type
    0x0632: (0xFEAF, 0xFEB0, 0,      0     ),  # ز ZAIN — R-type
    0x0633: (0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4),  # س SEEN — D-type
    0x0634: (0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8),  # ش SHEEN — D-type
    0x0635: (0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC),  # ص SAD — D-type
    0x0636: (0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0),  # ض DAD — D-type
    0x0637: (0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4),  # ط TAH — D-type
    0x0638: (0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8),  # ظ ZAH — D-type
    0x0639: (0xFEC9, 0xFECA, 0xFECB, 0xFECC),  # ع AIN — D-type
    0x063A: (0xFECD, 0xFECE, 0xFECF, 0xFED0),  # غ GHAIN — D-type
    # U+063B–U+063F: rare/extended — no Presentation Forms-B; pass through
    # U+0640: tatweel — transparent; not in _FORMS
    0x0641: (0xFED1, 0xFED2, 0xFED3, 0xFED4),  # ف FA — D-type
    0x0642: (0xFED5, 0xFED6, 0xFED7, 0xFED8),  # ق QAF — D-type
    0x0643: (0xFED9, 0xFEDA, 0xFEDB, 0xFEDC),  # ك KAF — D-type
    0x0644: (0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0),  # ل LAM — D-type
    0x0645: (0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4),  # م MEEM — D-type
    0x0646: (0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8),  # ن NOON — D-type
    0x0647: (0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC),  # ه HEH — D-type
    0x0648: (0xFEED, 0xFEEE, 0,      0     ),  # و WAW — R-type
    0x0649: (0xFEEF, 0xFEF0, 0,      0     ),  # ى ALEF MAQSURA — R-type
    0x064A: (0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4),  # ي YEH — D-type
}

# R-type: joinsLeft only — accept connection from prev, cannot extend to next
_RIGHT_JOINING: frozenset[int] = frozenset({
    0x0622, 0x0623, 0x0624, 0x0625, 0x0627,
    0x062F, 0x0630, 0x0631, 0x0632, 0x0648, 0x0649,
})

# Maps alef variant → (isolated_ligature, final_ligature)
_LAM_ALEF_FORMS: dict[int, tuple[int, int]] = {
    0x0627: (0xFEFB, 0xFEFC),  # ل + ا
    0x0622: (0xFEF5, 0xFEF6),  # ل + آ
    0x0623: (0xFEF7, 0xFEF8),  # ل + أ
    0x0625: (0xFEF9, 0xFEFA),  # ل + إ
}


def _is_arabic_letter(cp: int) -> bool:
    return (0x0621 <= cp <= 0x063A) or (0x0641 <= cp <= 0x064A)


def _is_transparent(cp: int) -> bool:
    return cp == 0x0640 or (0x064B <= cp <= 0x065F)


# D-type: can extend a connection to the NEXT letter
def _joins_right(cp: int) -> bool:
    return _is_arabic_letter(cp) and cp != 0x0621 and cp not in _RIGHT_JOINING


# D-type or R-type: can accept a connection from the PREVIOUS letter
def _joins_left(cp: int) -> bool:
    return _is_arabic_letter(cp) and cp != 0x0621


def _prev_arabic(cps: list[int], i: int) -> int | None:
    for j in range(i - 1, -1, -1):
        if _is_transparent(cps[j]):
            continue
        return cps[j] if _is_arabic_letter(cps[j]) else None
    return None


def _next_arabic(cps: list[int], i: int) -> int | None:
    for j in range(i + 1, len(cps)):
        if _is_transparent(cps[j]):
            continue
        return cps[j] if _is_arabic_letter(cps[j]) else None
    return None


def _next_arabic_index(cps: list[int], i: int) -> int | None:
    for j in range(i + 1, len(cps)):
        if _is_transparent(cps[j]):
            continue
        return j if _is_arabic_letter(cps[j]) else None
    return None


def reshape(text: str, *, use_lam_alef_ligatures: bool = False) -> str:
    if not text:
        return text
    cps = [ord(ch) for ch in text]
    skipped: set[int] = set()
    parts: list[str] = []

    for i, cp in enumerate(cps):
        if i in skipped:
            continue

        if _is_transparent(cp) or not _is_arabic_letter(cp):
            parts.append(chr(cp))
            continue

        forms = _FORMS.get(cp)
        if forms is None:
            parts.append(chr(cp))
            continue

        # Hamza — U-type: always isolated
        if cp == 0x0621:
            parts.append(chr(forms[_ISO]))
            continue

        # Lam-alef ligature check
        if use_lam_alef_ligatures and cp == 0x0644:
            next_idx = _next_arabic_index(cps, i)
            if next_idx is not None:
                lig = _LAM_ALEF_FORMS.get(cps[next_idx])
                if lig is not None:
                    prev = _prev_arabic(cps, i)
                    prev_jr = prev is not None and _joins_right(prev)
                    parts.append(chr(lig[1] if prev_jr else lig[0]))
                    # Preserve any transparent chars between lam and alef
                    for j in range(i + 1, next_idx):
                        parts.append(chr(cps[j]))
                    skipped.add(next_idx)
                    continue

        # Normal contextual form selection
        prev = _prev_arabic(cps, i)
        nxt = _next_arabic(cps, i)
        prev_jr = prev is not None and _joins_right(prev)
        next_jl = nxt is not None and _joins_left(nxt)
        self_jr = _joins_right(cp)
        self_jl = _joins_left(cp)

        if prev_jr and self_jl and self_jr and next_jl:
            idx = _MED
        elif prev_jr and self_jl and not (self_jr and next_jl):
            idx = _FIN
        elif not prev_jr and self_jr and next_jl:
            idx = _INI
        else:
            idx = _ISO

        form_cp = forms[idx]
        parts.append(chr(form_cp if form_cp != 0 else cp))

    return ''.join(parts)
