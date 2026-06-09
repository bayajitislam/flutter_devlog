import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'log_color.dart';
import 'log_level.dart';
import 'scoped_logger.dart';

/// A static, easy-to-use colored logger for Dart and Flutter.
///
/// Quick start:
///
/// ```dart
/// DevLog.info('App started');
/// DevLog.error('Boom', error: e, stackTrace: s);
/// DevLog.json({'id': 1}, title: 'User');
/// ```
///
/// Configure once (usually in `main`):
///
/// ```dart
/// DevLog.enabled = true;                 // defaults to debug mode only
/// DevLog.useColors = false;              // strip ANSI on plain consoles
/// DevLog.includeSource = true;           // prepend file:line
/// DevLog.minPriority = LogPriority.info; // drop ui/storage logs
/// DevLog.onLog = (msg, name) => myFile.writeln('[$name] $msg');
/// ```
class DevLog {
  DevLog._();

  /// Master switch. Defaults to active only in debug builds ([kDebugMode]).
  static bool enabled = kDebugMode;

  /// When `false`, ANSI color codes are stripped from output. Set this on
  /// consoles that print raw escape codes instead of rendering colors.
  static bool useColors = true;

  /// When `true`, each message is prefixed with the caller's `file:line`,
  /// e.g. `[main.dart:42] App started`. Off by default because resolving the
  /// source location parses a [StackTrace], which has a small cost.
  static bool includeSource = false;

  /// Logs whose level priority is below this are dropped before any work is
  /// done. Defaults to the lowest priority (nothing filtered).
  static LogPriority minPriority = LogPriority.ui;

  /// Optional output sink. When set, it receives `(message, name)` instead of
  /// the default `dart:developer` log — useful for files, crash reporters, or
  /// capturing output in tests. Set back to `null` to restore default output.
  static void Function(String message, String name)? onLog;

  // ----- internal helpers -----

  static bool _shouldLog(LogLevel level) =>
      enabled && level.priority.index >= minPriority.index;

  static String _wrap(String color, Object? message) =>
      useColors ? '$color$message${LogColor.reset}' : '$message';

  /// Resolves the caller's `file:line` from the current stack trace.
  /// [skip] is how many frames to skip to reach the user's call site.
  static String _source(int skip) {
    final frames = StackTrace.current.toString().split('\n');
    if (frames.length > skip) {
      final match =
          RegExp(r'\(?([^\s(]+\.dart):(\d+)(?::\d+)?\)?').firstMatch(frames[skip]);
      if (match != null) {
        final file = match.group(1)!.split('/').last;
        return '$file:${match.group(2)}';
      }
    }
    return '';
  }

  static void _emit(
    String text,
    String name, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final sink = onLog;
    if (sink != null) {
      sink(text, name);
      if (error != null) sink(_wrap(LogColor.red, error), '$name/ERR');
      if (stackTrace != null) sink(_wrap(LogColor.grey, stackTrace), '$name/STK');
    } else {
      developer.log(text, name: name, error: error, stackTrace: stackTrace);
    }
  }

  /// Core method. Logs [message] using any [level], built-in or custom.
  ///
  /// [tag] appends a sub-channel (`INFO/Auth`). [error] and [stackTrace] are
  /// forwarded so DevTools and crash reporters can pick them up.
  static void log(
    Object? message, {
    required LogLevel level,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    int sourceSkip = 4,
  }) {
    if (!_shouldLog(level)) return;
    final src = includeSource ? _source(sourceSkip) : '';
    final body = src.isEmpty ? '$message' : '[$src] $message';
    final name = tag == null ? level.name : '${level.name}/$tag';
    _emit(_wrap(level.color, body), name, error: error, stackTrace: stackTrace);
  }

  // ----- convenience shortcuts for built-in levels -----

  static void ui(Object? m, {String? tag}) =>
      log(m, level: LogLevel.ui, tag: tag);

  static void storage(Object? m, {String? tag}) =>
      log(m, level: LogLevel.storage, tag: tag);

  static void info(Object? m, {String? tag}) =>
      log(m, level: LogLevel.info, tag: tag);

  static void success(Object? m, {String? tag}) =>
      log(m, level: LogLevel.success, tag: tag);

  static void api(Object? m, {String? tag}) =>
      log(m, level: LogLevel.api, tag: tag);

  static void warn(Object? m, {String? tag}) =>
      log(m, level: LogLevel.warn, tag: tag);

  static void error(
    Object? m, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(m,
          level: LogLevel.error,
          tag: tag,
          error: error,
          stackTrace: stackTrace);

  // ----- lazy variant (avoids building the message when filtered out) -----

  /// Like [log], but [builder] is only called when the log will actually be
  /// emitted. Use this when constructing the message is expensive:
  ///
  /// ```dart
  /// DevLog.lazy(() => 'Big: ${expensiveDump()}', level: LogLevel.info);
  /// ```
  static void lazy(
    Object? Function() builder, {
    required LogLevel level,
    String? tag,
  }) {
    if (!_shouldLog(level)) return;
    log(builder(), level: level, tag: tag, sourceSkip: 5);
  }

  // ----- pretty JSON -----

  /// Pretty-prints any JSON-encodable [data] with 2-space indentation.
  ///
  /// An optional [title] is printed first (white); [label] sets the channel
  /// name. Data that cannot be encoded is reported on a `JSON ERROR` channel.
  static void json(
    Object? data, {
    String title = '',
    String label = 'JSON',
  }) {
    if (!enabled) return;
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final pretty = encoder.convert(data);
      if (title.isNotEmpty) {
        _emit(_wrap(LogColor.white, title), label);
      }
      _emit(_wrap(LogColor.cyan, pretty), label);
    } catch (e) {
      _emit(_wrap(LogColor.red, e), 'JSON ERROR');
    }
  }

  // ----- scoped instance -----

  /// Creates a [ScopedLogger] that automatically tags every message with
  /// [scope]. Handy for per-module logging:
  ///
  /// ```dart
  /// final authLog = DevLog.scoped('Auth');
  /// authLog.info('Login success'); // channel: INFO/Auth
  /// ```
  static ScopedLogger scoped(String scope) => ScopedLogger(scope);
}
