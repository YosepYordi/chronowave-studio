import 'package:chronowave_studio/src/core/ffi/chronowave_ffi.dart';
import 'package:chronowave_studio/src/domain/project/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a stable timeline snapshot for Rust', () {
    final project = _sampleProject();

    final snapshot = buildTimelineSnapshot(project, phase: 'preview');
    final tracks = snapshot['tracks'] as List<Object?>;
    final clips = snapshot['clips'] as List<Object?>;

    expect(snapshot['schema_version'], 1);
    expect(snapshot['phase'], 'preview');
    expect(tracks.length, 2);
    expect(clips.length, 1);
    expect((tracks.first as Map<String, Object?>)['type'], 'video');
    expect((clips.first as Map<String, Object?>)['duration_ms'], 4000);
  });

  test('uses Dart fallback when the native library is unavailable', () {
    final engine = ChronoWaveFfi.fallback('missing native library');

    final result = engine.processTimelineSnapshot(
      _sampleProject(),
      phase: 'export',
    );

    expect(result.nativeLibraryUsed, isFalse);
    expect(result.accepted, isTrue);
    expect(result.code, 1);
    expect(result.trackCount, 2);
    expect(result.clipCount, 1);
    expect(result.snapshotByteLength, greaterThan(0));
  });

  test('rejects malformed snapshots without tracks in fallback mode', () {
    final engine = ChronoWaveFfi.fallback('missing native library');
    final project = ChronoProject(
      id: 'empty-project',
      name: 'Empty Project',
      createdAt: DateTime.utc(2026, 5, 31),
      updatedAt: DateTime.utc(2026, 5, 31),
      schemaVersion: 1,
      durationMs: 0,
      syncState: ProjectSyncState.localOnly,
    );

    final result = engine.processTimelineSnapshot(project, phase: 'export');

    expect(result.nativeLibraryUsed, isFalse);
    expect(result.accepted, isFalse);
    expect(result.code, 0);
  });
}

ChronoProject _sampleProject() {
  final now = DateTime.utc(2026, 5, 31, 20, 0);
  return ChronoProject(
    id: 'project-ffi',
    name: 'FFI Smoke',
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
    durationMs: 8000,
    syncState: ProjectSyncState.localOnly,
    tracks: const [
      ProjectTrack(
        id: 'track-video',
        projectId: 'project-ffi',
        type: TrackType.video,
        name: 'Video 1',
        orderIndex: 0,
      ),
      ProjectTrack(
        id: 'track-audio',
        projectId: 'project-ffi',
        type: TrackType.audio,
        name: 'Audio 1',
        orderIndex: 1,
      ),
    ],
    clips: const [
      TimelineClip(
        id: 'clip-video',
        trackId: 'track-video',
        startMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      ),
    ],
  );
}
