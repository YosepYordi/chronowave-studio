import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/database.dart';
import '../../domain/project/project_model.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, required this.onProjectSelected});

  final Function(String projectId) onProjectSelected;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  AppDatabase? _database;
  List<ChronoProject> _projects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _activeFilter = 'All'; // All, Recientes, Favoritos, Templates

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final db = await AppDatabase.getInstance();
    setState(() {
      _database = db;
    });
    _loadProjects();

    // Escuchar cambios reactivos en la BD
    db.onChange.listen((_) {
      if (mounted) {
        _loadProjects();
      }
    });
  }

  void _loadProjects() {
    if (_database == null) return;
    try {
      final list = _database!.getProjects();
      setState(() {
        _projects = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading projects: $e');
    }
  }

  List<ChronoProject> get _filteredProjects {
    var filtered = _projects;

    // Filtro por texto
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Filtros de categoría de Stitch
    if (_activeFilter == 'Recientes') {
      // Filtrar proyectos editados en las últimas 24 horas o simplemente tomar los 3 más recientes
      filtered = filtered.take(3).toList();
    } else if (_activeFilter == 'Favoritos') {
      // En un MVP simulamos favoritos con los proyectos que tengan ID impar
      filtered = filtered.where((p) => p.id.hashCode % 2 == 0).toList();
    } else if (_activeFilter == 'Templates') {
      // Templates vacíos en el MVP
      filtered = [];
    }

    return filtered;
  }

  Future<void> _createNewProject() async {
    if (_database == null) return;

    final nameController = TextEditingController(text: 'Nuevo Proyecto Wave');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x2600D4FF), width: 1.5),
          ),
          title: Text(
            'Nuevo Proyecto',
            style: GoogleFonts.sora(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              style: GoogleFonts.dmSans(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre del Proyecto',
                labelStyle: GoogleFonts.dmSans(color: const Color(0xFF94A3B8)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00D4FF)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre no puede estar vacío';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.dmSans(color: const Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: const Color(0xFF0A0E17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(
                'Crear',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (created == true) {
      final id = 'proj_${DateTime.now().millisecondsSinceEpoch}';
      final name = nameController.text.trim();

      // Crear proyecto con pistas base
      final newProj = ChronoProject(
        id: id,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        schemaVersion: 1,
        durationMs: 30000, // 30 segundos por defecto
        syncState: ProjectSyncState.localOnly,
        thumbnailPath: 'placeholder',
        tracks: [
          ProjectTrack(
            id: 'track_vid_$id',
            projectId: id,
            type: TrackType.video,
            name: 'Pista de Video 1',
            orderIndex: 0,
          ),
          ProjectTrack(
            id: 'track_aud_$id',
            projectId: id,
            type: TrackType.audio,
            name: 'Pista de Audio 1',
            orderIndex: 1,
          ),
          ProjectTrack(
            id: 'track_txt_$id',
            projectId: id,
            type: TrackType.text,
            name: 'Pista de Subtítulos',
            orderIndex: 2,
          ),
        ],
      );

      _database!.saveProject(newProj);

      // Abrir editor
      widget.onProjectSelected(id);
    }
  }

  void _deleteProject(String id) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x26FF6B9D), width: 1.5),
        ),
        title: Text(
          'Eliminar Proyecto',
          style: GoogleFonts.sora(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar este proyecto? Esta acción no se puede deshacer.',
          style: GoogleFonts.dmSans(color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmSans(color: const Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _database?.deleteProject(id);
              Navigator.pop(context);
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProjects;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Encabezado premium con Sora
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ChronoWave',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Studio Engine v0.1.0',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF00D4FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Botón "Nuevo Proyecto" tipo Stitch
                  GestureDetector(
                    onTap: _createNewProject,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00D4FF,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Color(0xFF0A0E17),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Buscador elegante
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  style: GoogleFonts.dmSans(color: Colors.white),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF94A3B8),
                    ),
                    hintText: 'Buscar proyectos...',
                    hintStyle: GoogleFonts.dmSans(
                      color: const Color(0xFF475569),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Chips de filtrado
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Recientes', 'Favoritos', 'Templates'].map((
                    filter,
                  ) {
                    final isActive = _activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isActive,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _activeFilter = filter;
                            });
                          }
                        },
                        selectedColor: const Color(
                          0xFF00D4FF,
                        ).withValues(alpha: 0.15),
                        backgroundColor: const Color(0xFF111827),
                        labelStyle: GoogleFonts.dmSans(
                          color: isActive
                              ? const Color(0xFF00D4FF)
                              : const Color(0xFF94A3B8),
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isActive
                                ? const Color(0xFF00D4FF)
                                : const Color(0xFF1E293B),
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Lista de Proyectos o Estado Vacío
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00D4FF),
                        ),
                      )
                    : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: filtered.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final proj = filtered[index];
                          return _buildProjectCard(proj);
                        },
                      ),
              ),

              // Indicador de Almacenamiento
              _buildStorageIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D4FF).withValues(alpha: 0.1),
                    const Color(0xFF7B61FF).withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 40,
                color: Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin Proyectos Aún',
              style: GoogleFonts.sora(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Crea tu primer espacio de edición multitrack tocando el botón de arriba.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: const Color(0xFF00D4FF),
                side: const BorderSide(color: Color(0xFF00D4FF), width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Crear Espacio',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(ChronoProject proj) {
    final durationSec = (proj.durationMs / 1000).toStringAsFixed(1);
    final dateStr =
        '${proj.updatedAt.day}/${proj.updatedAt.month}/${proj.updatedAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onProjectSelected(proj.id),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Miniatura con gradiente estilizado (Stitch design)
              Container(
                width: 90,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B61FF),
                      const Color(0xFF00D4FF).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 28,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${durationSec}s',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Información del proyecto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proj.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '1080p60',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF94A3B8),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Editado: $dateStr',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menú de opciones
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                onPressed: () {
                  _showOptionsSheet(proj.id, proj.name);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(String id, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Color(0xFF1E293B)),
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF00D4FF),
                  ),
                  title: Text(
                    'Abrir en Editor',
                    style: GoogleFonts.dmSans(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onProjectSelected(id);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF6B9D),
                  ),
                  title: Text(
                    'Eliminar',
                    style: GoogleFonts.dmSans(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProject(id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStorageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Almacenamiento Local',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
              Text(
                '8.2 GB de 128 GB usados',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.064, // ~6.4%
              backgroundColor: Color(0xFF111827),
              color: Color(0xFF00D4FF),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
