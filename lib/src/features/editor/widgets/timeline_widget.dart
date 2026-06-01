import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/project/project_model.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({
    super.key,
    required this.tracks,
    required this.clips,
    required this.currentMs,
    required this.projectDurationMs,
    required this.onSeek,
    required this.onClipSelected,
    required this.selectedClipId,
    required this.onClipTrim,
  });

  final List<ProjectTrack> tracks;
  final List<TimelineClip> clips;
  final int currentMs;
  final int projectDurationMs;
  final Function(int ms) onSeek;
  final Function(String? clipId) onClipSelected;
  final String? selectedClipId;
  final Function(String clipId, int startMs, int durationMs) onClipTrim;

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  double _msPerPixel = 50.0; // Factor de zoom (50ms por pixel por defecto)
  final ScrollController _scrollController = ScrollController();
  bool _isDraggingPlayhead = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Convertir milisegundos a pixeles
  double _msToX(int ms) {
    return ms / _msPerPixel;
  }

  // Convertir pixeles a milisegundos
  int _xToMs(double x) {
    return (x * _msPerPixel).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final double timelineWidth = _msToX(widget.projectDurationMs);
    final double playheadX = _msToX(widget.currentMs);

    return Container(
      color: const Color(0xFF060A12), // Fondo de timeline más oscuro de Stitch
      child: Column(
        children: [
          // Barra de Herramientas de Timeline (Zoom / Edición)
          _buildTimelineToolbar(),

          // Línea de tiempo con scroll horizontal
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              physics: _isDraggingPlayhead
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              child: SizedBox(
                width: math.max(
                  timelineWidth + 200,
                  MediaQuery.of(context).size.width,
                ), // Ancho dinámico + margen final
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Grid y Regla Temporal (Ruler)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 35,
                      child: _buildRuler(timelineWidth),
                    ),

                    // Pistas del Timeline
                    Positioned(
                      top: 35,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildTracks(timelineWidth),
                    ),

                    // Playhead interactiva
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: playheadX - 1, // Centrar la línea
                      child: _buildPlayhead(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineToolbar() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E17),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.zoom_in_rounded,
                color: Color(0xFF64748B),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'ZOOM TIMELINE',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          // Control deslizante de Zoom (ms/px)
          SizedBox(
            width: 140,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbColor: const Color(0xFF00D4FF),
                activeTrackColor: const Color(0xFF00D4FF),
                inactiveTrackColor: const Color(0xFF1E293B),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: 1050.0 - _msPerPixel, // Invertir escala
                min: 50.0,
                max: 1000.0,
                onChanged: (val) {
                  setState(() {
                    _msPerPixel = 1050.0 - val;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuler(double timelineWidth) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => setState(() => _isDraggingPlayhead = true),
      onHorizontalDragUpdate: (details) {
        final double relativeX = details.localPosition.dx;
        final int targetMs = _xToMs(
          relativeX,
        ).clamp(0, widget.projectDurationMs);
        widget.onSeek(targetMs);
      },
      onHorizontalDragEnd: (_) => setState(() => _isDraggingPlayhead = false),
      onTapDown: (details) {
        final double relativeX = details.localPosition.dx;
        final int targetMs = _xToMs(
          relativeX,
        ).clamp(0, widget.projectDurationMs);
        widget.onSeek(targetMs);
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0E17),
          border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
        ),
        child: Stack(
          children: [
            // Líneas de tiempo secundarias y etiquetas de segundos
            ...List.generate((widget.projectDurationMs / 1000).ceil() + 1, (i) {
              final double x = _msToX(i * 1000);
              return Positioned(
                left: x,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${i}s',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF475569),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 1,
                      height: i % 5 == 0 ? 8 : 4,
                      color: const Color(0xFF1E293B),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTracks(double timelineWidth) {
    return Stack(
      children: [
        // Líneas de cuadrícula verticales de fondo
        ...List.generate((widget.projectDurationMs / 1000).ceil() + 1, (i) {
          if (i % 5 != 0) return const SizedBox.shrink(); // Solo cada 5s
          final double x = _msToX(i * 1000);
          return Positioned(
            left: x,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1,
              color: const Color(0xFF111827).withValues(alpha: 0.4),
            ),
          );
        }),

        // Filas de pistas reales
        Column(
          children: widget.tracks.map((track) {
            final trackClips = widget.clips
                .where((c) => c.trackId == track.id)
                .toList();
            return _buildTrackRow(track, trackClips, timelineWidth);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrackRow(
    ProjectTrack track,
    List<TimelineClip> trackClips,
    double timelineWidth,
  ) {
    double rowHeight = 70.0;
    Color trackAccent = Colors.grey;
    IconData trackIcon = Icons.movie_creation_outlined;

    if (track.type == TrackType.video) {
      rowHeight = 75.0;
      trackAccent = const Color(0xFF00D4FF);
      trackIcon = Icons.movie_filter_rounded;
    } else if (track.type == TrackType.audio) {
      rowHeight = 65.0;
      trackAccent = const Color(0xFF7B61FF);
      trackIcon = Icons.audiotrack_rounded;
    } else if (track.type == TrackType.text) {
      rowHeight = 55.0;
      trackAccent = const Color(0xFFFF6B9D);
      trackIcon = Icons.text_fields_rounded;
    }

    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF111827))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera estática de pista a la izquierda (en horizontal se amplía, en vertical es minimalista)
          Container(
            width: 75,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E17).withValues(alpha: 0.8),
              border: const Border(right: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  trackIcon,
                  color: trackAccent.withValues(alpha: 0.8),
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  track.name.split(' ').last, // Pista 1, Audio 1, etc.
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Contenedor de Clips
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: trackClips
                  .map(
                    (clip) =>
                        _buildClipWidget(clip, trackAccent, rowHeight - 16),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipWidget(
    TimelineClip clip,
    Color accentColor,
    double clipHeight,
  ) {
    final double left = _msToX(clip.startMs);
    final double width = _msToX(clip.durationMs);
    final isSelected = widget.selectedClipId == clip.id;

    String clipName = 'Clip';
    Widget bodyContent = const SizedBox.shrink();

    if (accentColor == const Color(0xFF00D4FF)) {
      clipName = clip.id.contains('proj')
          ? 'Clip_Video.mp4'
          : 'Intro_Drone.mp4';
      // Simular miniaturas internas para video
      bodyContent = Row(
        children: List.generate((width / 40).floor().clamp(1, 8), (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B),
                    accentColor.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          );
        }),
      );
    } else if (accentColor == const Color(0xFF7B61FF)) {
      clipName = 'Bg_Music.wav';
      // Waveform violeta brillante simulada
      bodyContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: CustomPaint(
          size: Size(width, clipHeight),
          painter: WaveformPainter(color: accentColor),
        ),
      );
    } else if (accentColor == const Color(0xFFFF6B9D)) {
      clipName = 'ChronoWave Overlay';
      bodyContent = Center(
        child: Text(
          '"TEXT OVERLAY"',
          style: GoogleFonts.dmSans(
            color: accentColor.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      );
    }

    return Positioned(
      left: left,
      top: 8,
      width: math.max(width, 40.0), // Ancho mínimo seguro
      height: clipHeight,
      child: GestureDetector(
        onTap: () {
          widget.onClipSelected(isSelected ? null : clip.id);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00D4FF)
                  : accentColor.withValues(alpha: 0.35),
              width: isSelected ? 2.2 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Contenido visual interno
              Positioned.fill(child: bodyContent),

              // Nombre superior
              Positioned(
                top: 4,
                left: 8,
                child: Text(
                  clipName,
                  style: GoogleFonts.sora(
                    color: isSelected
                        ? const Color(0xFF00D4FF)
                        : Colors.white.withValues(alpha: 0.85),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Recortadores / Handles laterales en modo seleccionado
              if (isSelected) ...[
                // Manejador izquierdo
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 8,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      final double deltaX = details.delta.dx;
                      final int deltaMs = _xToMs(deltaX);
                      final int newStart = (clip.startMs + deltaMs).clamp(
                        0,
                        clip.endMs - 1000,
                      );
                      final int newDuration = clip.endMs - newStart;
                      widget.onClipTrim(clip.id, newStart, newDuration);
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D4FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                        ),
                      ),
                      child: const Center(
                        child: VerticalDivider(
                          color: Color(0xFF0A0E17),
                          width: 2,
                          thickness: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Manejador derecho
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 8,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      final double deltaX = details.delta.dx;
                      final int deltaMs = _xToMs(deltaX);
                      final int newDuration = (clip.durationMs + deltaMs).clamp(
                        1000,
                        widget.projectDurationMs - clip.startMs,
                      );
                      widget.onClipTrim(clip.id, clip.startMs, newDuration);
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D4FF),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                      ),
                      child: const Center(
                        child: VerticalDivider(
                          color: Color(0xFF0A0E17),
                          width: 2,
                          thickness: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayhead() {
    return Column(
      children: [
        // Cabeza circular brillante
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D4FF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0A0E17),
              ),
            ),
          ),
        ),
        // Línea vertical que corta las pistas
        Expanded(
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Pintor personalizado para dibujar la waveform de audio violeta brillante
class WaveformPainter extends CustomPainter {
  WaveformPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double midY = size.height / 2.0;
    final int lineCount = (size.width / 4).floor();
    final random = math.Random(42); // Seed para consistencia

    for (int i = 0; i < lineCount; i++) {
      final double x = i * 4.0 + 2.0;
      final double amplitude = 8.0 + random.nextDouble() * (size.height - 20.0);
      final double top = midY - amplitude / 2.0;
      final double bottom = midY + amplitude / 2.0;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
