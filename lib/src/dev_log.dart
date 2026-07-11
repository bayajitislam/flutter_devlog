import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'log_level.dart';
import 'log_record.dart';
import 'scoped_logger.dart';

/// A static, easy-to-use colored logger for Flutter.
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
/// DevLog.configure(
///   enabled: true,                 // defaults to debug mode only
///   useColors: false,              // strip ANSI on plain consoles
///   includeSource: true,           // prepend file:line
///   showTimestamps: true,          // prepend HH:mm:ss.SSS
///   minPriority: LogPriority.info, // drop ui/storage logs
///   onLog: (record) => myFile.writeln(record.formatted),
/// );
/// ```
class DevLog {
  DevLog._();

  /// Master switch. Defaults to active only in debug builds ([kDebugMode]).
  ///
  /// This is a development-only logger: release builds ([kReleaseMode]) are
  /// **always silent**, even when this is set to `true`. Because the release
  /// check is a compile-time constant, the logging code is tree-shaken out of
  /// release builds entirely. Setting `enabled = true` only affects debug and
  /// profile builds.
  static bool enabled = kDebugMode;

  /// When `false`, ANSI color codes are stripped from output. Set this on
  /// consoles that print raw escape codes instead of rendering colors.
  static bool useColors = true;

  /// When `true`, each message is prefixed with the caller's `file:line`,
  /// e.g. `[main.dart:42] App started`. Off by default because resolving the
  /// source location parses a [StackTrace], which has a small cost.
  static bool includeSource = false;

  /// When `true`, each message is prefixed with an `HH:mm:ss.SSS` timestamp,
  /// e.g. `[14:03:07.412] App started`. Off by default.
  static bool showTimestamps = false;

  /// Logs whose level priority is below this are dropped before any work is
  /// done. Defaults to the lowest priority (nothing filtered).
  static LogPriority minPriority = LogPriority.ui;

  /// When set, only tagged logs whose tag is in this set are emitted.
  /// Untagged logs always pass. Leave `null` (the default) to allow all tags.
  ///
  /// ```dart
  /// DevLog.allowedTags = {'Auth', 'Payment'}; // silence everything else
  /// ```
  static Set<String>? allowedTags;

  /// Tags in this set are always dropped, even when listed in [allowedTags].
  /// Useful when one chatty module drowns out the console.
  ///
  /// ```dart
  /// DevLog.blockedTags = {'Bloc'}; // hide a noisy module
  /// ```
  static Set<String> blockedTags = {};

  /// Optional output sink. When set, it receives a structured [LogRecord]
  /// instead of the default `dart:developer` log — useful for files, crash
  /// reporters, or capturing output in tests. The record's `message` carries
  /// no ANSI codes; call `record.formatted` for the colored console string.
  /// Set back to `null` to restore default output.
  static void Function(LogRecord record)? onLog;

  /// Sets several options in one call. Only the parameters you pass are
  /// changed; the rest keep their current values.
  ///
  /// ```dart
  /// DevLog.configure(
  ///   includeSource: true,
  ///   minPriority: LogPriority.info,
  /// );
  /// ```
  static void configure({
    bool? enabled,
    bool? useColors,
    bool? includeSource,
    bool? showTimestamps,
    LogPriority? minPriority,
    Set<String>? allowedTags,
    Set<String>? blockedTags,
    void Function(LogRecord record)? onLog,
  }) {
    if (enabled != null) DevLog.enabled = enabled;
    if (useColors != null) DevLog.useColors = useColors;
    if (includeSource != null) DevLog.includeSource = includeSource;
    if (showTimestamps != null) DevLog.showTimestamps = showTimestamps;
    if (minPriority != null) DevLog.minPriority = minPriority;
    if (allowedTags != null) DevLog.allowedTags = allowedTags;
    if (blockedTags != null) DevLog.blockedTags = blockedTags;
    if (onLog != null) DevLog.onLog = onLog;
  }

  /// Restores every option to its default value, including [onLog]. Handy as
  /// a one-liner in test `tearDown` blocks.
  static void reset() {
    enabled = kDebugMode;
    useColors = true;
    includeSource = false;
    showTimestamps = false;
    minPriority = LogPriority.ui;
    allowedTags = null;
    blockedTags = {};
    onLog = null;
  }

