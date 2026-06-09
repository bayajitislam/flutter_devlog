import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_devlog/flutter_devlog.dart';

void main() {
  // Capture output through the onLog sink for every test.
  late List<({String msg, String name})> captured;

  setUp(() {
    captured = [];
    DevLog.enabled = true;
    DevLog.useColors = true;
    DevLog.includeSource = false;
    DevLog.minPriority = LogPriority.ui;
    DevLog.onLog = (msg, name) => captured.add((msg: msg, name: name));
  });

  tearDown(() {
    DevLog.onLog = null;
  });

  test('built-in levels route to the correct channel', () {
    DevLog.info('a');
    DevLog.error('b');
    final names = captured.map((e) => e.name).toList();
    expect(names, containsAll(['INFO', 'ERROR']));
  });

  test('custom level works', () {
    const custom = LogLevel('NETWORK', LogColor.blue, LogPriority.api);
    DevLog.log('hi', level: custom);
    expect(captured.single.name, 'NETWORK');
  });

  test('tag appends a sub-channel', () {
    DevLog.info('x', tag: 'Auth');
    expect(captured.single.name, 'INFO/Auth');
  });

  test('useColors=false strips ANSI codes', () {
    DevLog.useColors = false;
    DevLog.info('plain');
    expect(captured.single.msg, 'plain');
    expect(captured.single.msg, isNot(contains('\x1B')));
  });

  test('useColors=true wraps with color and reset', () {
    DevLog.info('hi');
    expect(captured.single.msg, contains(LogColor.cyan));
    expect(captured.single.msg, contains(LogColor.reset));
  });

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
    final names = captured.map((e) => e.name).toList();
    expect(names, ['ERROR']);
  });

  test('lazy builder is skipped when filtered out', () {
    DevLog.minPriority = LogPriority.error;
    var called = false;
    DevLog.lazy(() {
      called = true;
      return 'x';
    }, level: LogLevel.info);
    expect(called, isFalse);
    expect(captured, isEmpty);
  });

  test('lazy builder runs when not filtered', () {
    var called = false;
    DevLog.lazy(() {
      called = true;
      return 'x';
    }, level: LogLevel.info);
    expect(called, isTrue);
    expect(captured.single.name, 'INFO');
  });

  test('error forwards exception and stack trace as sub-channels', () {
    DevLog.error('boom', error: 'E', stackTrace: StackTrace.current);
    final names = captured.map((e) => e.name).toList();
    expect(names, containsAll(['ERROR', 'ERROR/ERR', 'ERROR/STK']));
  });

  test('includeSource prepends a file:line prefix', () {
    DevLog.includeSource = true;
    DevLog.info('with source');
    expect(captured.single.msg, matches(r'\[.+\.dart:\d+\]'));
  });

  test('json pretty-prints and reports encode errors', () {
    DevLog.json({'k': 'v'}, title: 'T');
    DevLog.json(Object()); // not encodable
    final names = captured.map((e) => e.name).toList();
    expect(names, contains('JSON'));
    expect(names, contains('JSON ERROR'));
  });

  test('scoped logger auto-tags', () {
    final log = DevLog.scoped('Payment');
    log.info('charge');
    log.success('done');
    final names = captured.map((e) => e.name).toList();
    expect(names, ['INFO/Payment', 'SUCCESS/Payment']);
  });
}
