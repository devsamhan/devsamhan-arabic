"""Arabic text normalization functions — devsamhan-arabic spec v1.0.0."""

import re

SPEC_VERSION = "1.0.0"

# U+064B–U+065F, U+0610–U+061A, U+06D6–U+06DC, U+06DF–U+06ED
_TASHKEEL_RE = re.compile(
    "[ً-ٟؐ-ؚۖ-ۜ۟-ۭ]"
)

# U+0640 tatweel, but not before U+0670 superscript alef (Quranic annotation)
_TATWEEL_RE = re.compile("ـ(?!ٰ)")

_DIGITS_TO_WESTERN_RE = re.compile("[٠-٩۰-۹]")
_DIGITS_TO_EASTERN_RE = re.compile("[0-9]")

_ARABIC_RE = re.compile("[؀-ۿ]")


def remove_tashkeel(text: str) -> str:
    return _TASHKEEL_RE.sub("", text)


def remove_tatweel(text: str) -> str:
    return _TATWEEL_RE.sub("", text)


def normalize_alef(text: str) -> str:
    return (
        text
        .replace("أ", "ا")  # أ → ا
        .replace("إ", "ا")  # إ → ا
        .replace("آ", "ا")  # آ → ا
        .replace("ٱ", "ا")  # ٱ → ا
    )


def normalize_hamza(text: str) -> str:
    return (
        text
        .replace("ؤ", "ء")  # ؤ → ء
        .replace("ئ", "ء")  # ئ → ء
    )


def normalize_ya(text: str) -> str:
    return (
        text
        .replace("ى", "ي")  # ى → ي
        .replace("ی", "ي")  # ی → ي
    )


def normalize_ta_marbouta(text: str) -> str:
    return text.replace("ة", "ه")  # ة → ه


def normalize_digits(text: str, to: str) -> str:
    if to == "western":
        def _to_western(m: re.Match) -> str:
            cp = ord(m.group())
            base = 0x0660 if cp <= 0x0669 else 0x06F0
            return chr(0x30 + (cp - base))
        return _DIGITS_TO_WESTERN_RE.sub(_to_western, text)
    else:
        return _DIGITS_TO_EASTERN_RE.sub(
            lambda m: chr(0x0660 + ord(m.group()) - 0x30), text
        )


def normalize_presentation_forms(text: str) -> str:
    if not text:
        return text
    return "".join(
        _PRESENTATION_FORMS_MAP.get(ord(ch), ch) for ch in text
    )


def is_arabic(text: str) -> bool:
    return bool(_ARABIC_RE.search(text))


def arabic_ratio(text: str) -> float:
    if not text:
        return 0.0
    count = sum(1 for ch in text if 0x0600 <= ord(ch) <= 0x06FF)
    return count / len(text)


