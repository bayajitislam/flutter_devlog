## 0.2.0

New features:

- Release builds are now always silent: even `DevLog.enabled = true` has no
  effect in release mode. The check is a compile-time constant
  (`kReleaseMode`), so logging code is tree-shaken out of release builds.
  `enabled` now only controls debug and profile builds.

- Structured log sink: `DevLog.onLog` now receives a `LogRecord` with the
  level, raw message (no ANSI codes), channel name, tag, error, stack trace,
  timestamp, and source location. Use `record.formatted` for the colored
  console string.
- `DevLog.configure(...)` to set several options in one call and
  `DevLog.reset()` to restore all defaults (handy in test `tearDown`).
- Tag filtering: `DevLog.allowedTags` (allowlist) and `DevLog.blockedTags`
  (denylist).
- Timestamps: set `DevLog.showTimestamps = true` for an `HH:mm:ss.SSS` prefix.
- `ScopedLogger` parity: `lazy()`, `child()` for nested scopes
  (`Auth/Login`), a `label` parameter on `json()`, and `error`/`stackTrace`
  parameters on `log()`.
- `DevLog.json` now accepts a `level` (defaults to the new `LogLevel.json`)
  and respects `minPriority` like every other log.

Breaking changes:

- `DevLog.onLog` changed from `void Function(String message, String name)` to
  `void Function(LogRecord record)`. Errors and stack traces are no longer
  delivered as separate `/ERR` and `/STK` calls; they are fields on the
  record. Migration:

  ```dart
  // Before
  DevLog.onLog = (message, name) => file.writeln('[$name] $message');

  // After
  DevLog.onLog = (record) =>
      file.writeln('[${record.name}] ${record.message}');
  ```

- The `sourceSkip` parameter was removed from `DevLog.log`. The source
  location is now resolved automatically and stays correct through wrappers.
- `DevLog.json` prints the title and JSON body as a single log entry instead
  of two, and is filtered by `minPriority` (priority `info` by default).

## 0.1.0

Initial release.

- Leveled colored logging: `info`, `success`, `warn`, `error`, `api`,
  `storage`, `ui`.
- Custom `LogLevel` support with `LogPriority` for filtering.
- Optional `[file:line]` source location (`DevLog.includeSource`).
- `error` and `stackTrace` parameters forwarded to `dart:developer`.
- Tagged logging (`tag:`) and per-module `DevLog.scoped()` loggers.
- `DevLog.minPriority` filter and `DevLog.lazy()` for deferred messages.
- Pretty JSON logging via `DevLog.json`.
- Pluggable output via `DevLog.onLog`; debug-only by default.
