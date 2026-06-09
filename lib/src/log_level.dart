import 'log_color.dart';

/// Relative importance of a log, used by [DevLog.minPriority] to filter out
/// low-importance logs cheaply. Ordered from least to most important.
enum LogPriority {
  /// UI/render events — lowest importance.
  ui,

  /// Local storage / cache events.
  storage,

  /// General informational messages.
  info,

  /// Successful operations.
  success,

  /// Network / API events.
  api,

  /// Warnings that need attention but are not failures.
  warn,

  /// Errors and failures — highest importance.
  error,
}

/// Describes a single log level: a display [name] (shown as the log channel),
/// an ANSI [color], and a [priority] used for filtering.
///
/// Define your own level to extend the logger without modifying it:
///
/// ```dart
/// const network = LogLevel('NETWORK', LogColor.blue, LogPriority.api);
/// DevLog.log('Connecting...', level: network);
/// ```
class LogLevel {
  /// Channel name shown alongside the message (e.g. `INFO`, `ERROR`).
  final String name;

  /// ANSI color applied to the message text.
  final String color;

  /// Importance used for filtering via [DevLog.minPriority].
  final LogPriority priority;

  const LogLevel(this.name, this.color, this.priority);

  // --- Built-in levels ---

  static const LogLevel ui = LogLevel('UI', LogColor.grey, LogPriority.ui);
  static const LogLevel storage =
      LogLevel('STORAGE', LogColor.white, LogPriority.storage);
  static const LogLevel info =
      LogLevel('INFO', LogColor.cyan, LogPriority.info);
  static const LogLevel success =
      LogLevel('SUCCESS', LogColor.green, LogPriority.success);
  static const LogLevel api =
      LogLevel('API', LogColor.magenta, LogPriority.api);
  static const LogLevel warn =
      LogLevel('WARN', LogColor.yellow, LogPriority.warn);
  static const LogLevel error =
      LogLevel('ERROR', LogColor.red, LogPriority.error);

  @override
  String toString() => 'LogLevel($name)';
}
