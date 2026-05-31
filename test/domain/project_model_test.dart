import 'package:chronowave_studio/src/domain/project/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a local project snapshot with media, tracks, and clips', () {
    final createdAt = DateTime.utc(2026, 5, 30, 16, 50);

    final project = ChronoProject(
      id: 'project-1',
      name: 'Launch reel',
      createdAt: createdAt,
      updatedAt: createdAt,
      schemaVersion: 1,
      durationMs: 12000,
      syncState: ProjectSyncState.localOnly,
      assets: [
        MediaAsset(
          id: 'asset-1',
          projectId: 'project-1',
          type: MediaAssetType.video,
          originalUri: 'content://media/external/video/1',
          localPath: 'projects/project-1/media/clip.mp4',
          displayName: 'clip.mp4',
          durationMs: 12000,
          width: 1920,
          height: 1080,
          createdAt: createdAt,
        ),
      ],
      tracks: [
        ProjectTrack(
          id: 'track-1',
          projectId: 'project-1',
          type: TrackType.video,
          name: 'Video 1',
          orderIndex: 0,
        ),
      ],
      clips: [
        TimelineClip(
          id: 'clip-1',
          trackId: 'track-1',
          assetId: 'asset-1',
          startMs: 0,
          durationMs: 12000,
          sourceInMs: 0,
          sourceOutMs: 12000,
        ),
      ],
    );

    expect(project.isLocalOnly, isTrue);
    expect(project.assets.single.type, MediaAssetType.video);
    expect(project.tracks.single.type, TrackType.video);
    expect(project.clips.single.endMs, 12000);
  });

  test('normalizes track volume and clip timing boundaries', () {
    const track = ProjectTrack(
      id: 'track-audio',
      projectId: 'project-1',
      type: TrackType.audio,
      name: 'Voiceover',
      orderIndex: 1,
      volume: 1.25,
    );

    const clip = TimelineClip(
      id: 'clip-audio',
      trackId: 'track-audio',
      startMs: 250,
      durationMs: 1750,
      sourceInMs: 500,
      sourceOutMs: 2250,
      volume: -0.5,
      fadeInMs: 200,
      fadeOutMs: 300,
    );

    expect(track.normalizedVolume, 1);
    expect(clip.normalizedVolume, 0);
    expect(clip.endMs, 2000);
    expect(clip.sourceDurationMs, 1750);
  });
}
