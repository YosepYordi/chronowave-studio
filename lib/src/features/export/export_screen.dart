import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database.dart';
import '../../core/ffi/chronowave_ffi.dart';
import '../../domain/project/project_model.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _nameController = TextEditingController(text: 'My_Awesome_Edit_v1.mp4');
  String _selectedResolution = '1080p'; // 1080p, 4k, 720p
  int _selectedFps = 60; // 30, 60
  String _selectedBitrate = 'High'; // Standard, High, Custom
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _elapsedTime = '00:00';
  String _remainingTime = '00:00';
  String _renderingClip = '';
  AppDatabase? _database;
  ChronoProject? _activeProject;
  final ChronoWaveFfi _timelineEngine = ChronoWaveFfi.instance;
  TimelineEngineResult? _engineResult;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void didUpdateWidget(covariant ExportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _loadActiveProject();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    final db = await AppDatabase.getInstance();
    if (!mounted) return;

    setState(() {
      _database = db;
    });
    _loadActiveProject();
  }

  void _loadActiveProject() {
    final db = _database;
    final projectId = widget.projectId;
    if (db == null || projectId == null) {
      setState(() {
        _activeProject = null;
      });
      return;
    }

    setState(() {
      _activeProject = db.getProject(projectId);
    });
  }

  void _startExport() async {
    if (_isExporting) return;
    final project = _activeProject;

    if (project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF00D4FF)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Selecciona un proyecto antes de exportar.',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final engineResult = _timelineEngine.processTimelineSnapshot(
      project,
      phase: 'export',
    );
    if (!engineResult.accepted) {
      setState(() {
        _engineResult = engineResult;
        _renderingClip = engineResult.message;
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _elapsedTime = '00:00';
      _remainingTime = '00:25';
      _renderingClip = 'Inicializando tuberías GStreamer...';
    });

    setState(() {
      _engineResult = engineResult;
      _renderingClip =
          '${engineResult.modeLabel}: snapshot validado para render.';
    });

    // Simular un proceso de renderizado reactivo y vistoso
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      setState(() {
        _exportProgress = i / 100.0;
        final elapsed = (i * 0.15).toInt();
        final remaining = ((100 - i) * 0.15).toInt();

        _elapsedTime = '00:${elapsed.toString().padLeft(2, '0')}';
        _remainingTime = '00:${remaining.toString().padLeft(2, '0')}';

        if (i < 20) {
          _renderingClip =
              '${engineResult.modeLabel}: cargando ${engineResult.trackCount} pistas del timeline...';
        } else if (i < 50) {
          _renderingClip =
              'Procesando ${engineResult.clipCount} clips desde snapshot JSON...';
        } else if (i < 80) {
          _renderingClip =
              'Mezclando pistas de audio (Bg_Music.wav) a 48kHz...';
        } else {
          _renderingClip =
              'Codificando fotogramas finales mediante GPU H.264...';
        }
      });
    }

    if (mounted) {
      setState(() {
        _renderingClip = '¡Renderizado completado con éxito!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Text(
                'Video exportado en /ChronoWave/exports/',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0x2610B981), width: 1.5),
          ),
        ),
      );

      // Terminar estado
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportProgress = 0.0;
          _engineResult = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Cabecera Sora
              Text(
                'Exportar Video',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Elige la calidad y compila tu video final',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Nombre de archivo Glassmorphic
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre del Archivo',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF00D4FF),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00D4FF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selector de Resolución (Grilla)
              Text(
                'Resolución de Salida',
                style: GoogleFonts.sora(
                  color: const Color(0xFF94A3B8),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildResolutionCard(
                    '1080p',
                    'Full HD',
                    'Recomendado',
                    const Color(0xFF00D4FF),
                  ),
                  _buildResolutionCard(
                    '4K',
                    'Ultra HD',
                    'Ultra Premium',
                    const Color(0xFF7B61FF),
                  ),
                  _buildResolutionCard(
                    '720p',
                    'Standard HD',
                    'Espacio Bajo',
                    const Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ajustes avanzados (Segmented Controls)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frame Rate',
                          style: GoogleFonts.sora(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSegmentedControl(
                          options: [30, 60],
                          selected: _selectedFps,
                          onSelected: (val) {
                            setState(() {
                              _selectedFps = val as int;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bitrate de Render',
                          style: GoogleFonts.sora(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSegmentedControl(
                          options: ['Standard', 'High', 'Custom'],
                          selected: _selectedBitrate,
                          onSelected: (val) {
                            setState(() {
                              _selectedBitrate = val as String;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Estado del Renderizado Activo
              if (_isExporting) ...[
                _buildActiveRenderPanel(),
                const SizedBox(height: 30),
              ],

              // CTA Iniciar Exportación
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _startExport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isExporting
                            ? [const Color(0xFF1E293B), const Color(0xFF1E293B)]
                            : [
                                const Color(0xFF00D4FF),
                                const Color(0xFF7B61FF),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isExporting
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(
                                  0xFF00D4FF,
                                ).withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        _isExporting
                            ? 'EXPORTANDO PROYECTO...'
                            : 'INICIAR EXPORTACIÓN',
                        style: GoogleFonts.sora(
                          color: _isExporting
                              ? const Color(0xFF64748B)
                              : const Color(0xFF0A0E17),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResolutionCard(
    String id,
    String label,
    String subtitle,
    Color accentColor,
  ) {
    final isSelected = _selectedResolution == id.toLowerCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedResolution = id.toLowerCase();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFF1E293B),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF475569),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                    boxShadow: [BoxShadow(color: accentColor, blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<dynamic> options,
    required dynamic selected,
    required Function(dynamic) onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    opt.toString(),
                    style: GoogleFonts.dmSans(
                      color: isSelected
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFF64748B),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveRenderPanel() {
    final progressPct = (_exportProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Render en Curso',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$progressPct%',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF00D4FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progreso con resplandor
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _exportProgress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF00D4FF)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detalles técnicos
          Text(
            _renderingClip,
            style: GoogleFonts.dmSans(
              color: const Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_engineResult != null) ...[
            const SizedBox(height: 6),
            Text(
              '${_engineResult!.modeLabel} · ${_engineResult!.snapshotByteLength} bytes · codigo ${_engineResult!.code}',
              style: GoogleFonts.dmSans(
                color: const Color(0xFF7B61FF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transcurrido: $_elapsedTime',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
              Text(
                'Restante: $_remainingTime',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E293B), height: 20),

          // Tamaño de archivo estimado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tamaño Estimado de Salida:',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
              Text(
                _selectedResolution == '4k'
                    ? '745.8 MB'
                    : _selectedResolution == '720p'
                    ? '92.4 MB'
                    : '184.2 MB',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFFFF6B9D),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
