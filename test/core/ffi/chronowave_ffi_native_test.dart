import 'dart:io';

import 'package:chronowave_studio/src/core/ffi/chronowave_ffi.dart';
import 'package:chronowave_studio/src/domain/project/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the compiled Rust library when native FFI is required', () {
    final requireNative =
        Platform.environment['CHRONOWAVE_REQUIRE_NATIVE_FFI'] == 'true';
    if (!requireNative) {
      return;
    }

    final engine = ChronoWaveFfi.load();
    final result = engine.processTimelineSnapshot(
      _sampleProject(),
      phase: 'native-smoke',
    );

    expect(engine.isNativeAvailable, isTrue, reason: engine.loadError);
    expect(engine.nativeVersion, 'chronowave-core/0.1.0');
    expect(result.nativeLibraryUsed, isTrue);
    expect(result.accepted, isTrue);
    expect(result.code, 1);
  });
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
