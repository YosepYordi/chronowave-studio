import 'package:flutter_test/flutter_test.dart';
import 'package:chronowave_studio/src/core/database/database.dart';
import 'package:chronowave_studio/src/domain/project/project_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de Base de Datos (Modo Testing en Memoria)', () {
    late AppDatabase db;

    setUp(() async {
      // Activar modo simulación para consola nativa
      AppDatabase.isTesting = true;
      db = await AppDatabase.getInstance();
    });

    test('Creación e inserción exitosa de un proyecto completo', () {
      final projectId = 'proj_test_123';
      
      final project = ChronoProject(
        id: projectId,
        name: 'Mi Primer Cortometraje',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        schemaVersion: 1,
        durationMs: 60000,
        syncState: ProjectSyncState.localOnly,
        thumbnailPath: 'thumbs/test.png',
        tracks: [
          ProjectTrack(
            id: 'track_vid_$projectId',
            projectId: projectId,
            type: TrackType.video,
            name: 'Pista de Video Principal',
            orderIndex: 0,
          ),
          ProjectTrack(
            id: 'track_aud_$projectId',
            projectId: projectId,
            type: TrackType.audio,
            name: 'Pista de Audio Estéreo',
            orderIndex: 1,
          ),
        ],
        clips: [
          TimelineClip(
            id: 'clip_vid_1',
            trackId: 'track_vid_$projectId',
            startMs: 0,
            durationMs: 15000,
            sourceInMs: 0,
            sourceOutMs: 15000,
          ),
        ],
      );

      // Guardar
      db.saveProject(project);

      // Recuperar por ID
      final retrieved = db.getProject(projectId);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Mi Primer Cortometraje'));
      expect(retrieved.durationMs, equals(60000));
      expect(retrieved.thumbnailPath, equals('thumbs/test.png'));

      // Validar pistas asociadas reales persistidas
      expect(retrieved.tracks.length, equals(2));
      expect(retrieved.tracks.first.name, equals('Pista de Video Principal'));
      expect(retrieved.tracks.first.type, equals(TrackType.video));

      // Validar clips asociados
      expect(retrieved.clips.length, equals(1));
      expect(retrieved.clips.first.id, equals('clip_vid_1'));
      expect(retrieved.clips.first.durationMs, equals(15000));
    });

    test('Edición y Trimming de clips en el Timeline', () {
      final projectId = 'proj_trim_test';
      final trackId = 'track_vid_$projectId';
      final clipId = 'clip_trim_1';

      final project = ChronoProject(
        id: projectId,
        name: 'Proyecto Recorte',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        schemaVersion: 1,
        durationMs: 30000,
        syncState: ProjectSyncState.localOnly,
        tracks: [
          ProjectTrack(
            id: trackId,
            projectId: projectId,
            type: TrackType.video,
            name: 'Video Track',
            orderIndex: 0,
          ),
        ],
        clips: [],
      );

      db.saveProject(project);

      // Guardar clip nuevo
      final clip = TimelineClip(
        id: clipId,
        trackId: trackId,
        startMs: 2000,
        durationMs: 6000,
        sourceInMs: 2000,
        sourceOutMs: 8000,
      );

      db.saveClip(clip);

      // Recuperar y validar cambios
      final retrieved = db.getProject(projectId);
      expect(retrieved!.clips.length, equals(1));
      
      final retrievedClip = retrieved.clips.first;
      expect(retrievedClip.startMs, equals(2000));
      expect(retrievedClip.durationMs, equals(6000));
      expect(retrievedClip.endMs, equals(8000));
    });

    test('Eliminación de proyectos', () async {
      final projectId = 'proj_delete_cascade';
      
      final project = ChronoProject(
        id: projectId,
        name: 'Proyecto Efímero',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        schemaVersion: 1,
        durationMs: 10000,
        syncState: ProjectSyncState.localOnly,
        tracks: [],
        clips: [],
      );

      db.saveProject(project);

      // Comprobar existencia en BD
      expect(db.getProject(projectId), isNotNull);

      // Eliminar proyecto
      db.deleteProject(projectId);

      // Comprobar eliminación
      expect(db.getProject(projectId), isNull);
    });
  });
}
