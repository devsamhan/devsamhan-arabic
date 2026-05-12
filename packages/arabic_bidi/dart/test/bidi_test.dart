import 'package:test/test.dart';
import 'package:arabic_bidi/arabic_bidi.dart';

// Expected values are written as Unicode escape sequences so the intent is
// unambiguous regardless of editor font/direction.
//
// Quick form-index reference per Presentation Forms-B layout:
//   [iso, fin, ini, med]  ← index order in the _forms map
//
// Selected letter lookups:
//   ء  0x0621 → iso=FE80  (U-type, no connecting forms)
//   آ  0x0622 → iso=FE81  fin=FE82
//   أ  0x0623 → iso=FE83  fin=FE84
//   ؤ  0x0624 → iso=FE85  fin=FE86  (R-type)
//   إ  0x0625 → iso=FE87  fin=FE88
//   ا  0x0627 → iso=FE8D  fin=FE8E  (R-type)
//   ب  0x0628 → iso=FE8F  fin=FE90  ini=FE91  med=FE92
//   ت  0x062A → iso=FE95  fin=FE96  ini=FE97  med=FE98
//   ح  0x062D → iso=FEA1  fin=FEA2  ini=FEA3  med=FEA4
//   د  0x062F → iso=FEA9  fin=FEAA  (R-type)
//   ذ  0x0630 → iso=FEAB  fin=FEAC  (R-type)
//   ر  0x0631 → iso=FEAD  fin=FEAE  (R-type)
//   ز  0x0632 → iso=FEAF  fin=FEB0  (R-type)
//   س  0x0633 → iso=FEB1  fin=FEB2  ini=FEB3  med=FEB4
//   ش  0x0634 → iso=FEB5  fin=FEB6  ini=FEB7  med=FEB8
//   ف  0x0641 → iso=FED1  fin=FED2  ini=FED3  med=FED4
//   ق  0x0642 → iso=FED5  fin=FED6  ini=FED7  med=FED8
//   ك  0x0643 → iso=FED9  fin=FEDA  ini=FEDB  med=FEDC
//   ل  0x0644 → iso=FEDD  fin=FEDE  ini=FEDF  med=FEE0
//   م  0x0645 → iso=FEE1  fin=FEE2  ini=FEE3  med=FEE4
//   ن  0x0646 → iso=FEE5  fin=FEE6  ini=FEE7  med=FEE8
//   ه  0x0647 → iso=FEE9  fin=FEEA  ini=FEEB  med=FEEC
//   و  0x0648 → iso=FEED  fin=FEEE  (R-type)
//   ي  0x064A → iso=FEF1  fin=FEF2  ini=FEF3  med=FEF4

