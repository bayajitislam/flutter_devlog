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
/// ```
class ScopedLogger {
  /// The tag applied to every message from this logger.
  final String scope;

  const ScopedLogger(this.scope);

  void ui(Object? m) => DevLog.ui(m, tag: scope);
  void storage(Object? m) => DevLog.storage(m, tag: scope);
  void info(Object? m) => DevLog.info(m, tag: scope);
  void success(Object? m) => DevLog.success(m, tag: scope);
  void api(Object? m) => DevLog.api(m, tag: scope);
  void warn(Object? m) => DevLog.warn(m, tag: scope);

  void error(Object? m, {Object? error, StackTrace? stackTrace}) =>
      DevLog.error(m, tag: scope, error: error, stackTrace: stackTrace);

  void log(Object? m, {required LogLevel level}) =>
      DevLog.log(m, level: level, tag: scope);

  void json(Object? data, {String title = ''}) =>
      DevLog.json(data, title: title, label: 'JSON/$scope');
}
