/// ANSI escape codes used to colorize console output.
///
/// ANSI rendering depends on the console. If raw codes such as `\x1B[31m`
/// appear in your output instead of colors, set [DevLog.useColors] to `false`.
class LogColor {
  const LogColor._();

  /// Resets all styling. Appended after every colored message.
  static const String reset = '\x1B[0m';

  /// Red — used by the built-in `error` level.
  static const String red = '\x1B[31m';

  /// Green — used by the built-in `success` level.
  static const String green = '\x1B[32m';

  /// Yellow — used by the built-in `warn` level.
  static const String yellow = '\x1B[33m';

  /// Blue — available for custom levels.
  static const String blue = '\x1B[34m';

  /// Magenta — used by the built-in `api` level.
  static const String magenta = '\x1B[35m';

  /// Cyan — used by the built-in `info` and `json` levels.
  static const String cyan = '\x1B[36m';

  /// White — used by the built-in `storage` level.
  static const String white = '\x1B[37m';

  /// Grey — used by the built-in `ui` level.
  static const String grey = '\x1B[90m';
}
