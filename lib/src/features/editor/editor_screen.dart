import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database.dart';
import '../../core/ffi/chronowave_ffi.dart';
import '../../domain/project/project_model.dart';
import 'widgets/timeline_widget.dart';

TimelineClip trimTimelineClip(
  TimelineClip clip, {
  required int startMs,
  required int durationMs,
}) {
  if (startMs < 0) {
    throw ArgumentError.value(startMs, 'startMs', 'must be non-negative');
  }
  if (durationMs < 0) {
    throw ArgumentError.value(durationMs, 'durationMs', 'must be non-negative');
  }

  final sourceInMs = clip.sourceInMs + (startMs - clip.startMs);
  final sourceOutMs = sourceInMs + durationMs;
  if (sourceInMs < 0) {
    throw ArgumentError.value(
      startMs,
      'startMs',
      'trim would move sourceInMs before zero',
    );
  }
  if (sourceOutMs > clip.sourceOutMs) {
    throw ArgumentError.value(
      durationMs,
      'durationMs',
      'trim would extend beyond original sourceOutMs',
    );
  }

  return clip.copyWith(
    startMs: startMs,
    durationMs: durationMs,
    sourceInMs: sourceInMs,
    sourceOutMs: sourceOutMs,
  );
}

List<TimelineClip> splitTimelineClipAt(
  TimelineClip clip, {
  required int playheadMs,
  required String newClipId,
}) {
  final relativePlayheadMs = playheadMs - clip.startMs;
  if (relativePlayheadMs <= 0 || relativePlayheadMs >= clip.durationMs) {
    throw ArgumentError.value(
      playheadMs,
      'playheadMs',
      'must be inside the clip bounds',
    );
  }

  final secondSourceInMs = clip.sourceInMs + relativePlayheadMs;
  return [
    clip.copyWith(
      durationMs: relativePlayheadMs,
      sourceOutMs: secondSourceInMs,
    ),
    clip.copyWith(
      id: newClipId,
      startMs: playheadMs,
      durationMs: clip.durationMs - relativePlayheadMs,
      sourceInMs: secondSourceInMs,
    ),
  ];
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.projectId,
    required this.onBack,
  });

  final String projectId;
  final VoidCallback onBack;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  AppDatabase? _database;
  ChronoProject? _project;
  bool _isLoading = true;

  // Estados del reproductor
  bool _isPlaying = false;
  int _currentMs = 0;
  Timer? _playbackTimer;
  String? _selectedClipId;
  final ChronoWaveFfi _timelineEngine = ChronoWaveFfi.instance;
  TimelineEngineResult? _lastEngineResult;
  bool _isSyncingEngine = false;

  // Media Bin local simulado (Stitch design)
  final List<Map<String, String>> _importedMedia = [
    {'name': 'Intro_Drone.mp4', 'dur': '00:15', 'res': '1080p'},
    {'name': 'Transition_Broll.mp4', 'dur': '00:12', 'res': '1080p'},
    {'name': 'Landscape_Pan.mp4', 'dur': '00:08', 'res': '4K'},
    {'name': 'Bg_Music.wav', 'dur': '02:30', 'res': 'Audio'},
  ];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    final db = await AppDatabase.getInstance();
    setState(() {
      _database = db;
    });
    _loadProject();

    // Escuchar cambios reactivos en la BD
    db.onChange.listen((_) {
      if (mounted) {
        _loadProject();
      }
    });
  }

  void _loadProject() {
    if (_database == null) return;
    try {
      final p = _database!.getProject(widget.projectId);
      if (p != null) {
        setState(() {
          _project = p;
          _isLoading = false;
        });

        // Generar clips por defecto si el proyecto está vacío
        if (p.clips.isEmpty && p.tracks.isNotEmpty) {
          _createDefaultClips(p);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading project: $e');
    }
  }

  void _createDefaultClips(ChronoProject p) {
    if (_database == null) return;

    // Crear clips iniciales para simular datos reales como en las pantallas de Stitch
    final videoTrack = p.tracks.firstWhere((t) => t.type == TrackType.video);
    final audioTrack = p.tracks.firstWhere((t) => t.type == TrackType.audio);
    final textTrack = p.tracks.firstWhere((t) => t.type == TrackType.text);

    final introClip = TimelineClip(
      id: 'clip_vid_${p.id}',
      trackId: videoTrack.id,
      startMs: 0,
      durationMs: 15000, // 15 segundos
      sourceInMs: 0,
      sourceOutMs: 15000,
    );

    final musicClip = TimelineClip(
      id: 'clip_aud_${p.id}',
      trackId: audioTrack.id,
      startMs: 0,
      durationMs: 25000, // 25 segundos
      sourceInMs: 0,
      sourceOutMs: 25000,
    );

    final textClip = TimelineClip(
      id: 'clip_txt_${p.id}',
      trackId: textTrack.id,
      startMs: 5000, // Empieza en el segundo 5
      durationMs: 10000, // Dura 10 segundos
      sourceInMs: 0,
      sourceOutMs: 10000,
    );

    _database!.saveClip(introClip);
    _database!.saveClip(musicClip);
    _database!.saveClip(textClip);
  }

  // --- Controles del Reproductor ---

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _syncTimelineWithEngine('preview');
      if (!mounted) return;

      setState(() {
        _isPlaying = true;
      });
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (!mounted) return;
        setState(() {
          if (_project != null && _currentMs >= _project!.durationMs) {
            _currentMs = 0; // Loop o Stop
            _playbackTimer?.cancel();
            _isPlaying = false;
          } else {
            _currentMs += 100;
          }
        });
      });
    }
  }

  Future<TimelineEngineResult?> _syncTimelineWithEngine(String phase) async {
    final project = _project;
    if (project == null) return null;

    setState(() {
      _isSyncingEngine = true;
    });

    final result = _timelineEngine.processTimelineSnapshot(
      project,
      phase: phase,
    );
    if (!mounted) return result;

    setState(() {
      _lastEngineResult = result;
      _isSyncingEngine = false;
    });
    return result;
  }

  void _seek(int ms) {
    setState(() {
      if (_project != null) {
        _currentMs = ms.clamp(0, _project!.durationMs);
      } else {
        _currentMs = ms;
      }
    });
  }

  void _splitClip() {
    if (_selectedClipId == null || _database == null || _project == null) {
      return;
    }

    try {
      final clip = _project!.clips.firstWhere((c) => c.id == _selectedClipId);
      final int relativePlayhead = _currentMs - clip.startMs;

      // Solo dividir si la playhead corta el clip en el medio
      if (relativePlayhead > 1000 &&
          relativePlayhead < clip.durationMs - 1000) {
        final String newClipId =
            'clip_split_${DateTime.now().millisecondsSinceEpoch}';

        final halves = splitTimelineClipAt(
          clip,
          playheadMs: _currentMs,
          newClipId: newClipId,
        );

        _database!.saveClip(halves.first);
        _database!.saveClip(halves.last);
        _syncTimelineWithEngine('edit');

        setState(() {
          _selectedClipId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF111827),
            content: Row(
              children: [
                const Icon(Icons.content_cut_rounded, color: Color(0xFF00D4FF)),
                const SizedBox(width: 12),
                Text(
                  'Clip dividido exitosamente',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error splitting clip: $e');
    }
  }

  void _trimClip(String clipId, int startMs, int durationMs) {
    if (_database == null || _project == null) return;
    try {
      final clip = _project!.clips.firstWhere((c) => c.id == clipId);
      final updated = trimTimelineClip(
        clip,
        startMs: startMs,
        durationMs: durationMs,
      );

      _database!.saveClip(updated);
      _syncTimelineWithEngine('edit');
    } catch (e) {
      debugPrint('Error trimming clip: $e');
    }
  }

  // --- Formateo de Timecode ---

  String _formatTimecode(int ms) {
    final int totalSec = ms ~/ 1000;
    final int min = totalSec ~/ 60;
    final int sec = totalSec % 60;
    final int frames = (ms % 1000) ~/ 40; // 25 fps aprox

    final String minStr = min.toString().padLeft(2, '0');
    final String secStr = sec.toString().padLeft(2, '0');
    final String frameStr = frames.toString().padLeft(2, '0');

    return '00:$minStr:$secStr:$frameStr';
  }

  // --- Renderización UI ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E17),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
        ),
      );
    }

    if (_project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E17),
        body: Center(
          child: Text(
            'Error: Proyecto no encontrado.',
            style: GoogleFonts.sora(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout();
          } else {
            return _buildLandscapeLayout();
          }
        },
      ),
    );
  }

  // --- Maquetado PORTRAIT (Móvil vertical) ---

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Cabecera superior
        _buildHeaderBar(),

        // Visor de Video Player (Preview)
        _buildPlayerPreview(16 / 10),

        // Barra de Controles y Herramientas del Player
        _buildPlayerControlsBar(),

        // Línea de tiempo multitrack (50% inferior)
        Expanded(
          child: TimelineWidget(
            tracks: _project!.tracks,
            clips: _project!.clips,
            currentMs: _currentMs,
            projectDurationMs: _project!.durationMs,
            selectedClipId: _selectedClipId,
            onSeek: _seek,
            onClipSelected: (id) => setState(() => _selectedClipId = id),
            onClipTrim: _trimClip,
          ),
        ),
      ],
    );
  }

  // --- Maquetado LANDSCAPE (Móvil horizontal / Tableta / Escritorio) ---

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Navigation Rail a la izquierda extrema (Stitch design)
        _buildNavigationRail(),

        // Espacio principal del editor widescreen
        Expanded(
          child: Column(
            children: [
              // Barra superior minimalista
              _buildHeaderBarWidescreen(),

              // Mitad superior: Widescreen Split Row (Inspector/Media a la izq, Player a la der)
              Expanded(
                flex: 5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Columna Izquierda: Media Bin / Importador (Stitch layout)
                    Expanded(flex: 4, child: _buildMediaBinWidescreen()),

                    const VerticalDivider(color: Color(0xFF1E293B), width: 1),

                    // Columna Derecha: Player Preview
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Expanded(child: _buildPlayerPreview(16 / 9)),
                          _buildPlayerControlsBarWidescreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF1E293B), height: 1),

              // Mitad inferior: Timeline multitrack expandido horizontalmente
              Expanded(
                flex: 5,
                child: TimelineWidget(
                  tracks: _project!.tracks,
                  clips: _project!.clips,
                  currentMs: _currentMs,
                  projectDurationMs: _project!.durationMs,
                  selectedClipId: _selectedClipId,
                  onSeek: _seek,
                  onClipSelected: (id) => setState(() => _selectedClipId = id),
                  onClipTrim: _trimClip,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Sub-widgets reutilizables ---

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _project!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Proyecto Local',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF00D4FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.share_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBarWidescreen() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _project!.name,
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'WIDESCREEN RENDER',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF00D4FF),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            _formatTimecode(_currentMs),
            style: GoogleFonts.sora(
              color: const Color(0xFF00D4FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPreview(double aspectRatio) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pantalla de video simulada: degradado animado premium (Stitch style)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7B61FF).withValues(alpha: 0.35),
                    const Color(0xFF0A0E17),
                  ],
                  radius: 1.2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.movie_creation_outlined,
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                  size: 80,
                ),
              ),
            ),

            // Marca de agua de preview
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Color(0xFFFF6B9D), size: 8),
                    const SizedBox(width: 6),
                    Text(
                      'PREVIEW ACTIVO',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Timecode central flotante
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatTimecode(_currentMs),
                  style: GoogleFonts.sora(
                    color: const Color(0xFF00D4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Positioned(bottom: 12, left: 12, child: _buildEngineStatusBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineStatusBadge() {
    final result = _lastEngineResult;
    final diagnostic = _timelineEngine.mediaEngineDiagnostic;
    final label = _isSyncingEngine
        ? 'SINCRONIZANDO'
        : result == null
        ? diagnostic.statusLabel.toUpperCase()
        : result.modeLabel.toUpperCase();
    final color = result?.nativeLibraryUsed == true
        ? const Color(0xFF10B981)
        : diagnostic.nativeLibraryUsed
        ? const Color(0xFF00D4FF)
        : const Color(0xFF7B61FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.memory_rounded, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Herramienta de Cortar/Dividir
          IconButton(
            icon: Icon(
              Icons.content_cut_rounded,
              color: _selectedClipId != null
                  ? const Color(0xFF00D4FF)
                  : const Color(0xFF475569),
            ),
            tooltip: 'Dividir Clip Seleccionado',
            onPressed: _selectedClipId != null ? _splitClip : null,
          ),

          // Controles de reproducción principales
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                onPressed: () => _seek(_currentMs - 10000),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D4FF),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF0A0E17),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                onPressed: () => _seek(_currentMs + 10000),
              ),
            ],
          ),

          // Info de Calidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Text(
              '1080p 60fps',
              style: GoogleFonts.dmSans(
                color: const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControlsBarWidescreen() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.content_cut_rounded,
                  color: _selectedClipId != null
                      ? const Color(0xFF00D4FF)
                      : const Color(0xFF475569),
                  size: 18,
                ),
                onPressed: _selectedClipId != null ? _splitClip : null,
              ),
              Text(
                'DIVIDIR',
                style: GoogleFonts.dmSans(
                  color: _selectedClipId != null
                      ? const Color(0xFF00D4FF)
                      : const Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Controles Widescreen
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _seek(0),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00D4FF),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF0A0E17),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _seek(_project!.durationMs),
              ),
            ],
          ),

          // Volumen
          const Row(
            children: [
              Icon(Icons.volume_up_rounded, color: Color(0xFF64748B), size: 16),
              SizedBox(width: 6),
              Icon(
                Icons.fullscreen_rounded,
                color: Color(0xFF64748B),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBinWidescreen() {
    return Container(
      color: const Color(0xFF0A0E17),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Media Bin',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Color(0xFF7B61FF), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'IMPORTAR',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF7B61FF),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _importedMedia.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final media = _importedMedia[index];
                final isAudio = media['res'] == 'Audio';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: isAudio
                                ? [
                                    const Color(0xFF7B61FF),
                                    const Color(
                                      0xFF7B61FF,
                                    ).withValues(alpha: 0.5),
                                  ]
                                : [
                                    const Color(0xFF00D4FF),
                                    const Color(0xFF7B61FF),
                                  ],
                          ),
                        ),
                        child: Icon(
                          isAudio
                              ? Icons.audiotrack_rounded
                              : Icons.video_camera_back_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media['name']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Duración: ${media['dur']}  |  ${media['res']}',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF64748B),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo premium de onda
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.waves_rounded,
              color: Color(0xFF00D4FF),
              size: 20,
            ),
          ),
          const Spacer(),
          _buildRailItem(Icons.folder_copy_rounded, false),
          _buildRailItem(Icons.movie_filter_rounded, true),
          _buildRailItem(Icons.ios_share_rounded, false),
          _buildRailItem(Icons.settings_suggest_rounded, false),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRailItem(IconData icon, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Icon(
        icon,
        color: isActive ? const Color(0xFF00D4FF) : const Color(0xFF475569),
        size: 22,
      ),
    );
  }
}
