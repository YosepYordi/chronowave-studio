import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../projects/projects_screen.dart';
import '../editor/editor_screen.dart';
import '../export/export_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _selectedProjectId;

  void _onProjectSelected(String projectId) {
    setState(() {
      _selectedProjectId = projectId;
      _selectedIndex = 1; // Redirigir automáticamente a la pestaña de Editor
    });
  }

  void _clearSelectedProject() {
    setState(() {
      _selectedProjectId = null;
      _selectedIndex = 0; // Redirigir a la biblioteca de proyectos
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definir las pantallas correspondientes
    final List<Widget> screens = [
      ProjectsScreen(onProjectSelected: _onProjectSelected),
      _selectedProjectId != null
          ? EditorScreen(
              projectId: _selectedProjectId!,
              onBack: _clearSelectedProject,
            )
          : _buildNoProjectSelectedState(),
      ExportScreen(projectId: _selectedProjectId),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF111827)),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF1E293B), width: 1.0),
            ),
          ),
          child: NavigationBar(
            backgroundColor: const Color(0xFF111827),
            indicatorColor: const Color(0xFF00D4FF).withValues(alpha: 0.15),
            selectedIndex: _selectedIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 65,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(
                  Icons.video_library_outlined,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: const Icon(
                  Icons.video_library_rounded,
                  color: Color(0xFF00D4FF),
                ),
                label: 'Proyectos',
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.timeline_outlined,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: const Icon(
                  Icons.timeline_rounded,
                  color: Color(0xFF00D4FF),
                ),
                label: 'Editor',
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.ios_share_outlined,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: const Icon(
                  Icons.ios_share_rounded,
                  color: Color(0xFF00D4FF),
                ),
                label: 'Exportar',
              ),
              NavigationDestination(
                icon: const Icon(Icons.tune_outlined, color: Color(0xFF64748B)),
                selectedIcon: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF00D4FF),
                ),
                label: 'Ajustes',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoProjectSelectedState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                    border: Border.all(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.movie_creation_outlined,
                    size: 48,
                    color: Color(0xFF7B61FF),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Editor de Video Inactivo',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Para empezar a editar en el Timeline multitrack, selecciona o crea un proyecto en la pestaña "Proyectos".',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // Llevar a la biblioteca
                    });
                  },
                  child: Text(
                    'Ver biblioteca de proyectos',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
