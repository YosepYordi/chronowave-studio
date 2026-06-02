import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Directory, File, Platform;

import 'package:ffi/ffi.dart';

import '../../domain/project/project_model.dart';

typedef _ProcessTimelineSnapshotNative = Int32 Function(Pointer<Utf8>);
typedef _ProcessTimelineSnapshotDart = int Function(Pointer<Utf8>);
typedef _CoreVersionNative = Pointer<Utf8> Function();
typedef _CoreVersionDart = Pointer<Utf8> Function();
typedef _MediaEngineDiagnosticNative = Pointer<Utf8> Function();
typedef _MediaEngineDiagnosticDart = Pointer<Utf8> Function();

class MediaEngineDiagnostic {
  const MediaEngineDiagnostic({
    required this.engine,
    required this.status,
    required this.mode,
    required this.nativeBindings,
    required this.nativeLibraryUsed,
    required this.detail,
  });

  final String engine;
  final String status;
  final String mode;
  final bool nativeBindings;
  final bool nativeLibraryUsed;
  final String detail;

  String get statusLabel {
    if (nativeBindings) return '$engine listo';
    if (nativeLibraryUsed) return '$engine simulado';
    return '$engine planificado';
  }

  factory MediaEngineDiagnostic.fromJson(
    Map<String, Object?> json, {
    required bool nativeLibraryUsed,
  }) {
    return MediaEngineDiagnostic(
      engine: (json['engine'] as String?) ?? 'GStreamer/GES',
      status: (json['status'] as String?) ?? 'unknown',
      mode: (json['mode'] as String?) ?? 'unknown',
      nativeBindings: (json['native_bindings'] as bool?) ?? false,
      nativeLibraryUsed: nativeLibraryUsed,
      detail: (json['detail'] as String?) ?? 'Diagnostico sin detalle.',
    );
  }

  factory MediaEngineDiagnostic.fallback(String? loadError) {
    return MediaEngineDiagnostic(
      engine: 'GStreamer/GES',
      status: 'planned',
      mode: 'dart-fallback',
      nativeBindings: false,
      nativeLibraryUsed: false,
      detail: loadError == null || loadError.isEmpty
          ? 'Libreria Rust pendiente; usando diagnostico Dart.'
          : 'Libreria Rust no disponible: $loadError',
    );
  }
}

class TimelineEngineResult {
  const TimelineEngineResult({
    required this.code,
    required this.phase,
    required this.nativeLibraryUsed,
    required this.trackCount,
    required this.clipCount,
    required this.snapshotByteLength,
    required this.message,
  });

  final int code;
  final String phase;
  final bool nativeLibraryUsed;
  final int trackCount;
  final int clipCount;
  final int snapshotByteLength;
  final String message;

  bool get accepted => code == 1 || code == 100;

  String get modeLabel => nativeLibraryUsed ? 'Rust FFI' : 'Dart fallback';
}

class ChronoWaveFfi {
  ChronoWaveFfi._({
    DynamicLibrary? library,
    _ProcessTimelineSnapshotDart? processTimelineSnapshot,
    _CoreVersionDart? coreVersion,
    _MediaEngineDiagnosticDart? mediaEngineDiagnostic,
    this.loadError,
  }) : _library = library,
       _processTimelineSnapshot = processTimelineSnapshot,
       _coreVersion = coreVersion,
       _mediaEngineDiagnostic = mediaEngineDiagnostic;

  factory ChronoWaveFfi.load({DynamicLibrary? library}) {
    try {
      final resolvedLibrary = library ?? _openBundledOrSystemLibrary();
      return ChronoWaveFfi._(
        library: resolvedLibrary,
        processTimelineSnapshot: resolvedLibrary
            .lookupFunction<
              _ProcessTimelineSnapshotNative,
              _ProcessTimelineSnapshotDart
            >('process_timeline_snapshot'),
        coreVersion: resolvedLibrary
            .lookupFunction<_CoreVersionNative, _CoreVersionDart>(
              'chronowave_core_version',
            ),
        mediaEngineDiagnostic: resolvedLibrary
            .lookupFunction<
              _MediaEngineDiagnosticNative,
              _MediaEngineDiagnosticDart
            >('chronowave_media_engine_diagnostic'),
      );
    } catch (error) {
      return ChronoWaveFfi.fallback(error.toString());
    }
  }

