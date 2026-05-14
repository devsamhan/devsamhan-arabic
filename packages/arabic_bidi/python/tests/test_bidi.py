"""Tests for devsamhan-arabic-bidi — mirrors the TypeScript bidi.test.ts suite."""
import re
from io import StringIO
from unittest.mock import patch

import pytest

from devsamhan_arabic_bidi import (
    ArabicLogger,
    arabic_logger,
    detect_direction,
    prepare_for_terminal,
    print_arabic,
    reshape,
)

# Helpers — named constants for presentation-form code points
def fcp(*cps: int) -> str:
    return ''.join(chr(cp) for cp in cps)


# Isolated forms
BA_ISO   = 0xFE8F; BA_INI  = 0xFE91; BA_MED  = 0xFE92; BA_FIN  = 0xFE90
NUN_FIN  = 0xFEE6; NUN_MED = 0xFEE8
TA_FIN   = 0xFE96
ALEF_ISO = 0xFE8D; ALEF_FIN = 0xFE8E
RA_ISO   = 0xFEAD
WAW_ISO  = 0xFEED
YA_MED   = 0xFEF4; YA_INI  = 0xFEF3
LAM_INI  = 0xFEDF
QAF_INI  = 0xFED7; MEEM_FIN = 0xFEE2
HAMZA_ISO = 0xFE80
LAM_ALEF_ISO = 0xFEFB; LAM_ALEF_FIN = 0xFEFC
LAM_MADDA_ISO = 0xFEF5


# ── reshape — basic ───────────────────────────────────────────────────────────

def test_reshape_empty():
    assert reshape('') == ''

def test_reshape_latin_passthrough():
    assert reshape('Hello World') == 'Hello World'

def test_reshape_digits_passthrough():
    assert reshape('123') == '123'


# ── reshape — isolated forms ──────────────────────────────────────────────────

def test_reshape_hamza_isolated():
    # hamza U-type: always isolated
    assert reshape('ء') == fcp(HAMZA_ISO)

def test_reshape_ba_alone_isolated():
    assert reshape('ب') == fcp(BA_ISO)


# ── reshape — initial form ────────────────────────────────────────────────────

def test_reshape_ba_nun_initial_final():
    # ba(D)+nun(D): ba→initial, nun→final
    assert reshape('بن') == fcp(BA_INI, NUN_FIN)


# ── reshape — medial form ─────────────────────────────────────────────────────

def test_reshape_ba_nun_ta_medial():
    # ba(D)+nun(D)+ta(D): ba→initial, nun→medial, ta→final
    assert reshape('بنت') == fcp(BA_INI, NUN_MED, TA_FIN)


# ── reshape — R-type letters break chain ─────────────────────────────────────

def test_reshape_r_type_breaks_chain():
    # ba(D)+alef(R)+ra(R): ba→initial, alef→final, ra→isolated
    assert reshape('بار') == fcp(BA_INI, ALEF_FIN, RA_ISO)

def test_reshape_two_r_type_both_isolated():
    # waw(R)+alef(R): no D-type predecessor → both isolated
    assert reshape('وا') == fcp(WAW_ISO, ALEF_ISO)


# ── reshape — transparent characters ─────────────────────────────────────────

def test_reshape_tashkeel_transparent():
    # ba + fatha(U+064E) + ya + ta: fatha is transparent
    # ba→initial, ya→medial (sees ba through fatha), ta→final
    assert reshape('بَيت') == fcp(BA_INI, 0x064E, YA_MED, TA_FIN)

def test_reshape_tatweel_transparent():
    # ba + tatweel(U+0640) + ya + ta
    assert reshape('بـيت') == fcp(BA_INI, 0x0640, YA_MED, TA_FIN)


# ── reshape — lam-alef ligatures ─────────────────────────────────────────────

def test_reshape_lam_alef_no_ligature_default():
    # lam+alef without option: lam→initial, alef→final
    assert reshape('لا') == fcp(LAM_INI, ALEF_FIN)

def test_reshape_lam_alef_isolated_ligature():
    # lam+alef with opt-in: isolated ligature U+FEFB
    assert reshape('لا', use_lam_alef_ligatures=True) == fcp(LAM_ALEF_ISO)

def test_reshape_ba_lam_alef_final_ligature():
    # ba+lam+alef: ba→initial; lam has prev=ba(joinsRight) → final lam-alef (U+FEFC)
    assert reshape('بلا', use_lam_alef_ligatures=True) == fcp(BA_INI, LAM_ALEF_FIN)

def test_reshape_lam_alef_madda_isolated_ligature():
    # lam+alef-madda: isolated ligature U+FEF5
    assert reshape('لآ', use_lam_alef_ligatures=True) == fcp(LAM_MADDA_ISO)


# ── detect_direction ──────────────────────────────────────────────────────────

def test_detect_direction_empty():
    assert detect_direction('') == 'ltr'

def test_detect_direction_pure_arabic():
    # all 5 chars Arabic-block → 100% → rtl
    assert detect_direction('مرحبا') == 'rtl'

def test_detect_direction_pure_latin():
    assert detect_direction('Hello') == 'ltr'

def test_detect_direction_digits_only():
    # digits not counted as Arabic or Latin → ltr
    assert detect_direction('12345') == 'ltr'

