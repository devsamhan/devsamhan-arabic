import { describe, it, expect, vi, afterEach } from 'vitest';
import {
  reshape,
  detectDirection, Direction,
  prepareForTerminal,
  printArabic,
  ArabicLogger, arabicLogger,
} from '../src/index';

// Helpers — named constants for presentation form code points
const fcp = (...cps: number[]) => String.fromCodePoint(...cps);

// Isolated forms
const BA_ISO  = 0xFE8F, BA_INI  = 0xFE91, BA_MED  = 0xFE92, BA_FIN  = 0xFE90;
const NUN_FIN = 0xFEE6, NUN_MED = 0xFEE8;
const TA_FIN  = 0xFE96;
const ALEF_ISO = 0xFE8D, ALEF_FIN = 0xFE8E;
const RA_ISO   = 0xFEAD;
const WAW_ISO  = 0xFEED;
const YA_MED   = 0xFEF4, YA_INI  = 0xFEF3;
const LAM_INI  = 0xFEDF;
const RA_ISO_CP = 0xFEAD, QAF_INI = 0xFED7, MEEM_FIN = 0xFEE2;
const HAMZA_ISO = 0xFE80;
const LAM_ALEF_ISO = 0xFEFB, LAM_ALEF_FIN = 0xFEFC;
const LAM_MADDA_ISO = 0xFEF5;

// ── reshape ───────────────────────────────────────────────────────────────────

describe('reshape - basic', () => {
  it('empty string returns empty', () => {
    expect(reshape('')).toBe('');
  });

  it('Latin passes through unchanged', () => {
    expect(reshape('Hello World')).toBe('Hello World');
  });

  it('ASCII digits pass through unchanged', () => {
    expect(reshape('123')).toBe('123');
  });
});

describe('reshape - isolated forms', () => {
  it('hamza (U-type) -> isolated form U+FE80', () => {
    // hamza has no joining; always emits isolated form
    expect(reshape('ء')).toBe(fcp(HAMZA_ISO));
  });

  it('ba alone -> isolated form U+FE8F', () => {
    expect(reshape('ب')).toBe(fcp(BA_ISO));
  });
});

describe('reshape - initial form', () => {
  // ba(D) + nun(D): ba has no prev, next=nun joinsLeft -> initial; nun has prev=ba joinsRight, next=none -> final
  it('ba+nun: initial+final', () => {
    expect(reshape('بن')).toBe(fcp(BA_INI, NUN_FIN));
  });
});

describe('reshape - medial form', () => {
  // ba(D)+nun(D)+ta(D): ba->initial, nun->medial (both neighbours join), ta->final
  it('ba+nun+ta: initial+medial+final', () => {
    expect(reshape('بنت')).toBe(fcp(BA_INI, NUN_MED, TA_FIN));
  });
});

describe('reshape - R-type letters break chain', () => {
  // ba(D)+alef(R)+ra(R):
  //   ba -> initial (next=alef joinsLeft=true)
  //   alef -> final (prev=ba joinsRight=true; alef joinsRight=false so it cannot extend)
  //   ra -> isolated (prev=alef joinsRight=false, ra joinsRight=false -> not initial)
  it('ba+alef+ra: R-type letters do not extend the join rightward', () => {
    expect(reshape('بار')).toBe(fcp(BA_INI, ALEF_FIN, RA_ISO));
  });

  // waw(R)+alef(R): neither has a D-type predecessor to make it final/initial
  it('waw+alef: both R-type -> both isolated', () => {
    expect(reshape('وا')).toBe(fcp(WAW_ISO, ALEF_ISO));
  });
});

describe('reshape - transparent characters', () => {
  // ba + fatha(U+064E) + ya + ta: fatha is tashkeel, transparent
  // ba sees ya as next -> initial; ya sees ba as prev -> medial; ta -> final
  it('fatha (tashkeel U+064E) is transparent for joining, preserved in output', () => {
    expect(reshape('بَيت')).toBe(fcp(BA_INI, 0x064E, YA_MED, TA_FIN));
  });

  // ba + tatweel(U+0640) + ya + ta: same but tatweel
  it('tatweel (U+0640) is transparent for joining, preserved in output', () => {
    expect(reshape('بـيت')).toBe(fcp(BA_INI, 0x0640, YA_MED, TA_FIN));
  });
});

