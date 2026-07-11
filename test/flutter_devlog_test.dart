import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_devlog/flutter_devlog.dart';

void main() {
  // Capture output through the onLog sink for every test.
  late List<LogRecord> captured;

  setUp(() {
    captured = [];
    DevLog.reset();
    DevLog.enabled = true;
    DevLog.onLog = captured.add;
  });

  tearDown(DevLog.reset);

  group('levels and channels', () {
    test('built-in levels route to the correct channel', () {
      DevLog.info('a');
      DevLog.error('b');
      final names = captured.map((r) => r.name).toList();
      expect(names, containsAll(['INFO', 'ERROR']));
    });

    test('every shortcut uses its own level', () {
      DevLog.ui('a');
      DevLog.storage('b');
      DevLog.info('c');
      DevLog.success('d');
      DevLog.api('e');
      DevLog.warn('f');
      DevLog.error('g');
      expect(captured.map((r) => r.level).toList(), [
        LogLevel.ui,
        LogLevel.storage,
        LogLevel.info,
        LogLevel.success,
        LogLevel.api,
        LogLevel.warn,
        LogLevel.error,
      ]);
    });

    test('custom level works', () {
      const custom = LogLevel('NETWORK', LogColor.blue, LogPriority.api);
      DevLog.log('hi', level: custom);
      expect(captured.single.name, 'NETWORK');
      expect(captured.single.level, custom);
    });

    test('tag appends a sub-channel', () {
      DevLog.info('x', tag: 'Auth');
      expect(captured.single.name, 'INFO/Auth');
      expect(captured.single.tag, 'Auth');
    });
  });

  group('LogRecord', () {
    test('message carries no ANSI codes even with colors on', () {
      DevLog.useColors = true;
      DevLog.info('plain');
      expect(captured.single.message, 'plain');
      expect(captured.single.message, isNot(contains('\x1B')));
    });

    test('carries error and stack trace as fields', () {
      final trace = StackTrace.current;
      DevLog.error('boom', error: 'E', stackTrace: trace);
      final record = captured.single;
      expect(record.error, 'E');
      expect(record.stackTrace, trace);
      expect(captured, hasLength(1)); // no separate /ERR and /STK entries
    });

    test('records the time of the log call', () {
      final before = DateTime.now();
      DevLog.info('now');
      final after = DateTime.now();
      final time = captured.single.time;
      expect(time.isBefore(before), isFalse);
      expect(time.isAfter(after), isFalse);
    });

    test('format wraps with the level color and reset', () {
      DevLog.info('hi');
      final text = captured.single.format(colors: true);
      expect(text, startsWith(LogColor.cyan));
      expect(text, endsWith(LogColor.reset));
    });

    test('format without colors is the plain message', () {
      DevLog.info('hi');
      expect(captured.single.format(colors: false), 'hi');
    });

    test('format with timestamp prefixes HH:mm:ss.SSS', () {
      DevLog.info('hi');
      final text = captured.single.format(colors: false, timestamp: true);
      expect(text, matches(r'^\[\d{2}:\d{2}:\d{2}\.\d{3}\] hi$'));
    });

    test('formatted honors current useColors and showTimestamps', () {
      DevLog.info('hi');
      final record = captured.single;

      DevLog.useColors = false;
      DevLog.showTimestamps = false;
      expect(record.formatted, 'hi');

      DevLog.useColors = true;
      DevLog.showTimestamps = true;
      expect(record.formatted, contains(LogColor.cyan));
      expect(record.formatted, matches(r'\[\d{2}:\d{2}:\d{2}\.\d{3}\]'));
    });
  });

  group('filtering', () {
    test('disabled logger emits nothing', () {
      DevLog.enabled = false;
      DevLog.info('nope');
      expect(captured, isEmpty);
    });

    test('minPriority filters lower-priority logs', () {
      DevLog.minPriority = LogPriority.warn;
      DevLog.info('dropped'); // info < warn
      DevLog.ui('dropped'); // ui < warn
      DevLog.error('kept'); // error >= warn
      expect(captured.map((r) => r.name).toList(), ['ERROR']);
    });

    test('blockedTags drops matching tags', () {
      DevLog.blockedTags = {'Noisy'};
      DevLog.info('dropped', tag: 'Noisy');
      DevLog.info('kept', tag: 'Auth');
      DevLog.info('kept untagged');
      expect(captured.map((r) => r.tag).toList(), ['Auth', null]);
    });

    test('allowedTags keeps only listed tags but lets untagged pass', () {
      DevLog.allowedTags = {'Auth'};
      DevLog.info('kept', tag: 'Auth');
      DevLog.info('dropped', tag: 'Payment');
      DevLog.info('kept untagged');
      expect(captured.map((r) => r.tag).toList(), ['Auth', null]);
    });

    test('blockedTags wins over allowedTags', () {
      DevLog.allowedTags = {'Auth'};
      DevLog.blockedTags = {'Auth'};
      DevLog.info('dropped', tag: 'Auth');
      expect(captured, isEmpty);
    });
  });

  group('lazy', () {
    test('builder is skipped when filtered out', () {
      DevLog.minPriority = LogPriority.error;
      var called = false;
      DevLog.lazy(() {
        called = true;
        return 'x';
      }, level: LogLevel.info);
      expect(called, isFalse);
      expect(captured, isEmpty);
    });

    test('builder runs when not filtered', () {
      var called = false;
      DevLog.lazy(() {
        called = true;
        return 'x';
      }, level: LogLevel.info);
      expect(called, isTrue);
      expect(captured.single.name, 'INFO');
    });
  });

  group('source location', () {
    test('includeSource resolves the caller file:line', () {
      DevLog.includeSource = true;
      DevLog.info('with source');
      expect(captured.single.source, matches(r'flutter_devlog_test\.dart:\d+'));
    });

    test('source stays correct through wrappers like lazy and scoped', () {
      DevLog.includeSource = true;
      DevLog.lazy(() => 'x', level: LogLevel.info);
      DevLog.scoped('S').info('y');
      for (final record in captured) {
        expect(record.source, matches(r'flutter_devlog_test\.dart:\d+'));
      }
    });

    test('format prefixes the source when present', () {
      DevLog.includeSource = true;
      DevLog.info('with source');
      expect(captured.single.format(colors: false),
          matches(r'^\[flutter_devlog_test\.dart:\d+\] with source$'));
    });

    test('source is null when includeSource is off', () {
      DevLog.info('no source');
      expect(captured.single.source, isNull);
    });
  });

  group('json', () {
    test('pretty-prints with title and reports encode errors', () {
      DevLog.json({'k': 'v'}, title: 'T');
      DevLog.json(Object()); // not encodable
      expect(captured[0].name, 'JSON');
      expect(captured[0].message, contains('T'));
      expect(captured[0].message, contains('"k": "v"'));
      expect(captured[1].name, 'JSON ERROR');
    });

    test('respects minPriority', () {
      DevLog.minPriority = LogPriority.warn;
      DevLog.json({'k': 'v'}); // default level is info priority
      expect(captured, isEmpty);

      const important = LogLevel('JSON', LogColor.cyan, LogPriority.error);
      DevLog.json({'k': 'v'}, level: important);
      expect(captured.single.name, 'JSON');
    });

    test('custom label sets the channel name', () {
      DevLog.json({'k': 'v'}, label: 'API');
      expect(captured.single.name, 'API');
    });
  });

  group('ScopedLogger', () {
    test('auto-tags every message', () {
      final log = DevLog.scoped('Payment');
      log.info('charge');
      log.success('done');
      expect(captured.map((r) => r.name).toList(),
          ['INFO/Payment', 'SUCCESS/Payment']);
    });

    test('error forwards exception and stack trace', () {
      final log = DevLog.scoped('Payment');
      final trace = StackTrace.current;
      log.error('declined', error: 'E', stackTrace: trace);
      final record = captured.single;
      expect(record.name, 'ERROR/Payment');
      expect(record.error, 'E');
      expect(record.stackTrace, trace);
    });

    test('log forwards error and stack trace', () {
      final log = DevLog.scoped('Payment');
      log.log('x', level: LogLevel.warn, error: 'E');
      expect(captured.single.error, 'E');
    });

    test('lazy respects the filter and tags with the scope', () {
      final log = DevLog.scoped('Payment');

      DevLog.minPriority = LogPriority.error;
      var called = false;
      log.lazy(() {
        called = true;
        return 'x';
      }, level: LogLevel.info);
      expect(called, isFalse);

      DevLog.minPriority = LogPriority.ui;
      log.lazy(() => 'x', level: LogLevel.info);
      expect(captured.single.name, 'INFO/Payment');
    });

    test('json label defaults to JSON/scope and can be overridden', () {
      final log = DevLog.scoped('Payment');
      log.json({'k': 'v'});
      log.json({'k': 'v'}, label: 'Custom');
      expect(captured.map((r) => r.name).toList(), ['JSON/Payment', 'Custom']);
    });

    test('child creates a nested scope', () {
      final login = DevLog.scoped('Auth').child('Login');
      expect(login.scope, 'Auth/Login');
      login.info('OTP sent');
      expect(captured.single.name, 'INFO/Auth/Login');
    });
  });

  group('configure and reset', () {
    test('configure sets only the passed options', () {
      DevLog.configure(
        minPriority: LogPriority.warn,
        showTimestamps: true,
        blockedTags: {'X'},
      );
      expect(DevLog.minPriority, LogPriority.warn);
      expect(DevLog.showTimestamps, isTrue);
      expect(DevLog.blockedTags, {'X'});
      expect(DevLog.enabled, isTrue); // untouched
      expect(DevLog.onLog, isNotNull); // untouched
    });

    test('reset restores every default', () {
      DevLog.configure(
        useColors: false,
        includeSource: true,
        showTimestamps: true,
        minPriority: LogPriority.error,
        allowedTags: {'A'},
        blockedTags: {'B'},
      );
      DevLog.reset();
      expect(DevLog.useColors, isTrue);
      expect(DevLog.includeSource, isFalse);
      expect(DevLog.showTimestamps, isFalse);
      expect(DevLog.minPriority, LogPriority.ui);
      expect(DevLog.allowedTags, isNull);
      expect(DevLog.blockedTags, isEmpty);
      expect(DevLog.onLog, isNull);
    });
  });
}
