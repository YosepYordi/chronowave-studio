import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GStreamer Windows preflight emits machine-readable status', () async {
    if (!Platform.isWindows) {
      return;
    }

    final script = File('tooling/gstreamer_windows_preflight.ps1');
    expect(
      script.existsSync(),
      isTrue,
      reason: 'Fase 5A necesita una verificacion local reproducible.',
    );

    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script.path,
      '-Json',
    ]);

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final decoded = jsonDecode(result.stdout as String);
    expect(decoded, isA<Map<String, Object?>>());

    final payload = decoded as Map<String, Object?>;
    expect(payload['status'], anyOf('ready', 'missing'));
    expect(payload['tools'], isA<List<Object?>>());
    expect(payload['next_steps'], isA<List<Object?>>());

    final tools = payload['tools'] as List<Object?>;
    expect(tools, hasLength(greaterThanOrEqualTo(3)));
    expect(
      tools.map((tool) => (tool as Map<String, Object?>)['name']),
      containsAll(['gst-launch-1.0', 'gst-inspect-1.0', 'pkg-config']),
    );
  });
}