  // ----- internal helpers -----

  static bool _shouldLog(LogLevel level, String? tag) {
    // kReleaseMode is a compile-time constant, so in release builds this
    // whole method folds to `false` and log calls are tree-shaken away.
    if (kReleaseMode) return false;
    if (!enabled || level.priority.index < minPriority.index) return false;
    if (tag != null) {
      if (blockedTags.contains(tag)) return false;
      final allowed = allowedTags;
      if (allowed != null && !allowed.contains(tag)) return false;
    }
    return true;
  }

  /// Resolves the caller's `file:line` by scanning the current stack trace
  /// for the first frame outside this package. This stays correct no matter
  /// how many wrapper calls (shortcuts, [lazy], [ScopedLogger]) sit between
  /// the user's code and the logger.
  static String? _source() {
    final frames = StackTrace.current.toString().split('\n');
    for (final frame in frames) {
      if (frame.contains('package:flutter_devlog/')) continue;
      final match =
          RegExp(r'\(?([^\s(]+\.dart):(\d+)(?::\d+)?\)?').firstMatch(frame);
      if (match != null) {
        final file = match.group(1)!.split('/').last;
        return '$file:${match.group(2)}';
      }
    }
    return null;
  }

  static void _emit(LogRecord record) {
    final sink = onLog;
    if (sink != null) {
      sink(record);
    } else {
      developer.log(
        record.format(colors: useColors, timestamp: showTimestamps),
        name: record.name,
        time: record.time,
        error: record.error,
        stackTrace: record.stackTrace,
      );
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
  }) {
    if (!_shouldLog(level, tag)) return;
    _emit(LogRecord(
      level: level,
      message: '$message',
      name: tag == null ? level.name : '${level.name}/$tag',
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
      source: includeSource ? _source() : null,
    ));
  }

  // ----- convenience shortcuts for built-in levels -----

  /// Logs [m] at [LogLevel.ui] — screen and widget events.
  static void ui(Object? m, {String? tag}) =>
      log(m, level: LogLevel.ui, tag: tag);

  /// Logs [m] at [LogLevel.storage] — local storage, cache, and database.
  static void storage(Object? m, {String? tag}) =>
      log(m, level: LogLevel.storage, tag: tag);

  /// Logs [m] at [LogLevel.info] — general informational messages.
  static void info(Object? m, {String? tag}) =>
      log(m, level: LogLevel.info, tag: tag);

  /// Logs [m] at [LogLevel.success] — operations that completed well.
  static void success(Object? m, {String? tag}) =>
      log(m, level: LogLevel.success, tag: tag);

  /// Logs [m] at [LogLevel.api] — network and API events.
  static void api(Object? m, {String? tag}) =>
      log(m, level: LogLevel.api, tag: tag);

  /// Logs [m] at [LogLevel.warn] — needs attention but is not a failure.
  static void warn(Object? m, {String? tag}) =>
      log(m, level: LogLevel.warn, tag: tag);

  /// Logs [m] at [LogLevel.error], optionally with the caught [error] object
  /// and [stackTrace] so DevTools and crash reporters can pick them up.
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
    if (!_shouldLog(level, tag)) return;
    log(builder(), level: level, tag: tag);
  }

  // ----- pretty JSON -----

  /// Pretty-prints any JSON-encodable [data] with 2-space indentation.
  ///
  /// An optional [title] is printed on the line above the JSON; [label] sets
  /// the channel name. The log is filtered like any other via [level], which
  /// defaults to [LogLevel.json] (priority [LogPriority.info]). Data that
  /// cannot be encoded is reported on a `JSON ERROR` channel instead.
  static void json(
    Object? data, {
    String title = '',
    String label = 'JSON',
    LogLevel level = LogLevel.json,
  }) {
    if (!_shouldLog(level, null)) return;
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final pretty = encoder.convert(data);
      _emit(LogRecord(
        level: level,
        message: title.isEmpty ? pretty : '$title\n$pretty',
        name: label,
        time: DateTime.now(),
        source: includeSource ? _source() : null,
      ));
    } catch (e) {
      _emit(LogRecord(
        level: LogLevel.error,
        message: '$e',
        name: 'JSON ERROR',
        time: DateTime.now(),
      ));
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
