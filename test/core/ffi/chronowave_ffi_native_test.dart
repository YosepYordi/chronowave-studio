import 'dart:ffi';
import 'dart:io';

import 'package:chronowave_studio/src/core/ffi/chronowave_ffi.dart';
import 'package:chronowave_studio/src/domain/project/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final requireNative =
      Platform.environment['CHRONOWAVE_REQUIRE_NATIVE_FFI'] == 'true';
  final nativeSkipReason = requireNative
      ? false
      : 'Set CHRONOWAVE_REQUIRE_NATIVE_FFI=true to run native FFI tests.';

  test(
    'loads the compiled Rust library when native FFI is required',
    () {
      final engine = ChronoWaveFfi.load(library: _openCurrentNativeLibrary());
      final diagnostic = engine.mediaEngineDiagnostic;
      final result = engine.processTimelineSnapshot(
        _sampleProject(),
        phase: 'native-smoke',
      );

      expect(engine.isNativeAvailable, isTrue, reason: engine.loadError);
      expect(engine.nativeVersion, 'chronowave-core/0.1.0');
      expect(diagnostic.nativeLibraryUsed, isTrue);
      expect(diagnostic.engine, 'GStreamer/GES');
      expect(diagnostic.status, 'simulated');
      expect(diagnostic.nativeBindings, isFalse);
      expect(result.nativeLibraryUsed, isTrue);
      expect(result.accepted, isTrue);
      expect(result.code, 1);
    },
    skip: nativeSkipReason,
  );

  test(
    'keeps required native FFI when optional diagnostic is absent',
    () {
      final library = _buildLegacyNativeLibrary();
      final engine = ChronoWaveFfi.load(library: library);
      final diagnostic = engine.mediaEngineDiagnostic;
      final result = engine.processTimelineSnapshot(
        _sampleProject(),
        phase: 'legacy-native-smoke',
      );

      expect(engine.isNativeAvailable, isTrue, reason: engine.loadError);
      expect(engine.nativeVersion, 'chronowave-core/legacy');
      expect(diagnostic.status, 'unavailable');
      expect(diagnostic.nativeLibraryUsed, isTrue);
      expect(result.nativeLibraryUsed, isTrue);
      expect(result.accepted, isTrue);
      expect(result.code, 1);
    },
    skip: nativeSkipReason,
  );

  test(
    'keeps native FFI when optional diagnostic returns null',
    () {
      final library = _buildInvalidDiagnosticNativeLibrary();
      final engine = ChronoWaveFfi.load(library: library);
      final diagnostic = engine.mediaEngineDiagnostic;

      expect(engine.isNativeAvailable, isTrue, reason: engine.loadError);
      expect(diagnostic.status, 'unavailable');
      expect(diagnostic.nativeLibraryUsed, isTrue);
      expect(
        diagnostic.detail,
        contains('chronowave_media_engine_diagnostic returned null'),
      );
    },
    skip: nativeSkipReason,
  );
}

DynamicLibrary _buildLegacyNativeLibrary() {
  return _buildSyntheticNativeLibrary(
    name: 'chronowave_legacy_ffi',
    sourceCode: r'''
use std::ffi::c_char;

static VERSION: &[u8] = b"chronowave-core/legacy\0";

#[no_mangle]
pub extern "C" fn chronowave_core_version() -> *const c_char {
    VERSION.as_ptr().cast()
}

#[no_mangle]
pub extern "C" fn process_timeline_snapshot(_snapshot: *const c_char) -> i32 {
    1
}
''',
  );
}

DynamicLibrary _buildInvalidDiagnosticNativeLibrary() {
  return _buildSyntheticNativeLibrary(
    name: 'chronowave_invalid_diagnostic_ffi',
    sourceCode: r'''
use std::ffi::c_char;
use std::ptr;

static VERSION: &[u8] = b"chronowave-core/invalid-diagnostic\0";

#[no_mangle]
pub extern "C" fn chronowave_core_version() -> *const c_char {
    VERSION.as_ptr().cast()
}

#[no_mangle]
pub extern "C" fn process_timeline_snapshot(_snapshot: *const c_char) -> i32 {
    1
}

#[no_mangle]
pub extern "C" fn chronowave_media_engine_diagnostic() -> *const c_char {
    ptr::null()
}
''',
  );
}

DynamicLibrary _buildSyntheticNativeLibrary({
  required String name,
  required String sourceCode,
}) {
  final tempDirectory = Directory.systemTemp.createTempSync('${name}_');
  final separator = Platform.pathSeparator;
  final source = File('${tempDirectory.path}$separator$name.rs')
    ..writeAsStringSync(sourceCode);
  final libraryPath =
      '${tempDirectory.path}$separator${_libraryFileName(name)}';
  final result = Process.runSync('rustc', [
    '--crate-type=cdylib',
    '--crate-name=$name',
    source.path,
    '-o',
    libraryPath,
  ]);

  expect(
    result.exitCode,
    0,
    reason: 'rustc failed:\n${result.stdout}\n${result.stderr}',
  );

  final library = DynamicLibrary.open(libraryPath);
  addTearDown(() {
    library.close();
    tempDirectory.deleteSync(recursive: true);
  });
  return library;
}

String _libraryFileName(String name) {
  if (Platform.isWindows) return '$name.dll';
  if (Platform.isMacOS || Platform.isIOS) {
    return 'lib$name.dylib';
  }
  return 'lib$name.so';
}

DynamicLibrary _openCurrentNativeLibrary() {
  final separator = Platform.pathSeparator;
  final path =
      '${Directory.current.path}${separator}rust${separator}target'
      '${separator}debug$separator${_libraryFileName('chronowave_core')}';
  expect(
    File(path).existsSync(),
    isTrue,
    reason: 'Current native library is missing. Run cargo build first: $path',
  );
  return DynamicLibrary.open(path);
}

ChronoProject _sampleProject() {
  final now = DateTime.utc(2026, 5, 31, 22, 20);
  return ChronoProject(
    id: 'native-ffi-project',
    name: 'Native FFI Project',
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
    durationMs: 5000,
    syncState: ProjectSyncState.localOnly,
    tracks: const [
      ProjectTrack(
        id: 'track-video',
        projectId: 'native-ffi-project',
        type: TrackType.video,
        name: 'Video 1',
        orderIndex: 0,
      ),
    ],
    clips: const [
      TimelineClip(
        id: 'clip-video',
        trackId: 'track-video',
        startMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      ),
    ],
  );
}
