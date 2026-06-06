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

  test('GStreamer setup keeps installer downloads outside the repo', () {
    final script = File('tooling/setup_gstreamer.ps1');
    expect(script.existsSync(), isTrue);

    final contents = script.readAsStringSync();
    expect(contents, contains('[IO.Path]::GetTempPath()'));
    expect(contents, isNot(contains('.gstreamer_temp')));
  });

  test('GStreamer setup verifies downloaded installer checksums', () {
    final script = File('tooling/setup_gstreamer.ps1');
    expect(script.existsSync(), isTrue);

    final contents = script.readAsStringSync();
    expect(contents, contains('.sha256sum'));
    expect(contents, contains('Get-FileHash'));
    expect(contents, contains('Installer hash mismatch'));
  });

  test('GStreamer setup uses a retrying downloader when available', () {
    final script = File('tooling/setup_gstreamer.ps1');
    expect(script.existsSync(), isTrue);

    final contents = script.readAsStringSync();
    expect(contents, contains('curl.exe'));
    expect(contents, contains('--retry'));
    expect(contents, contains('--fail'));
  });

  test('GStreamer setup checks free disk space before install', () {
    final script = File('tooling/setup_gstreamer.ps1');
    expect(script.existsSync(), isTrue);

    final contents = script.readAsStringSync();
    expect(contents, contains('RequiredFreeGB'));
    expect(contents, contains('Assert-PathDriveHasFreeSpace'));
    expect(contents, contains('requires at least'));
  });

  test('GStreamer setup env loads usable paths into the current process', () {
    final script = File('tooling/setup_env.ps1');
    expect(script.existsSync(), isTrue);

    final contents = script.readAsStringSync();
    expect(contents, contains(r'$env:GSTREAMER_1_0_ROOT_MSVC_X86_64'));
    expect(contents, contains(r'$env:PKG_CONFIG_PATH'));
    expect(contents, contains(r'$env:PATH'));
  });
}