# ── Presentation Forms Map ────────────────────────────────────────────────────
# Arabic Presentation Forms-B (U+FE70–U+FEFC) and Forms-A (U+FB50–U+FBFF)
_PRESENTATION_FORMS_MAP: dict[int, str] = {
    # Presentation Forms-B
    0xFE70: " ً", 0xFE71: "ـً",
    0xFE72: " ٌ",
    0xFE74: " ٍ",
    0xFE76: " َ", 0xFE77: "ـَ",
    0xFE78: " ُ", 0xFE79: "ـُ",
    0xFE7A: " ِ", 0xFE7B: "ـِ",
    0xFE7C: " ّ", 0xFE7D: "ـّ",
    0xFE7E: " ْ", 0xFE7F: "ـْ",
    0xFE80: "ء",
    0xFE81: "آ", 0xFE82: "آ",
    0xFE83: "أ", 0xFE84: "أ",
    0xFE85: "ؤ", 0xFE86: "ؤ",
    0xFE87: "إ", 0xFE88: "إ",
    0xFE89: "ئ", 0xFE8A: "ئ", 0xFE8B: "ئ", 0xFE8C: "ئ",
    0xFE8D: "ا", 0xFE8E: "ا",
    0xFE8F: "ب", 0xFE90: "ب", 0xFE91: "ب", 0xFE92: "ب",
    0xFE93: "ة", 0xFE94: "ة",
    0xFE95: "ت", 0xFE96: "ت", 0xFE97: "ت", 0xFE98: "ت",
    0xFE99: "ث", 0xFE9A: "ث", 0xFE9B: "ث", 0xFE9C: "ث",
    0xFE9D: "ج", 0xFE9E: "ج", 0xFE9F: "ج", 0xFEA0: "ج",
    0xFEA1: "ح", 0xFEA2: "ح", 0xFEA3: "ح", 0xFEA4: "ح",
    0xFEA5: "خ", 0xFEA6: "خ", 0xFEA7: "خ", 0xFEA8: "خ",
    0xFEA9: "د", 0xFEAA: "د",
    0xFEAB: "ذ", 0xFEAC: "ذ",
    0xFEAD: "ر", 0xFEAE: "ر",
    0xFEAF: "ز", 0xFEB0: "ز",
    0xFEB1: "س", 0xFEB2: "س", 0xFEB3: "س", 0xFEB4: "س",
    0xFEB5: "ش", 0xFEB6: "ش", 0xFEB7: "ش", 0xFEB8: "ش",
    0xFEB9: "ص", 0xFEBA: "ص", 0xFEBB: "ص", 0xFEBC: "ص",
    0xFEBD: "ض", 0xFEBE: "ض", 0xFEBF: "ض", 0xFEC0: "ض",
    0xFEC1: "ط", 0xFEC2: "ط", 0xFEC3: "ط", 0xFEC4: "ط",
    0xFEC5: "ظ", 0xFEC6: "ظ", 0xFEC7: "ظ", 0xFEC8: "ظ",
    0xFEC9: "ع", 0xFECA: "ع", 0xFECB: "ع", 0xFECC: "ع",
    0xFECD: "غ", 0xFECE: "غ", 0xFECF: "غ", 0xFED0: "غ",
    0xFED1: "ف", 0xFED2: "ف", 0xFED3: "ف", 0xFED4: "ف",
    0xFED5: "ق", 0xFED6: "ق", 0xFED7: "ق", 0xFED8: "ق",
    0xFED9: "ك", 0xFEDA: "ك", 0xFEDB: "ك", 0xFEDC: "ك",
    0xFEDD: "ل", 0xFEDE: "ل", 0xFEDF: "ل", 0xFEE0: "ل",
    0xFEE1: "م", 0xFEE2: "م", 0xFEE3: "م", 0xFEE4: "م",
    0xFEE5: "ن", 0xFEE6: "ن", 0xFEE7: "ن", 0xFEE8: "ن",
    0xFEE9: "ه", 0xFEEA: "ه", 0xFEEB: "ه", 0xFEEC: "ه",
    0xFEED: "و", 0xFEEE: "و",
    0xFEEF: "ى", 0xFEF0: "ى",
    0xFEF1: "ي", 0xFEF2: "ي", 0xFEF3: "ي", 0xFEF4: "ي",
    0xFEF5: "لآ", 0xFEF6: "لآ",
    0xFEF7: "لأ", 0xFEF8: "لأ",
    0xFEF9: "لإ", 0xFEFA: "لإ",
    0xFEFB: "لا", 0xFEFC: "لا",
    # Presentation Forms-A
    0xFB50: "ٱ", 0xFB51: "ٱ",
    0xFB52: "ٻ", 0xFB53: "ٻ", 0xFB54: "ٻ", 0xFB55: "ٻ",
    0xFB56: "پ", 0xFB57: "پ", 0xFB58: "پ", 0xFB59: "پ",
    0xFB5A: "ڀ", 0xFB5B: "ڀ", 0xFB5C: "ڀ", 0xFB5D: "ڀ",
    0xFB5E: "ٺ", 0xFB5F: "ٺ", 0xFB60: "ٺ", 0xFB61: "ٺ",
    0xFB62: "ٿ", 0xFB63: "ٿ", 0xFB64: "ٿ", 0xFB65: "ٿ",
    0xFB66: "ٹ", 0xFB67: "ٹ", 0xFB68: "ٹ", 0xFB69: "ٹ",
    0xFB6A: "ڤ", 0xFB6B: "ڤ", 0xFB6C: "ڤ", 0xFB6D: "ڤ",
    0xFB6E: "ڦ", 0xFB6F: "ڦ", 0xFB70: "ڦ", 0xFB71: "ڦ",
    0xFB72: "ڄ", 0xFB73: "ڄ", 0xFB74: "ڄ", 0xFB75: "ڄ",
    0xFB76: "ڃ", 0xFB77: "ڃ", 0xFB78: "ڃ", 0xFB79: "ڃ",
    0xFB7A: "چ", 0xFB7B: "چ", 0xFB7C: "چ", 0xFB7D: "چ",
    0xFB7E: "ڇ", 0xFB7F: "ڇ", 0xFB80: "ڇ", 0xFB81: "ڇ",
    0xFB82: "ڍ", 0xFB83: "ڍ",
    0xFB84: "ڌ", 0xFB85: "ڌ",
    0xFB86: "ڎ", 0xFB87: "ڎ",
    0xFB88: "ڈ", 0xFB89: "ڈ",
    0xFB8A: "ژ", 0xFB8B: "ژ",
    0xFB8C: "ڑ", 0xFB8D: "ڑ",
    0xFB8E: "ک", 0xFB8F: "ک", 0xFB90: "ک", 0xFB91: "ک",
    0xFB92: "گ", 0xFB93: "گ", 0xFB94: "گ", 0xFB95: "گ",
    0xFB96: "ڳ", 0xFB97: "ڳ", 0xFB98: "ڳ", 0xFB99: "ڳ",
    0xFB9A: "ڱ", 0xFB9B: "ڱ", 0xFB9C: "ڱ", 0xFB9D: "ڱ",
    0xFB9E: "ں", 0xFB9F: "ں",
    0xFBA0: "ڻ", 0xFBA1: "ڻ", 0xFBA2: "ڻ", 0xFBA3: "ڻ",
    0xFBA4: "ۀ", 0xFBA5: "ۀ",
    0xFBA6: "ہ", 0xFBA7: "ہ", 0xFBA8: "ہ", 0xFBA9: "ہ",
    0xFBAA: "ھ", 0xFBAB: "ھ", 0xFBAC: "ھ", 0xFBAD: "ھ",
    0xFBAE: "ے", 0xFBAF: "ے",
    0xFBB0: "ۓ", 0xFBB1: "ۓ",
    0xFBD3: "ڭ", 0xFBD4: "ڭ", 0xFBD5: "ڭ", 0xFBD6: "ڭ",
    0xFBD7: "ۇ", 0xFBD8: "ۇ",
    0xFBD9: "ۆ", 0xFBDA: "ۆ",
    0xFBDB: "ۈ", 0xFBDC: "ۈ",
    0xFBDD: "ٷ",
    0xFBDE: "ۋ", 0xFBDF: "ۋ",
    0xFBE0: "ۅ", 0xFBE1: "ۅ",
    0xFBE2: "ۉ", 0xFBE3: "ۉ",
    0xFBE4: "ې", 0xFBE5: "ې", 0xFBE6: "ې", 0xFBE7: "ې",
    0xFBE8: "ى", 0xFBE9: "ى",
    0xFBEA: "ئا", 0xFBEB: "ئا",
    0xFBEC: "ئە", 0xFBED: "ئە",
    0xFBEE: "ئو", 0xFBEF: "ئو",
    0xFBF0: "ئۇ", 0xFBF1: "ئۇ",
    0xFBF2: "ئۆ", 0xFBF3: "ئۆ",
    0xFBF4: "ئۈ", 0xFBF5: "ئۈ",
    0xFBF6: "ئې", 0xFBF7: "ئې", 0xFBF8: "ئې",
    0xFBF9: "ئی", 0xFBFA: "ئی", 0xFBFB: "ئی",
    0xFBFC: "ی", 0xFBFD: "ی", 0xFBFE: "ی", 0xFBFF: "ی",
    # Special ligatures
    0xFDF2: "الله",  # الله
    0xFDFA: "صلى الله عليه وسلم",
    0xFDFB: "جل جلاله",
}