def test_detect_direction_equal_mixed():
    # 'Hello مرحبا': 5 Latin + 5 Arabic-block → mixed
    assert detect_direction('Hello مرحبا') == 'mixed'

def test_detect_direction_50_50():
    # 'ab مر': 2 Latin, 2 Arabic-block → mixed
    assert detect_direction('ab مر') == 'mixed'

def test_detect_direction_arabic_dominant():
    # 'السلام a': 6 Arabic-block + 1 Latin = 6/7 ≥ 0.8 → rtl
    assert detect_direction('السلام a') == 'rtl'


# ── prepare_for_terminal — Arabic-only ───────────────────────────────────────

def test_prepare_empty():
    assert prepare_for_terminal('') == ''

def test_prepare_pure_arabic_reshaped():
    # 'بيت': ba-ini(FE91) + ya-med(FEF4) + ta-fin(FE96)
    assert prepare_for_terminal('بيت') == fcp(0xFE91, 0xFEF4, 0xFE96)


# ── prepare_for_terminal — mixed ──────────────────────────────────────────────

def test_prepare_arabic_dominant_latin_moves_front():
    # 'السلام عليكم Hello': 11 Arabic letters / 16 non-ws = 0.6875 > 0.5 → reorder
    result = prepare_for_terminal('السلام عليكم Hello')
    assert result.startswith('Hello')
    # Arabic presentation-form chars present (U+FE70–U+FEFF)
    assert any(0xFE70 <= ord(ch) <= 0xFEFF for ch in result)

def test_prepare_latin_dominant_order_unchanged():
    # 'Hello ب': 1 Arabic letter / 7 non-ws = 0.143 → no reorder
    result = prepare_for_terminal('Hello ب')
    assert result.startswith('Hello')


# ── prepare_for_terminal — digits ─────────────────────────────────────────────

def test_prepare_eastern_arabic_digits_python_no_reorder():
    # Python-specific: 'رقم ١٢٣'
    # _arabic_letter_ratio = 3 letters / 6 non-ws = 0.5 — NOT > 0.5 → no reorder
    # reshape 'رقم': ra-iso(FEAD) + qaf-ini(FED7) + meem-fin(FEE2)
    expected = fcp(RA_ISO, QAF_INI, MEEM_FIN, 0x20, 0x0661, 0x0662, 0x0663)
    assert prepare_for_terminal('رقم ١٢٣') == expected

def test_prepare_ascii_digits_no_reorder():
    # 'رقم 123': arabic_letter_ratio = 3/6 = 0.5 → no reorder; '123' stays at end
    result = prepare_for_terminal('رقم 123')
    assert '123' in result
    assert result.endswith('123')


# ── prepare_for_terminal — options ────────────────────────────────────────────

def test_prepare_no_reshape():
    # reshape=False: Arabic not converted to presentation forms
    assert prepare_for_terminal('بيت', do_reshape=False) == 'بيت'

def test_prepare_no_reorder():
    # reorder=False: Arabic-dominant text still gets reshaped but runs stay in order
    result = prepare_for_terminal('السلام Hello', reorder=False)
    # Arabic run is first (not moved)
    assert ord(result[0]) >= 0xFE70


# ── ArabicLogger ──────────────────────────────────────────────────────────────

def test_logger_info():
    with patch('builtins.print') as mock_print:
        arabic_logger.info('Hello')
        mock_print.assert_called_once_with('[INFO] Hello')

def test_logger_error():
    with patch('builtins.print') as mock_print:
        arabic_logger.error('boom')
        mock_print.assert_called_once_with('[ERROR] boom')

def test_logger_warn():
    with patch('builtins.print') as mock_print:
        arabic_logger.warn('caution')
        mock_print.assert_called_once_with('[WARN] caution')

def test_logger_debug():
    with patch('builtins.print') as mock_print:
        arabic_logger.debug('trace')
        mock_print.assert_called_once_with('[DEBUG] trace')

def test_logger_prefix():
    with patch('builtins.print') as mock_print:
        ArabicLogger(prefix='app').info('started')
        mock_print.assert_called_once_with('[app][INFO] started')

def test_logger_timestamp_format():
    with patch('builtins.print') as mock_print:
        ArabicLogger(use_timestamp=True).info('x')
        output = mock_print.call_args[0][0]
        assert re.match(r'^\[20\d{2}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]', output)

def test_logger_prefix_and_timestamp():
    with patch('builtins.print') as mock_print:
        ArabicLogger(prefix='srv', use_timestamp=True).warn('down')
        output = mock_print.call_args[0][0]
        assert re.match(
            r'^\[20\d{2}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]\[srv\]\[WARN\] down$',
            output,
        )

def test_logger_arabic_message_reshaped():
    # 'بيت' reshaped: BA_INI(FE91) + YA_MED(FEF4) + TA_FIN(FE96)
    with patch('builtins.print') as mock_print:
        arabic_logger.info('بيت')
        expected = '[INFO] ' + fcp(0xFE91, 0xFEF4, 0xFE96)
        mock_print.assert_called_once_with(expected)

def test_print_arabic():
    with patch('builtins.print') as mock_print:
        print_arabic('بيت')
        mock_print.assert_called_once_with(fcp(0xFE91, 0xFEF4, 0xFE96))
