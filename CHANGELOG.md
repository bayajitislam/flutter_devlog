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
