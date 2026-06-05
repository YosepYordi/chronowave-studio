import 'package:chronowave_studio/src/core/ffi/chronowave_ffi.dart';
import 'package:chronowave_studio/src/domain/project/project_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads ChronoWave Rust FFI library on Android device', (
    tester,
  ) async {
    final engine = ChronoWaveFfi.load();
    final diagnostic = engine.mediaEngineDiagnostic;
    final result = engine.processTimelineSnapshot(
      _sampleProject(),
      phase: 'android-device-smoke',
    );

    expect(engine.isNativeAvailable, isTrue, reason: engine.loadError);
    expect(engine.nativeVersion, 'chronowave-core/0.1.0');
    expect(diagnostic.nativeLibraryUsed, isTrue);
    expect(diagnostic.engine, 'GStreamer/GES');
    expect(result.nativeLibraryUsed, isTrue);
    expect(result.accepted, isTrue);
  });
}

ChronoProject _sampleProject() {
  final now = DateTime.utc(2026, 6, 2, 23, 0);
  return ChronoProject(
    id: 'android-ffi-project',
    name: 'Android FFI Project',
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
    durationMs: 5000,
    syncState: ProjectSyncState.localOnly,
    tracks: const [
      ProjectTrack(
        id: 'track-video',
        projectId: 'android-ffi-project',
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
