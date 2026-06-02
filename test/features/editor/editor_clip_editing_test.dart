import 'package:chronowave_studio/src/domain/project/project_model.dart';
import 'package:chronowave_studio/src/features/editor/editor_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const originalClip = TimelineClip(
    id: 'clip-original',
    trackId: 'track-video',
    assetId: 'asset-video',
    startMs: 1000,
    durationMs: 8000,
    sourceInMs: 2000,
    sourceOutMs: 10000,
    zIndex: 7,
    volume: 0.42,
    fadeInMs: 300,
    fadeOutMs: 450,
    effectConfigJson: '{"lut":"teal-orange"}',
    textConfigJson: '{"caption":"intro"}',
  );

  test(
    'trimTimelineClip preserves metadata and advances sourceIn on left trim',
    () {
      final trimmed = trimTimelineClip(
        originalClip,
        startMs: 2500,
        durationMs: 6500,
      );

      expect(trimmed.id, originalClip.id);
      expect(trimmed.trackId, originalClip.trackId);
      expect(trimmed.assetId, originalClip.assetId);
      expect(trimmed.startMs, 2500);
      expect(trimmed.durationMs, 6500);
      expect(trimmed.sourceInMs, 3500);
      expect(trimmed.sourceOutMs, 10000);
      expect(trimmed.zIndex, originalClip.zIndex);
      expect(trimmed.volume, originalClip.volume);
      expect(trimmed.fadeInMs, originalClip.fadeInMs);
      expect(trimmed.fadeOutMs, originalClip.fadeOutMs);
      expect(trimmed.effectConfigJson, originalClip.effectConfigJson);
      expect(trimmed.textConfigJson, originalClip.textConfigJson);
    },
  );

  test('trimTimelineClip rejects left trims before available source media', () {
    const clip = TimelineClip(
      id: 'clip-trim-left',
      trackId: 'track-video',
      startMs: 5000,
      durationMs: 4000,
      sourceInMs: 1000,
      sourceOutMs: 5000,
    );

    expect(
      () => trimTimelineClip(clip, startMs: 3000, durationMs: 4000),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('trimTimelineClip rejects trims beyond original sourceOut', () {
    expect(
      () => trimTimelineClip(originalClip, startMs: 2500, durationMs: 7000),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('splitTimelineClipAt preserves metadata across both clip halves', () {
    final halves = splitTimelineClipAt(
      originalClip,
      playheadMs: 4500,
      newClipId: 'clip-second-half',
    );

    expect(halves, hasLength(2));

    final firstHalf = halves.first;
    expect(firstHalf.id, originalClip.id);
    expect(firstHalf.trackId, originalClip.trackId);
    expect(firstHalf.assetId, originalClip.assetId);
    expect(firstHalf.startMs, originalClip.startMs);
    expect(firstHalf.durationMs, 3500);
    expect(firstHalf.sourceInMs, originalClip.sourceInMs);
    expect(firstHalf.sourceOutMs, 5500);
    expect(firstHalf.zIndex, originalClip.zIndex);
    expect(firstHalf.volume, originalClip.volume);
    expect(firstHalf.fadeInMs, originalClip.fadeInMs);
    expect(firstHalf.fadeOutMs, originalClip.fadeOutMs);
    expect(firstHalf.effectConfigJson, originalClip.effectConfigJson);
    expect(firstHalf.textConfigJson, originalClip.textConfigJson);

    final secondHalf = halves.last;
    expect(secondHalf.id, 'clip-second-half');
    expect(secondHalf.trackId, originalClip.trackId);
    expect(secondHalf.assetId, originalClip.assetId);
    expect(secondHalf.startMs, 4500);
    expect(secondHalf.durationMs, 4500);
    expect(secondHalf.sourceInMs, 5500);
    expect(secondHalf.sourceOutMs, originalClip.sourceOutMs);
    expect(secondHalf.zIndex, originalClip.zIndex);
    expect(secondHalf.volume, originalClip.volume);
    expect(secondHalf.fadeInMs, originalClip.fadeInMs);
    expect(secondHalf.fadeOutMs, originalClip.fadeOutMs);
    expect(secondHalf.effectConfigJson, originalClip.effectConfigJson);
    expect(secondHalf.textConfigJson, originalClip.textConfigJson);
  });
}