void main() {
  // ── Isolated forms ────────────────────────────────────────────────────────

  group('reshape — isolated', () {
    test('empty string', () => expect(ArabicBidi.reshape(''), equals('')));

    test('single letter م: isolated', () {
      // م (D-type): no neighbours → isolated = FEE1
      expect(ArabicBidi.reshape('م'), equals('ﻡ'));
    });

    test('ء: always isolated (U-type, no connecting forms)', () {
      expect(ArabicBidi.reshape('ء'), equals('ﺀ'));
    });

    test('اد: two R-type letters — both isolated', () {
      // ا(R) cannot extend to د; د preceding is ا(R, joinsRight=F) → no chain
      // ا iso=FE8D, د iso=FEA9
      expect(ArabicBidi.reshape('اد'), equals('ﺍﺩ'));
    });

    test('ورد (rose): all R-type — all isolated', () {
      // و iso=FEED, ر iso=FEAD, د iso=FEA9
      expect(ArabicBidi.reshape('ورد'), equals('ﻭﺭﺩ'));
    });

    test('دار (house): all R-type — all isolated', () {
      // د iso=FEA9, ا iso=FE8D, ر iso=FEAD
      expect(ArabicBidi.reshape('دار'), equals('ﺩﺍﺭ'));
    });

    test('آدم (Adam): R+R+D where D has no prev connector', () {
      // آ iso=FE81, د iso=FEA9, م iso=FEE1
      // م: prev=د(joinsRight=F) → isolated
      expect(ArabicBidi.reshape('آدم'), equals('ﺁﺩﻡ'));
    });

    test('رؤوف (Raouf): R+R+R+D where all break the chain', () {
      // ر iso=FEAD, ؤ iso=FE85, و iso=FEED, ف iso=FED1
      // ف: prev=و(joinsRight=F) → isolated
      expect(ArabicBidi.reshape('رؤوف'), equals('ﺭﺅﻭﻑ'));
    });
  });

  // ── Final forms ───────────────────────────────────────────────────────────

  group('reshape — final', () {
    test('بر: D + R → initial + final', () {
      // ب ini=FE91, ر fin=FEAE
      expect(ArabicBidi.reshape('بر'), equals('ﺑﺮ'));
    });

    test('بت: D + D (no next) → initial + final', () {
      // ب ini=FE91, ت fin=FE96
      expect(ArabicBidi.reshape('بت'), equals('ﺑﺖ'));
    });

    test('زيد (Zayd): R + D + R → iso + ini + fin', () {
      // ز(R) iso=FEAF; ي(D) prev=ز(JR=F) → ini=FEF3; د(R) prev=ي(JR=T) → fin=FEAA
      expect(ArabicBidi.reshape('زيد'), equals('ﺯﻳﺪ'));
    });
  });

  // ── Medial forms ──────────────────────────────────────────────────────────

  group('reshape — medial', () {
    test('بيت (house): D + D + D → ini + med + fin', () {
      // ب ini=FE91, ي med=FEF4, ت fin=FE96
      expect(ArabicBidi.reshape('بيت'), equals('ﺑﻴﺖ'));
    });

    test('بيب: D + D + D → ini + med + fin', () {
      // ب ini=FE91, ي med=FEF4, ب fin=FE90
      expect(ArabicBidi.reshape('بيب'), equals('ﺑﻴﺐ'));
    });

    test('محمد (Muhammad): ini + med + med + fin', () {
      // م ini=FEE3, ح med=FEA4, م med=FEE4, د fin=FEAA
      // Third م: prev=ح(JR=T), next=د(JL=T) → medial (د is R-type but joinsLeft=T)
      expect(ArabicBidi.reshape('محمد'), equals('ﻣﺤﻤﺪ'));
    });

    test('سلام (peace): ini + med + fin + iso', () {
      // س ini=FEB3, ل med=FEE0 (next=ا JL=T), ا fin=FE8E, م iso=FEE1
      // م: prev=ا(JR=F) → isolated
      expect(ArabicBidi.reshape('سلام'), equals('ﺳﻠﺎﻡ'));
    });

    test('بنت (girl): ini + med + fin', () {
      // ب ini=FE91, ن med=FEE8, ت fin=FE96
      expect(ArabicBidi.reshape('بنت'), equals('ﺑﻨﺖ'));
    });
  });

  // ── Chain breaks (R-type in the middle) ───────────────────────────────────

  group('reshape — chain breaks', () {
    test('باب (door): ini + fin + iso', () {
      // ب ini=FE91; ا fin=FE8E; ب iso=FE8F (prev=ا JR=F → no chain)
      expect(ArabicBidi.reshape('باب'), equals('ﺑﺎﺏ'));
    });

    test('مرحبا: chain broken by ر', () {
      // م ini=FEE3; ر fin=FEAE (prev=م JR=T); ح ini=FEA3 (new chain after ر);
      // ب med=FE92; ا fin=FE8E
      expect(ArabicBidi.reshape('مرحبا'), equals('ﻣﺮﺣﺒﺎ'));
    });

    test('أمل (hope): R + D + D → iso + ini + fin', () {
      // أ iso=FE83; م ini=FEE3 (prev=أ JR=F → new chain); ل fin=FEDE
      expect(ArabicBidi.reshape('أمل'), equals('ﺃﻣﻞ'));
    });

    test('مسؤول: chain broken by ؤ and و', () {
      // م ini=FEE3, س med=FEB4, ؤ fin=FE86 (prev=س JR=T; ؤ R-type → fin)
      // و iso=FEED (prev=ؤ JR=F), ل iso=FEDD (prev=و JR=F)
      expect(ArabicBidi.reshape('مسؤول'), equals('ﻣﺴﺆﻭﻝ'));
    });
  });

  // ── ء (U-type) halts connections ──────────────────────────────────────────

  group('reshape — hamza and hamza-containing words', () {
    test('ء: isolated', () => expect(ArabicBidi.reshape('ء'), equals('ﺀ')));

    test('شيء (thing): D + D + U → ini + fin + iso', () {
      // ش ini=FEB7; ي: prev=ش(JR=T), next=ء(JL=F U-type) → fin=FEF2; ء iso=FE80
      expect(ArabicBidi.reshape('شيء'), equals('ﺷﻲﺀ'));
    });

    test('ماء (water): D + R + U → ini + fin + iso', () {
      // م ini=FEE3; ا fin=FE8E (prev=م JR=T); ء iso=FE80
      expect(ArabicBidi.reshape('ماء'), equals('ﻣﺎﺀ'));
    });
  });

  // ── Tashkeel and tatweel transparency ────────────────────────────────────

  group('reshape — transparent characters', () {
    test('tashkeel marks are preserved and transparent for joining', () {
      // مُحَمَّدٌ → same reshaping as محمد; tashkeel interspersed
      // م FEE3 + U+064F + ح FEA4 + U+064E + م FEE4 + U+064E + U+0651 + د FEAA
      expect(
        ArabicBidi.reshape('مُحَمَّدٌ'),
        equals('ﻣُﺤَﻤَّﺪٌ'),
      );
    });

    test('مُحَمَّد (without trailing tanwin): same reshaping as محمد', () {
      expect(
        ArabicBidi.reshape('مُحَمَّد'),
        equals('ﻣُﺤَﻤَّﺪ'),
      );
    });

    test('مـحـمـد (tatweels transparent): same letter forms as محمد', () {
      // Tatweels (U+0640) are preserved in output but skipped for joining context
      expect(
        ArabicBidi.reshape('مـحـمـد'),
        equals('ﻣـﺤـﻤـﺪ'),
      );
    });

    test('بـت (tatweel between D-type letters): ini + transparent + fin', () {
      // ب ini=FE91; U+0640 pass-through; ت fin=FE96
      expect(ArabicBidi.reshape('بـت'), equals('ﺑـﺖ'));
    });
  });

  // ── Non-Arabic passthrough ────────────────────────────────────────────────

  group('reshape — non-Arabic passthrough', () {
    test('empty string', () => expect(ArabicBidi.reshape(''), equals('')));

    test('pure Latin unchanged', () {
      expect(ArabicBidi.reshape('Hello World'), equals('Hello World'));
    });

    test('Arabic+Latin: only Arabic letters are reshaped', () {
      // مرحبا: م ini=FEE3, ر fin=FEAE, ح ini=FEA3, ب med=FE92, ا fin=FE8E
      expect(
        ArabicBidi.reshape('Hello مرحبا World'),
        equals('Hello ﻣﺮﺣﺒﺎ World'),
      );
    });

    test('كود Python: Arabic word followed by Latin', () {
      // ك ini=FEDB, و fin=FEEE, د iso=FEA9 (prev=و JR=F)
      expect(ArabicBidi.reshape('كود Python'), equals('ﻛﻮﺩ Python'));
    });

    test('رقم 123 هاتف: digits unchanged; Arabic words shaped independently',
        () {
      // رقم: ر iso=FEAD, ق ini=FED7, م fin=FEE2
      // هاتف: ه ini=FEEB, ا fin=FE8E, ت ini=FE97, ف fin=FED2
      expect(
        ArabicBidi.reshape('رقم 123 هاتف'),
        equals('ﺭﻗﻢ 123 ﻫﺎﺗﻒ'),
      );
    });

    test('digits pass through unchanged', () {
      expect(ArabicBidi.reshape('السعر ١٢٣'), contains('١٢٣'));
    });

    test('space between words restarts joining context', () {
      // من: م ini=FEE3, ن fin=FEE6
      // نحن: ن ini=FEE7, ح med=FEA4, ن fin=FEE6
      expect(ArabicBidi.reshape('من نحن'), equals('ﻣﻦ ﻧﺤﻦ'));
    });
  });

  // ── Full word suite from task spec ───────────────────────────────────────

  group('reshape — task word suite', () {
    test('لا (no): ل + ا → ini + fin (no ligature in default mode)', () {
      // ل ini=FEDF, ا fin=FE8E
      expect(ArabicBidi.reshape('لا'), equals('ﻟﺎ'));
    });

    test('السلام (as-salamu): ا + ل + س + ل + ا + م', () {
      // ا iso=FE8D; ل ini=FEDF; س med=FEB4; ل med=FEE0; ا fin=FE8E; م iso=FEE1
      expect(ArabicBidi.reshape('السلام'), equals('ﺍﻟﺴﻠﺎﻡ'));
    });
  });

  // ── Lam-alef ligatures (opt-in) ───────────────────────────────────────────

  group('reshape — lam-alef ligatures disabled (default)', () {
    test('لا: default mode → initial ل + final ا (no ligature)', () {
      expect(ArabicBidi.reshape('لا'), equals('ﻟﺎ'));
    });

    test('كلا: default mode → ini ك + med ل + fin ا', () {
      expect(ArabicBidi.reshape('كلا'), equals('ﻛﻠﺎ'));
    });
  });

  group('reshape — lam-alef ligatures enabled', () {
    const opts = ArabicReshapeOptions(useLamAlefLigatures: true);

    test('لا → isolated lam-alef ligature U+FEFB', () {
      expect(ArabicBidi.reshape('لا', options: opts), equals('ﻻ'));
    });

    test('لأ → isolated lam-alef-hamza-above U+FEF7', () {
      expect(ArabicBidi.reshape('لأ', options: opts), equals('ﻷ'));
    });

    test('لإ → isolated lam-alef-hamza-below U+FEF9', () {
      expect(ArabicBidi.reshape('لإ', options: opts), equals('ﻹ'));
    });

    test('لآ → isolated lam-alef-madda U+FEF5', () {
      expect(ArabicBidi.reshape('لآ', options: opts), equals('ﻵ'));
    });

    test('كلا → final ligature U+FEFC (lam preceded by connector)', () {
      // ك ini=FEDB; ل preceded by ك (joinsRight=T) → FEFC (final lam-alef)
      expect(ArabicBidi.reshape('كلا', options: opts), equals('ﻛﻼ'));
    });

    test('السلام: second لا → final ligature U+FEFC', () {
      // ا iso=FE8D; ل ini=FEDF (next=س, not alef); س med=FEB4;
      // ل + ا → FEFC (prev=س JR=T → final ligature); م iso=FEE1
      expect(
        ArabicBidi.reshape('السلام', options: opts),
        equals('ﺍﻟﺴﻼﻡ'),
      );
    });

    test('الا: first لا → isolated ligature (prev ا is R-type)', () {
      // ا iso=FE8D; ل ini (prev=ا JR=F) + ا → FEFB (isolated); no more chars
      expect(ArabicBidi.reshape('الا', options: opts), equals('ﺍﻻ'));
    });

    test('ligature option passed via ArabicBidi.reshape', () {
      expect(
        ArabicBidi.reshape('لا',
            options: const ArabicReshapeOptions(useLamAlefLigatures: true)),
        equals('ﻻ'),
      );
    });
  });

  // ── ArabicBidi facade ─────────────────────────────────────────────────────

  group('ArabicBidi facade', () {
    test('ArabicBidi.reshape returns correct shaped forms', () {
      expect(ArabicBidi.reshape('بيت'), equals('ﺑﻴﺖ'));
    });

    test('explicit ArabicReshapeOptions.defaults matches implicit defaults',
        () {
      expect(
        ArabicBidi.reshape('لا', options: ArabicReshapeOptions.defaults),
        equals(ArabicBidi.reshape('لا')),
      );
    });
  });

  // ── Direction detection ───────────────────────────────────────────────────

  group('detectDirection', () {
    test('pure Arabic → rtl', () {
      expect(ArabicBidi.detectDirection('مرحبا'), equals(Direction.rtl));
    });

    test('pure Latin → ltr', () {
      expect(ArabicBidi.detectDirection('Hello'), equals(Direction.ltr));
    });

    test('mixed Arabic+Latin → mixed', () {
      expect(
        ArabicBidi.detectDirection('Hello مرحبا World'),
        equals(Direction.mixed),
      );
    });

    test('empty string → ltr', () {
      expect(ArabicBidi.detectDirection(''), equals(Direction.ltr));
    });
  });
}
