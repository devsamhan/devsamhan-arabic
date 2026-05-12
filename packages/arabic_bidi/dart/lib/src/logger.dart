library;

import 'terminal.dart';

/// Arabic-aware terminal logger.
///
/// Applies [prepareForTerminal] to every message before printing.
/// Drop-in replacement for bare [print] calls in CLI and script environments.
///
/// Output format: `[timestamp?][prefix?][LEVEL] message`
class ArabicLogger {
  /// Optional label prepended to every line as `[prefix]`.
  final String? prefix;

  /// When true, prepends an ISO-8601 timestamp `[yyyy-MM-dd HH:mm:ss]`.
  final bool useTimestamp;

  /// Terminal preparation options applied to every message.
  final ArabicTerminalOptions terminalOptions;

  const ArabicLogger({
    this.prefix,
    this.useTimestamp = false,
    this.terminalOptions = const ArabicTerminalOptions(),
  });

  void info(String message) => _log('INFO', message);
  void error(String message) => _log('ERROR', message);
  void warn(String message) => _log('WARN', message);
  void debug(String message) => _log('DEBUG', message);

  void _log(String level, String message) {
    final prepared = prepareForTerminal(message, options: terminalOptions);
    final sb = StringBuffer();
    if (useTimestamp) {
      final now = DateTime.now();
      final y = now.year.toString().padLeft(4, '0');
      final mo = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      final h = now.hour.toString().padLeft(2, '0');
      final mi = now.minute.toString().padLeft(2, '0');
      final s = now.second.toString().padLeft(2, '0');
      sb.write('[$y-$mo-$d $h:$mi:$s]');
    }
    if (prefix != null) sb.write('[$prefix]');
    sb.write('[$level] $prepared');
    print(sb.toString());
  }
}

/// Ready-to-use default logger instance.
const arabicLogger = ArabicLogger();
