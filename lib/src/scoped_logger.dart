import 'dev_log.dart';
import 'log_level.dart';

/// A logger bound to a [scope] that auto-tags every message.
///
/// Get one via [DevLog.scoped]:
///
/// ```dart
/// final log = DevLog.scoped('Payment');
/// log.info('Charge started');   // channel: INFO/Payment
/// log.error('Declined', error: e);
///
/// final refunds = log.child('Refund');
/// refunds.info('Started');      // channel: INFO/Payment/Refund
/// ```
class ScopedLogger {
  /// The tag applied to every message from this logger.
  final String scope;

  /// Creates a logger whose every message is tagged with [scope].
  const ScopedLogger(this.scope);

  /// Creates a nested logger whose tag is `'$scope/$sub'`:
  ///
  /// ```dart
  /// final auth = DevLog.scoped('Auth');
  /// final login = auth.child('Login');
  /// login.info('OTP sent'); // channel: INFO/Auth/Login
  /// ```
  ScopedLogger child(String sub) => ScopedLogger('$scope/$sub');

  /// Logs [m] at [LogLevel.ui], tagged with [scope].
  void ui(Object? m) => DevLog.ui(m, tag: scope);

  /// Logs [m] at [LogLevel.storage], tagged with [scope].
  void storage(Object? m) => DevLog.storage(m, tag: scope);

  /// Logs [m] at [LogLevel.info], tagged with [scope].
  void info(Object? m) => DevLog.info(m, tag: scope);

  /// Logs [m] at [LogLevel.success], tagged with [scope].
  void success(Object? m) => DevLog.success(m, tag: scope);

  /// Logs [m] at [LogLevel.api], tagged with [scope].
  void api(Object? m) => DevLog.api(m, tag: scope);

  /// Logs [m] at [LogLevel.warn], tagged with [scope].
  void warn(Object? m) => DevLog.warn(m, tag: scope);

  /// Logs [m] at [LogLevel.error], tagged with [scope], optionally with the
  /// caught [error] object and [stackTrace].
  void error(Object? m, {Object? error, StackTrace? stackTrace}) =>
      DevLog.error(m, tag: scope, error: error, stackTrace: stackTrace);

  /// Logs [m] using any [level], tagged with [scope]. See [DevLog.log].
  void log(
    Object? m, {
    required LogLevel level,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      DevLog.log(m,
          level: level, tag: scope, error: error, stackTrace: stackTrace);

  /// Like [log], but [builder] only runs when the log will actually be
  /// emitted. See [DevLog.lazy].
  void lazy(Object? Function() builder, {required LogLevel level}) =>
      DevLog.lazy(builder, level: level, tag: scope);

  /// Pretty-prints [data] as JSON. The channel [label] defaults to
  /// `'JSON/$scope'`. See [DevLog.json].
  void json(Object? data, {String title = '', String? label}) =>
      DevLog.json(data, title: title, label: label ?? 'JSON/$scope');
}