describe('reshape - lam-alef ligatures', () => {
  // lam+alef without option: lam->initial (next=alef joinsLeft), alef->final
  it('lam+alef default: no ligature, normal contextual forms', () => {
    expect(reshape('لا')).toBe(fcp(LAM_INI, ALEF_FIN));
  });

  // lam+alef with opt-in: isolated lam-alef ligature (U+FEFB)
  it('lam+alef with useLamAlefLigatures: isolated ligature U+FEFB', () => {
    expect(reshape('لا', { useLamAlefLigatures: true })).toBe(fcp(LAM_ALEF_ISO));
  });

  // ba+lam+alef: ba->initial; lam has prev=ba(joinsRight) -> use final lam-alef ligature (U+FEFC)
  it('ba+lam+alef with useLamAlefLigatures: ba-initial + final ligature U+FEFC', () => {
    expect(reshape('بلا', { useLamAlefLigatures: true })).toBe(fcp(BA_INI, LAM_ALEF_FIN));
  });

  // lam+alef-madda: isolated lam+alef-madda ligature (U+FEF5)
  it('lam+alef-madda with useLamAlefLigatures: isolated ligature U+FEF5', () => {
    expect(reshape('لآ', { useLamAlefLigatures: true })).toBe(fcp(LAM_MADDA_ISO));
  });
});

// ── detectDirection ───────────────────────────────────────────────────────────

describe('detectDirection', () => {
  it('empty string -> LTR', () => {
    expect(detectDirection('')).toBe(Direction.LTR);
  });

  it('pure Arabic text -> RTL (Arabic-block >= 80% of arabic+latin)', () => {
    // all 5 chars are Arabic-block, 0 Latin -> 100% -> RTL
    expect(detectDirection('مرحبا')).toBe(Direction.RTL);
  });

  it('pure Latin text -> LTR (Latin >= 80% of arabic+latin)', () => {
    expect(detectDirection('Hello')).toBe(Direction.LTR);
  });

  it('digits-only -> LTR (digits not counted as Arabic or Latin)', () => {
    expect(detectDirection('12345')).toBe(Direction.LTR);
  });

  it('equal Arabic and Latin -> MIXED (neither >= 80%)', () => {
    // 'Hello مرحبا': 5 Latin + 5 Arabic-block
    expect(detectDirection('Hello مرحبا')).toBe(Direction.MIXED);
  });

  it('50/50 split -> MIXED', () => {
    // 'ab مر': 2 Latin, 2 Arabic-block
    expect(detectDirection('ab مر')).toBe(Direction.MIXED);
  });

  it('Arabic >= 80% with small Latin minority -> RTL', () => {
    // 'السلام a': 6 Arabic-block + 1 Latin -> 6/7 >= 0.8 -> RTL
    expect(detectDirection('السلام a')).toBe(Direction.RTL);
  });
});

// ── prepareForTerminal ────────────────────────────────────────────────────────

describe('prepareForTerminal - Arabic-only text', () => {
  it('empty string -> empty', () => {
    expect(prepareForTerminal('')).toBe('');
  });

  it('pure Arabic: reshaped correctly (single run, reorder has no effect)', () => {
    // 'بيت' = ba+ya+ta (house)
    // arabicRatio = 1.0 > 0.5 -> reorder (but single run stays same)
    // reshape: ba-ini(FE91) + ya-med(FEF4) + ta-fin(FE96)
    expect(prepareForTerminal('بيت')).toBe(fcp(0xFE91, 0xFEF4, 0xFE96));
  });
});

describe('prepareForTerminal - mixed Arabic+Latin', () => {
  it('Arabic-dominant text: Latin run moves to front after reorder', () => {
    // 'السلام عليكم Hello'
    // 11 Arabic-block / 18 total = 0.61 > 0.5 -> reorder
    // reversed runs: Latin('Hello') + space + Arabic(reshaped) + space + Arabic(reshaped)
    const result = prepareForTerminal('السلام عليكم Hello');
    expect(result.startsWith('Hello')).toBe(true);
    // Arabic presentation-form chars present (U+FE70-U+FEFF range)
    expect(/[ﹰ-﻿]/.test(result)).toBe(true);
  });

  it('Latin-dominant text: run order unchanged', () => {
    // 'Hello ب': 1 Arabic-block / 8 total = 0.125 -> no reorder
    const result = prepareForTerminal('Hello ب');
    expect(result.startsWith('Hello')).toBe(true);
  });
});

