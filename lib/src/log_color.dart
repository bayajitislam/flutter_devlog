/// ANSI escape codes used to colorize console output.
///
/// ANSI rendering depends on the console. If raw codes such as `\x1B[31m`
/// appear in your output instead of colors, set [DevLog.useColors] to `false`.
class LogColor {
  const LogColor._();

  /// Resets all styling. Appended after every colored message.
  static const String reset = '\x1B[0m';

  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String grey = '\x1B[90m';
}
