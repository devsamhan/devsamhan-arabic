import 'dart:async';
import 'package:test/test.dart';
import 'package:arabic_bidi/arabic_bidi.dart';

// Runs [fn] inside a zone that captures the single print() line it emits.
String _capture(void Function() fn) {
  var line = '';
  runZoned(
    fn,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, s) => line = s,
    ),
  );
  return line;
}

void main() {
  group('default logger output format', () {
    test('info: contains [INFO] and prepared Arabic text', () {
      final out = _capture(() => arabicLogger.info('مرحبا'));
      expect(out, contains('[INFO]'));
      expect(out, contains(ArabicBidi.prepareForTerminal('مرحبا')));
    });

    test('error: contains [ERROR] and prepared Arabic text', () {
      final out = _capture(() => arabicLogger.error('خطأ في الاتصال'));
      expect(out, contains('[ERROR]'));
      expect(out, contains(ArabicBidi.prepareForTerminal('خطأ في الاتصال')));
    });

    test('warn: contains [WARN] and prepared Arabic text', () {
      final out = _capture(() => arabicLogger.warn('تحذير: الذاكرة ممتلئة'));
      expect(out, contains('[WARN]'));
      expect(out,
          contains(ArabicBidi.prepareForTerminal('تحذير: الذاكرة ممتلئة')));
    });

    test('debug: contains [DEBUG] and message text', () {
      final out = _capture(() => arabicLogger.debug('debug message here'));
      expect(out, contains('[DEBUG]'));
      expect(out, contains('debug message here'));
    });
  });

  group('custom prefix', () {
    test('prefix appears in output as [prefix]', () {
      final log = ArabicLogger(prefix: 'MyApp');
      final out = _capture(() => log.info('تم التشغيل'));
      expect(out, contains('[MyApp]'));
      expect(out, contains('[INFO]'));
    });

    test('prefix appears before level tag', () {
      final log = ArabicLogger(prefix: 'MyApp');
      final out = _capture(() => log.warn('تحذير'));
      // Format: [MyApp][WARN] ...
      expect(out.indexOf('[MyApp]'), lessThan(out.indexOf('[WARN]')));
    });

    test('prefix + level + prepared text all present', () {
      final log = ArabicLogger(prefix: 'MyApp');
      final out = _capture(() => log.info('تم التشغيل'));
      expect(out, contains(ArabicBidi.prepareForTerminal('تم التشغيل')));
    });
  });

  group('timestamp option', () {
    test('timestamp pattern present when useTimestamp: true', () {
      final log = ArabicLogger(useTimestamp: true);
      final out = _capture(() => log.info('رسالة'));
      expect(out, matches(RegExp(r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]')));
      expect(out, contains('[INFO]'));
    });

    test('timestamp appears before level tag', () {
      final log = ArabicLogger(useTimestamp: true);
      final out = _capture(() => log.info('رسالة'));
      final tsStart = out.indexOf(RegExp(r'\[\d{4}-'));
      final levelStart = out.indexOf('[INFO]');
      expect(tsStart, lessThan(levelStart));
    });

    test('no timestamp by default', () {
      final out = _capture(() => arabicLogger.info('رسالة'));
      expect(out, isNot(matches(RegExp(r'\[\d{4}-\d{2}-\d{2}'))));
    });

    test('timestamp + prefix + level ordering', () {
      final log = ArabicLogger(useTimestamp: true, prefix: 'App');
      final out = _capture(() => log.info('رسالة'));
      // Format: [yyyy-MM-dd HH:mm:ss][App][INFO] ...
      final tsStart = out.indexOf(RegExp(r'\[\d{4}-'));
      final prefixIdx = out.indexOf('[App]');
      final levelIdx = out.indexOf('[INFO]');
      expect(tsStart, lessThan(prefixIdx));
      expect(prefixIdx, lessThan(levelIdx));
    });
  });

  group('terminal options passthrough', () {
    test('reorder: false is respected — shaped text not reordered', () {
      const opts = ArabicTerminalOptions(reorder: false);
      final log = ArabicLogger(terminalOptions: opts);
      final out = _capture(() => log.info('نص عربي'));
      final expected = ArabicBidi.prepareForTerminal('نص عربي', options: opts);
      expect(out, contains(expected));
    });

    test('default options match ArabicBidi.prepareForTerminal defaults', () {
      final out = _capture(() => arabicLogger.info('السلام عليكم'));
      final expected = ArabicBidi.prepareForTerminal('السلام عليكم');
      expect(out, contains(expected));
    });
  });

  group('Latin text passthrough', () {
    test('Latin text passes through unchanged', () {
      final out =
          _capture(() => arabicLogger.info('Server started on port 3000'));
      expect(out, contains('Server started on port 3000'));
    });

    test('Latin characters are not reversed', () {
      final out =
          _capture(() => arabicLogger.info('Server started on port 3000'));
      expect(out, isNot(contains('0003 trop no detrats revreS')));
    });
  });

  group('mixed text', () {
    test('no crash on Arabic-dominant + Latin', () {
      expect(
        () => arabicLogger.info('Error: فشل الاتصال بالخادم'),
        returnsNormally,
      );
    });

    test('Latin word preserved in Arabic-dominant mixed output', () {
      final out =
          _capture(() => arabicLogger.info('Error: فشل الاتصال بالخادم'));
      expect(out, contains('Error'));
    });

    test('no crash on Arabic + filename', () {
      expect(
        () => arabicLogger.info('تم حفظ الملف: report.pdf'),
        returnsNormally,
      );
    });

    test('filename preserved in mixed output', () {
      final out = _capture(() => arabicLogger.info('تم حفظ الملف: report.pdf'));
      expect(out, contains('report.pdf'));
    });
  });
}
