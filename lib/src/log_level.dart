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

  /// Creates a level from a channel [name], an ANSI [color] (see [LogColor]),
  /// and a [priority] used for filtering.
  const LogLevel(this.name, this.color, this.priority);

  // --- Built-in levels ---

  /// UI/render events — grey, lowest priority.
  static const LogLevel ui = LogLevel('UI', LogColor.grey, LogPriority.ui);

  /// Local storage / cache events — white.
  static const LogLevel storage =
      LogLevel('STORAGE', LogColor.white, LogPriority.storage);

  /// General informational messages — cyan.
  static const LogLevel info =
      LogLevel('INFO', LogColor.cyan, LogPriority.info);

  /// Successful operations — green.
  static const LogLevel success =
      LogLevel('SUCCESS', LogColor.green, LogPriority.success);

  /// Network / API events — magenta.
  static const LogLevel api =
      LogLevel('API', LogColor.magenta, LogPriority.api);

  /// Warnings — yellow.
  static const LogLevel warn =
      LogLevel('WARN', LogColor.yellow, LogPriority.warn);

  /// Errors and failures — red, highest priority.
  static const LogLevel error =
      LogLevel('ERROR', LogColor.red, LogPriority.error);

  /// Pretty-printed JSON output — cyan, same priority as [info]. Used as the
  /// default level for `DevLog.json`.
  static const LogLevel json =
      LogLevel('JSON', LogColor.cyan, LogPriority.info);

  @override
  String toString() => 'LogLevel($name)';
}
