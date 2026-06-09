import 'package:flutter/material.dart';
import 'package:flutter_devlog/flutter_devlog.dart';

// 1. A custom level — no need to edit the package.
const networkLevel = LogLevel('NETWORK', LogColor.blue, LogPriority.api);

// 2. A per-module scoped logger.
final authLog = DevLog.scoped('Auth');

void main() {
  // Configure once at startup.
  DevLog.enabled = true; // by default only true in debug builds
  DevLog.useColors = true; // set false if your console shows raw \x1B codes
  DevLog.includeSource = true; // prepend [file:line] to every message
  DevLog.minPriority = LogPriority.ui; // log everything

  // Basic leveled logging.
  DevLog.ui('HomeScreen built');
  DevLog.storage('Token loaded from disk');
  DevLog.info('App started');
  DevLog.success('Initialization complete');
  DevLog.api('GET /users/1 -> 200');
  DevLog.warn('Cache is stale');

  // Error with exception + stack trace (great for DevTools).
  try {
    throw StateError('Profile not found');
  } catch (e, s) {
    DevLog.error('Failed to load profile', error: e, stackTrace: s);
  }

  // Tagged logging without a scoped instance.
  DevLog.info('Charge started', tag: 'Payment');

  // Scoped logger — auto-tags as INFO/Auth, SUCCESS/Auth, etc.
  authLog.info('Verifying credentials');
  authLog.success('Logged in');

  // Custom level.
  DevLog.log('Opening socket...', level: networkLevel);

  // Lazy message — builder only runs if the log passes the filter.
  DevLog.lazy(() => 'Expensive: ${_buildBigString()}', level: LogLevel.info);

  // Pretty JSON.
  DevLog.json(
    {
      'id': 1,
      'name': 'Sam',
      'roles': ['admin', 'editor'],
    },
    title: 'User payload',
    label: 'API',
  );

  runApp(const DemoApp());
}

String _buildBigString() => List.generate(3, (i) => 'row$i').join(', ');

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_devlog demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_devlog demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Open the debug console to see the logs.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => DevLog.info('Button tapped', tag: 'UI'),
                child: const Text('Log info'),
              ),
              ElevatedButton(
                onPressed: () => authLog.warn('Session about to expire'),
                child: const Text('Log scoped warning'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
