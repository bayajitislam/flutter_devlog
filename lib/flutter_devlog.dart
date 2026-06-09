/// A lightweight, zero-dependency, extensible colored console logger for
/// Dart and Flutter.
///
/// ```dart
/// import 'package:flutter_devlog/flutter_devlog.dart';
///
/// void main() {
///   DevLog.info('App started');
///   DevLog.error('Failed', error: e, stackTrace: s);
///   DevLog.json({'id': 1, 'name': 'Sam'}, title: 'User');
///
///   // Custom level:
///   const network = LogLevel('NETWORK', LogColor.blue, LogPriority.api);
///   DevLog.log('Connecting...', level: network);
///
///   // Per-module logger:
///   final authLog = DevLog.scoped('Auth');
///   authLog.success('Logged in');
/// }
/// ```
library flutter_devlog;

export 'src/log_color.dart';
export 'src/log_level.dart';
export 'src/dev_log.dart';
export 'src/scoped_logger.dart';