describe('prepareForTerminal - digits and arabicLetterRatio', () => {
  it('Eastern Arabic digits NOT counted as letters: ratio 3/6=0.5 -> no reorder', () => {
    // 'رقم ١٢٣': 3 Arabic letters, 3 Eastern Arabic digits (not letters), 1 space
    // arabicLetterRatio = 3 letters / 6 non-ws = 0.5 — NOT > 0.5 -> no reorder
    // reshape 'رقم': ra-iso(FEAD) + qaf-ini(FED7) + meem-fin(FEE2)
    // result: reshaped-raqm + space + digits (original order)
    const expected = fcp(RA_ISO_CP, QAF_INI, MEEM_FIN, 0x20, 0x0661, 0x0662, 0x0663);
    expect(prepareForTerminal('رقم ١٢٣')).toBe(expected);
  });

  it('Persian digits NOT counted as letters: no reorder', () => {
    // 'رقم ۱۲۳': same structure with Persian digits U+06F1–U+06F3
    const result = prepareForTerminal('رقم ۱۲۳');
    // word comes first (no reorder), digits at end
    expect(result.endsWith('۱۲۳')).toBe(true);
  });

  it('ASCII digits are NumberRun: not counted as letters, no reorder', () => {
    // 'رقم 123': arabicLetterRatio = 3/6 = 0.5 -> no reorder
    const result = prepareForTerminal('رقم 123');
    expect(result.endsWith('123')).toBe(true);
  });

  it('Arabic-dominant text with ratio > 0.5 still reorders', () => {
    // 'السلام عليكم': 11 letters / 11 non-ws = 1.0 > 0.5 -> reorder
    // Result starts with last run reversed to front
    const result = prepareForTerminal('السلام Hello');
    expect(result.startsWith('Hello')).toBe(true);
  });

  it('50/50 text (ratio = 0.5) does NOT reorder', () => {
    // 3 Arabic letters + 3 Latin letters, no spaces: ratio = 3/6 = 0.5 -> no reorder
    // 'بنت' (3 Arabic) + 'abc' (3 Latin): first run is Arabic
    const result = prepareForTerminal('بنتabc');
    // Arabic run stays first (not reversed)
    expect(result.endsWith('abc')).toBe(true);
  });
});

describe('prepareForTerminal - options', () => {
  it('reshape: false -> Arabic not converted to presentation forms', () => {
    expect(prepareForTerminal('بيت', { reshape: false })).toBe('بيت');
  });

  it('reorder: false -> run order unchanged for Arabic-dominant text', () => {
    // Arabic still gets reshaped, but runs stay in original order
    const result = prepareForTerminal('السلام Hello', { reorder: false });
    // Arabic run comes first (not moved to end)
    expect(/^[ﹰ-﻿]/.test(result)).toBe(true);
  });
});

// ── ArabicLogger ──────────────────────────────────────────────────────────────

describe('ArabicLogger', () => {
  afterEach(() => vi.restoreAllMocks());

  it('info: [INFO] level label', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    arabicLogger.info('Hello');
    expect(spy).toHaveBeenCalledWith('[INFO] Hello');
  });

  it('error: [ERROR] level label', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    arabicLogger.error('boom');
    expect(spy).toHaveBeenCalledWith('[ERROR] boom');
  });

  it('warn: [WARN] level label', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    arabicLogger.warn('caution');
    expect(spy).toHaveBeenCalledWith('[WARN] caution');
  });

  it('debug: [DEBUG] level label', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    arabicLogger.debug('trace');
    expect(spy).toHaveBeenCalledWith('[DEBUG] trace');
  });

  it('prefix: [prefix][LEVEL] message', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    new ArabicLogger({ prefix: 'app' }).info('started');
    expect(spy).toHaveBeenCalledWith('[app][INFO] started');
  });

  it('useTimestamp: output starts with [YYYY-MM-DD HH:MM:SS]', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    new ArabicLogger({ useTimestamp: true }).info('x');
    expect(spy.mock.calls[0][0]).toMatch(/^\[20\d{2}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/);
  });

  it('prefix + timestamp: timestamp then prefix then level', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    new ArabicLogger({ prefix: 'srv', useTimestamp: true }).warn('down');
    expect(spy.mock.calls[0][0]).toMatch(/^\[20\d{2}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]\[srv\]\[WARN\] down$/);
  });

  it('Arabic message is reshaped before output', () => {
    // ba+ya+ta reshaped: BA_INI(FE91) + YA_MED(FEF4) + TA_FIN(FE96)
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    arabicLogger.info('بيت');
    expect(spy).toHaveBeenCalledWith('[INFO] ' + fcp(0xFE91, 0xFEF4, 0xFE96));
  });

  it('printArabic calls console.log with prepared text', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    printArabic('بيت');
    expect(spy).toHaveBeenCalledWith(fcp(0xFE91, 0xFEF4, 0xFE96));
  });
});
