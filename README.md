# flutter_devlog

[![pub package](https://img.shields.io/pub/v/flutter_devlog.svg?logo=dart&logoColor=00b9fc)](https://pub.dev/packages/flutter_devlog)
[![CI](https://img.shields.io/github/actions/workflow/status/bayajitislam/flutter_devlog/dart.yml?branch=main&logo=github-actions&logoColor=white)](https://github.com/bayajitislam/flutter_devlog/actions)
[![Last Commits](https://img.shields.io/github/last-commit/bayajitislam/flutter_devlog?logo=git&logoColor=white)](https://github.com/bayajitislam/flutter_devlog/commits/main)
[![Pull Requests](https://img.shields.io/github/issues-pr/bayajitislam/flutter_devlog?logo=github&logoColor=white)](https://github.com/bayajitislam/flutter_devlog/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/bayajitislam/flutter_devlog?logo=github&logoColor=white)](https://github.com/bayajitislam/flutter_devlog)
[![License](https://img.shields.io/github/license/bayajitislam/flutter_devlog?logo=open-source-initiative&logoColor=green)](https://github.com/bayajitislam/flutter_devlog/blob/main/LICENSE)

A small, colored console logger for Dart and Flutter.

It has no dependencies beyond the Flutter SDK, is guaranteed silent in release
builds (the logging code is compiled out of your production app), and keeps a
simple API: one class, `DevLog`, with a method for each log level. When your
app grows, you can add tags, scopes, custom levels, and filtering without
changing how you call it.

**If this package helps you, please star the repo to support it.**

### Resources

- [Pub Package](https://pub.dev/packages/flutter_devlog)
- [API Documentation](https://pub.dev/documentation/flutter_devlog/latest/)
- [GitHub Repository](https://github.com/bayajitislam/flutter_devlog)

## Installation

Add it to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_devlog: ^0.2.0
```

Then run `flutter pub get`, and import it where you need it:

```dart
import 'package:flutter_devlog/flutter_devlog.dart';
```

It goes under `dependencies` (not `dev_dependencies`) because your app code
imports it — Dart only allows dev dependencies in `test/` and `tool/`. That is
safe: this is a development-only logger, and release builds are always silent
(see below), so it adds nothing to your production app.

## A quick example

You don't need to create anything or call a setup function. Just log:

```dart
DevLog.info('App started');
DevLog.success('User logged in');
DevLog.warn('Cache is old');
DevLog.error('Could not load profile');
```

Each line prints to the console in its own color, with a label showing which
kind of log it was (`INFO`, `SUCCESS`, `WARN`, `ERROR`).

You can pass any object, not just text:

```dart
DevLog.info(user);            // an object
DevLog.info([1, 2, 3]);       // a list
DevLog.info({'id': 1});       // a map
```

That is all you need for everyday use. The sections below explain the extra
features for when you want them.

## The log levels

There are seven built-in levels. Use whichever fits what you are logging:

```dart
DevLog.ui('Home screen built');       // screen / widget events
DevLog.storage('Saved token');        // local storage, cache, database
DevLog.info('App started');           // general messages
DevLog.success('Payment complete');   // something worked
DevLog.api('GET /users returned 200');// network calls
DevLog.warn('Token expires soon');    // needs attention, not an error
DevLog.error('Request failed');       // something went wrong
```

The names you pick are only for your own clarity. Internally they also have a
priority order (`ui` is lowest, `error` is highest), which the filter below uses.

## Logging errors with details

When you catch an exception, pass the error and stack trace. They show up in the
console and in Flutter DevTools, which makes debugging much easier:

```dart
try {
  await loadProfile();
} catch (e, stackTrace) {
  DevLog.error('Failed to load profile', error: e, stackTrace: stackTrace);
}
```

## Pretty-printing JSON

If you log an API response, `DevLog.json` formats it with indentation so it is
actually readable:

```dart
DevLog.json(response, title: 'User response');
```

This prints the title first, then the JSON neatly indented. If the object can't
be turned into JSON, it tells you instead of crashing. JSON logs are filtered
like `info`-level logs; pass a different `level` if you want another priority.

## Turning logging on and off

By default, logs only appear in debug builds, so you don't have to remove your
log lines before shipping.

Release builds are **always silent** — this is a debugging tool, and there is
deliberately no way to turn it on in production. Even `DevLog.enabled = true`
has no effect in a release build. The release check is a compile-time constant,
so the compiler removes the logging code from your release app entirely; your
log lines cost nothing in production.

`enabled` controls debug and profile builds. You can change it and a few other
things once, usually at the start of `main`.
Every option is a plain field on `DevLog`, or set several at a time with
`configure`:

```dart
void main() {
  DevLog.configure(
    enabled: true,         // force on/off (debug and profile builds only)
    useColors: true,       // set false if you see raw codes like \x1B[31m
    includeSource: true,   // add the file and line, e.g. [main.dart:42]
    showTimestamps: true,  // add the time, e.g. [14:03:07.412]
  );

  runApp(const MyApp());
}
```

`includeSource` is handy while debugging because every log tells you exactly
which line printed it. To go back to all defaults at once (useful in test
`tearDown` blocks), call `DevLog.reset()`.

## Showing only the important logs

In a busy app you may want to hide the low-level noise and keep only warnings
and errors. Set a minimum level once:

```dart
DevLog.minPriority = LogPriority.warn;
```

After this, `ui`, `storage`, `info`, `success`, and `api` logs are skipped, and
only `warn` and `error` get through. Set it back to `LogPriority.ui` to see
everything again.

You can also filter by tag. When one module floods the console, block it; or
allow only the tags you are working on right now:

```dart
DevLog.blockedTags = {'Bloc'};            // hide a noisy module
DevLog.allowedTags = {'Auth', 'Payment'}; // show only these tags
```

Untagged logs always pass the allowlist. Set `blockedTags = {}` and
`allowedTags = null` to remove the filters.

## Tagging logs by feature

In a larger app it helps to know which part of the code a log came from. Add a
`tag`:

```dart
DevLog.info('Charge started', tag: 'Payment');
```

This prints under the label `INFO/Payment`, so you can scan the console and find
all payment-related logs quickly.

## A logger for one feature (scopes)

If a whole file or feature should always use the same tag, create a scoped
logger once and reuse it. Every call is tagged automatically:

```dart
final log = DevLog.scoped('Auth');

log.info('Checking credentials');   // prints as INFO/Auth
log.success('Logged in');           // prints as SUCCESS/Auth
log.error('Token expired', error: e);
```

This keeps your code clean because you don't repeat the tag every time. A
scoped logger has the same methods as `DevLog`, including `lazy` and `json`.

For sub-features, create a nested scope with `child`:

```dart
final loginLog = log.child('Login');
loginLog.info('OTP sent');          // prints as INFO/Auth/Login
```

## Adding your own log level

The built-in levels may not cover everything. You can define your own by giving
it a name, a color, and a priority. No need to edit the package:

```dart
const network = LogLevel('NETWORK', LogColor.blue, LogPriority.api);

DevLog.log('Opening socket', level: network);
```

It then behaves like any built-in level, including color and filtering.

## Avoiding expensive log messages

Sometimes building the log text is costly (for example, dumping a large object).
Normally that work happens even if the log is later filtered out. To avoid that,
use `lazy` and pass a function. The function only runs if the log will actually
be shown:

```dart
DevLog.lazy(() => 'Big dump: ${buildExpensiveString()}', level: LogLevel.info);
```

If `minPriority` is set above `info`, the function is never called.

## Sending logs somewhere other than the console

By default logs go to the console. If you want to write them to a file, send
them to a crash reporter, or capture them in a test, set `onLog`. It receives
a `LogRecord` with everything about the log as separate fields: the level, the
raw message (no color codes), the channel name, the tag, the error and stack
trace, the time, and the source location.

Writing to a file:

```dart
DevLog.onLog = (record) {
  myLogFile.writeln('${record.time} [${record.name}] ${record.message}');
};
```

Forwarding errors to a crash reporter:

```dart
DevLog.onLog = (record) {
  if (record.level == LogLevel.error) {
    FirebaseCrashlytics.instance.recordError(
      record.error ?? record.message,
      record.stackTrace,
      reason: record.message,
    );
  }
};
```

If you just want the exact colored string the console would show, use
`record.formatted`. Set `onLog` back to `null` to return to normal console
output.

## A note on colors

Colors use ANSI escape codes. Most terminals and IDE consoles understand them,
but a few do not and will print raw codes like `\x1B[31m` instead. If you see
that, turn colors off:

```dart
DevLog.useColors = false;
```

## Author

Made by **Bayajit Islam** — [Portfolio](https://bayajitislam.com/) · [GitHub](https://github.com/bayajitislam)

Found a bug or have an idea? Open an issue or a pull request on the repository.

## License

MIT. See the [LICENSE](https://github.com/bayajitislam/flutter_devlog/blob/main/LICENSE) file.