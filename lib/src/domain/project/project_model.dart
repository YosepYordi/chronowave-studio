enum ProjectSyncState { localOnly, pendingUpload, synced, conflict }

enum MediaAssetType { video, audio, image }

enum TrackType { video, audio, text }

class ChronoProject {
  const ChronoProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
    required this.durationMs,
    required this.syncState,
    this.thumbnailPath,
    this.assets = const [],
    this.tracks = const [],
    this.clips = const [],
  }) : assert(durationMs >= 0),
       assert(schemaVersion > 0);

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;
  final int durationMs;
  final String? thumbnailPath;
  final ProjectSyncState syncState;
  final List<MediaAsset> assets;
  final List<ProjectTrack> tracks;
  final List<TimelineClip> clips;

  bool get isLocalOnly => syncState == ProjectSyncState.localOnly;
}

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.projectId,
    required this.type,
    required this.originalUri,
    required this.localPath,
    required this.displayName,
    required this.durationMs,
    required this.createdAt,
    this.width,
    this.height,
    this.sampleRate,
    this.channels,
    this.checksum,
  }) : assert(durationMs >= 0),
       assert(width == null || width > 0),
       assert(height == null || height > 0),
       assert(sampleRate == null || sampleRate > 0),
       assert(channels == null || channels > 0);

  final String id;
  final String projectId;
  final MediaAssetType type;
  final String originalUri;
  final String localPath;
  final String displayName;
  final int durationMs;
  final int? width;
  final int? height;
  final int? sampleRate;
  final int? channels;
  final DateTime createdAt;
  final String? checksum;
}

class ProjectTrack {
  const ProjectTrack({
    required this.id,
    required this.projectId,
    required this.type,
    required this.name,
    required this.orderIndex,
    this.muted = false,
    this.locked = false,
    this.visible = true,
    this.volume = 1,
  }) : assert(orderIndex >= 0);

  final String id;
  final String projectId;
  final TrackType type;
  final String name;
  final int orderIndex;
  final bool muted;
  final bool locked;
  final bool visible;
  final double volume;

  double get normalizedVolume => _clampUnit(volume);
}

class TimelineClip {
  const TimelineClip({
    required this.id,
    required this.trackId,
    required this.startMs,
    required this.durationMs,
    required this.sourceInMs,
    required this.sourceOutMs,
    this.assetId,
    this.zIndex = 0,
    this.volume = 1,
    this.fadeInMs = 0,
    this.fadeOutMs = 0,
    this.effectConfigJson,
    this.textConfigJson,
  }) : assert(startMs >= 0),
       assert(durationMs >= 0),
       assert(sourceInMs >= 0),
       assert(sourceOutMs >= sourceInMs),
       assert(fadeInMs >= 0),
       assert(fadeOutMs >= 0);

  final String id;
  final String trackId;
  final String? assetId;
  final int startMs;
  final int durationMs;
  final int sourceInMs;
  final int sourceOutMs;
  final int zIndex;
  final double volume;
  final int fadeInMs;
  final int fadeOutMs;
  final String? effectConfigJson;
  final String? textConfigJson;

  int get endMs => startMs + durationMs;

  int get sourceDurationMs => sourceOutMs - sourceInMs;

  double get normalizedVolume => _clampUnit(volume);

  static const Object _unset = Object();

  TimelineClip copyWith({
    String? id,
    String? trackId,
    Object? assetId = _unset,
    int? startMs,
    int? durationMs,
    int? sourceInMs,
    int? sourceOutMs,
    int? zIndex,
    double? volume,
    int? fadeInMs,
    int? fadeOutMs,
    Object? effectConfigJson = _unset,
    Object? textConfigJson = _unset,
  }) {
    return TimelineClip(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      assetId: assetId == _unset ? this.assetId : assetId as String?,
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
      sourceInMs: sourceInMs ?? this.sourceInMs,
      sourceOutMs: sourceOutMs ?? this.sourceOutMs,
      zIndex: zIndex ?? this.zIndex,
      volume: volume ?? this.volume,
      fadeInMs: fadeInMs ?? this.fadeInMs,
      fadeOutMs: fadeOutMs ?? this.fadeOutMs,
      effectConfigJson: effectConfigJson == _unset
          ? this.effectConfigJson
          : effectConfigJson as String?,
      textConfigJson: textConfigJson == _unset
          ? this.textConfigJson
          : textConfigJson as String?,
    );
  }
}

double _clampUnit(double value) => value.clamp(0, 1).toDouble();
