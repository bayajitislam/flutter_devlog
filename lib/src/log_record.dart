import 'dev_log.dart';
import 'log_color.dart';
import 'log_level.dart';

/// A single structured log event, delivered to [DevLog.onLog].
///
/// The [message] is the raw text without any ANSI color codes, so sinks can
/// write it to files or crash reporters directly. Use [format] or [formatted]
/// when you want the same colored string that would appear on the console:
///
/// ```dart
/// DevLog.onLog = (record) {
///   myFile.writeln('[${record.name}] ${record.message}');
///   if (record.error != null) crashReporter.record(record.error!);
/// };
/// ```
class LogRecord {
  /// The level this record was logged at.
  final LogLevel level;

  /// The raw message text, without ANSI color codes or prefixes.
  final String message;

  /// The full channel name, e.g. `INFO` or `INFO/Auth`.
  final String name;

  /// The tag passed to the log call (or the scope of a [ScopedLogger]),
  /// if any.
  final String? tag;

  /// The error object passed to the log call, if any.
  final Object? error;

  /// The stack trace passed to the log call, if any.
  final StackTrace? stackTrace;

  /// When the record was created.
  final DateTime time;

  /// The caller's `file:line`, present only when [DevLog.includeSource] is on
  /// and the location could be resolved.
  final String? source;

  /// Creates a log record. Normally you don't construct these yourself;
  /// [DevLog] builds one for every emitted log.
  const LogRecord({
    required this.level,
    required this.message,
    required this.name,
    required this.time,
    this.tag,
    this.error,
    this.stackTrace,
    this.source,
  });

  /// Renders the record as a display string.
  ///
  /// When [colors] is `true` the text is wrapped in the level's ANSI color.
  /// When [timestamp] is `true` an `HH:mm:ss.SSS` prefix is added. The
  /// [source] prefix is included whenever it is present on the record.
  String format({bool colors = true, bool timestamp = false}) {
    final buffer = StringBuffer();
    if (timestamp) buffer.write('[${_formatTime(time)}] ');
    if (source != null) buffer.write('[$source] ');
    buffer.write(message);
    final text = buffer.toString();
    return colors ? '${level.color}$text${LogColor.reset}' : text;
  }

  /// The record rendered with the current [DevLog.useColors] and
  /// [DevLog.showTimestamps] settings — the exact string the console
  /// would show.
  String get formatted =>
      format(colors: DevLog.useColors, timestamp: DevLog.showTimestamps);

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.$ms';
  }

  @override
  String toString() => 'LogRecord($name: $message)';
}