  factory ChronoWaveFfi.fallback([String? loadError]) {
    return ChronoWaveFfi._(loadError: loadError);
  }

  static ChronoWaveFfi? _instance;

  static ChronoWaveFfi get instance => _instance ??= ChronoWaveFfi.load();

  static set instanceForTesting(ChronoWaveFfi? engine) {
    _instance = engine;
  }

  final DynamicLibrary? _library;
  final _ProcessTimelineSnapshotDart? _processTimelineSnapshot;
  final _CoreVersionDart? _coreVersion;
  final _MediaEngineDiagnosticDart? _mediaEngineDiagnostic;
  final String? loadError;

  bool get isNativeAvailable =>
      _library != null && _processTimelineSnapshot != null;

  String? get nativeVersion {
    final versionLookup = _coreVersion;
    if (versionLookup == null) return null;

    final versionPointer = versionLookup();
    if (versionPointer == nullptr) return null;
    return versionPointer.toDartString();
  }

  MediaEngineDiagnostic get mediaEngineDiagnostic {
    final diagnosticLookup = _mediaEngineDiagnostic;
    if (diagnosticLookup == null) {
      return MediaEngineDiagnostic.fallback(loadError);
    }

    try {
      final diagnosticPointer = diagnosticLookup();
      if (diagnosticPointer == nullptr) {
        return MediaEngineDiagnostic.fallback(
          'chronowave_media_engine_diagnostic returned null',
        );
      }

      final decoded = jsonDecode(diagnosticPointer.toDartString());
      if (decoded is! Map<String, Object?>) {
        return MediaEngineDiagnostic.fallback(
          'chronowave_media_engine_diagnostic returned non-object JSON',
        );
      }

      return MediaEngineDiagnostic.fromJson(
        decoded,
        nativeLibraryUsed: isNativeAvailable,
      );
    } catch (error) {
      return MediaEngineDiagnostic.fallback(error.toString());
    }
  }

  TimelineEngineResult processTimelineSnapshot(
    ChronoProject project, {
    required String phase,
  }) {
    final snapshot = buildTimelineSnapshot(project, phase: phase);
    final snapshotJson = jsonEncode(snapshot);
    final snapshotByteLength = utf8.encode(snapshotJson).length;
    final trackCount = (snapshot['tracks'] as List<Object?>).length;
    final clipCount = (snapshot['clips'] as List<Object?>).length;

    final processTimelineSnapshot = _processTimelineSnapshot;
    if (processTimelineSnapshot == null) {
      final code = trackCount > 0 ? 1 : 0;
      return TimelineEngineResult(
        code: code,
        phase: phase,
        nativeLibraryUsed: false,
        trackCount: trackCount,
        clipCount: clipCount,
        snapshotByteLength: snapshotByteLength,
        message: code == 1
            ? 'Snapshot aceptado por simulacion Dart; libreria Rust pendiente.'
            : 'Snapshot rechazado por simulacion Dart: no contiene pistas.',
      );
    }

    final snapshotPointer = snapshotJson.toNativeUtf8();
    try {
      final code = processTimelineSnapshot(snapshotPointer);
      return TimelineEngineResult(
        code: code,
        phase: phase,
        nativeLibraryUsed: true,
        trackCount: trackCount,
        clipCount: clipCount,
        snapshotByteLength: snapshotByteLength,
        message: code == 1 || code == 100
            ? 'Snapshot aceptado por Rust FFI.'
            : 'Rust FFI rechazo el snapshot con codigo $code.',
      );
    } finally {
      calloc.free(snapshotPointer);
    }
  }

  static String get _libraryFileName {
    if (Platform.isWindows) return 'chronowave_core.dll';
    if (Platform.isAndroid || Platform.isLinux) return 'libchronowave_core.so';
    if (Platform.isMacOS || Platform.isIOS) return 'libchronowave_core.dylib';
    return 'chronowave_core';
  }

  static DynamicLibrary _openBundledOrSystemLibrary() {
    final errors = <String>[];

    for (final candidate in _libraryCandidates()) {
      try {
        return DynamicLibrary.open(candidate);
      } catch (error) {
        errors.add('$candidate: $error');
      }
    }

    throw StateError(
      'No se pudo cargar la libreria nativa ChronoWave. ${errors.join(' | ')}',
    );
  }

  static List<String> _libraryCandidates() {
    final libraryFileName = _libraryFileName;
    final envPath = Platform.environment['CHRONOWAVE_CORE_LIBRARY'];
    final candidates = <String>[];

    if (envPath != null && envPath.trim().isNotEmpty) {
      candidates.add(envPath.trim());
    }

    if (Platform.isWindows) {
      final cwd = Directory.current.path;
      candidates.addAll(
        [
          '$cwd\\rust\\target\\release\\$libraryFileName',
          '$cwd\\rust\\target\\debug\\$libraryFileName',
          '$cwd\\rust\\target\\release\\deps\\$libraryFileName',
          '$cwd\\rust\\target\\debug\\deps\\$libraryFileName',
        ].where((path) => File(path).existsSync()),
      );
    }

    candidates.add(libraryFileName);
    return candidates;
  }
}

Map<String, Object?> buildTimelineSnapshot(
  ChronoProject project, {
  required String phase,
}) {
  final tracks = [...project.tracks]
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  final clips = [...project.clips]
    ..sort((a, b) => a.startMs.compareTo(b.startMs));

  return {
    'schema_version': project.schemaVersion,
    'phase': phase,
    'project': {
      'id': project.id,
      'name': project.name,
      'duration_ms': project.durationMs,
      'updated_at': project.updatedAt.toIso8601String(),
      'sync_state': project.syncState.name,
    },
    'assets': project.assets.map(_mediaAssetToJson).toList(growable: false),
    'tracks': tracks.map(_trackToJson).toList(growable: false),
    'clips': clips.map(_clipToJson).toList(growable: false),
  };
}

Map<String, Object?> _mediaAssetToJson(MediaAsset asset) {
  return {
    'id': asset.id,
    'project_id': asset.projectId,
    'type': asset.type.name,
    'original_uri': asset.originalUri,
    'local_path': asset.localPath,
    'display_name': asset.displayName,
    'duration_ms': asset.durationMs,
    'width': asset.width,
    'height': asset.height,
    'sample_rate': asset.sampleRate,
    'channels': asset.channels,
    'created_at': asset.createdAt.toIso8601String(),
    'checksum': asset.checksum,
  };
}

Map<String, Object?> _trackToJson(ProjectTrack track) {
  return {
    'id': track.id,
    'project_id': track.projectId,
    'type': track.type.name,
    'name': track.name,
    'order_index': track.orderIndex,
    'muted': track.muted,
    'locked': track.locked,
    'visible': track.visible,
    'volume': track.normalizedVolume,
  };
}

Map<String, Object?> _clipToJson(TimelineClip clip) {
  return {
    'id': clip.id,
    'track_id': clip.trackId,
    'asset_id': clip.assetId,
    'start_ms': clip.startMs,
    'duration_ms': clip.durationMs,
    'end_ms': clip.endMs,
    'source_in_ms': clip.sourceInMs,
    'source_out_ms': clip.sourceOutMs,
    'z_index': clip.zIndex,
    'volume': clip.normalizedVolume,
    'fade_in_ms': clip.fadeInMs,
    'fade_out_ms': clip.fadeOutMs,
    'effect_config_json': clip.effectConfigJson,
    'text_config_json': clip.textConfigJson,
  };
}
