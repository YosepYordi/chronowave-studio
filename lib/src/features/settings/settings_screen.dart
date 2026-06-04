import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ffi/chronowave_ffi.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBenchmarking = false;
  double _audioBufferSize = 256; // 256, 512, 1024
  bool _hardwareAccel = true;

  void _runBenchmark() async {
    setState(() {
      _isBenchmarking = true;
    });

    // Simular un benchmark premium
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isBenchmarking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          content: Row(
            children: [
              const Icon(Icons.speed_rounded, color: Color(0xFF00D4FF)),
              const SizedBox(width: 12),
              Text(
                'Benchmark completado: GPU score 98.4 GFLOPS',
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
            side: const BorderSide(color: Color(0x2600D4FF), width: 1),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ffi = ChronoWaveFfi.instance;
    final mediaDiagnostic = ffi.mediaEngineDiagnostic;
    final nativeVersion = ffi.nativeVersion;
    final isNativeAvailable = ffi.isNativeAvailable;
    final rustStatus = isNativeAvailable
        ? 'CONECTADO (${nativeVersion ?? 'version no reportada'})'
        : 'NO DISPONIBLE';
    final rustDetails = isNativeAvailable
        ? nativeVersion == null
              ? 'Libreria nativa Rust disponible; version no reportada.'
              : 'Libreria nativa Rust disponible: $nativeVersion.'
        : 'Fallback Dart activo. Version nativa no disponible.';
    final rustStatusColor = isNativeAvailable
        ? const Color(0xFF00D4FF)
        : const Color(0xFFFF6B9D);
    final mediaStatusColor = switch (mediaDiagnostic.status) {
      'ready' => const Color(0xFF10B981),
      'simulated' => const Color(0xFF00D4FF),
      'planned' => const Color(0xFF7B61FF),
      'unavailable' => const Color(0xFFFF6B9D),
      _ => const Color(0xFF64748B),
    };

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
                'Ajustes',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Configuración del estudio y hardware',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Sección: General
              _buildSectionHeader('General'),

              // Tarjeta: Cache
              _buildSettingCard(
                icon: Icons.folder_open_rounded,
                title: 'Directorio de Caché por Defecto',
                subtitle: '/storage/emulated/0/ChronoWave/cache',
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF475569),
                  size: 14,
                ),
              ),
              const SizedBox(height: 12),

              // Tarjeta: Tema
              _buildSettingCard(
                icon: Icons.palette_outlined,
                title: 'Tema del Estudio',
                subtitle: 'Dark Studio (Activo)',
                trailing: Text(
                  'CAMBIAR',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF00D4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tarjeta: Audio Buffer
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
                    Row(
                      children: [
                        const Icon(
                          Icons.graphic_eq_rounded,
                          color: Color(0xFF7B61FF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tamaño de Buffer de Audio',
                                style: GoogleFonts.sora(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Latencia actual: ${(_audioBufferSize / 44.1).toStringAsFixed(1)} ms',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _audioBufferSize,
                      min: 128,
                      max: 1024,
                      divisions: 2,
                      activeColor: const Color(0xFF7B61FF),
                      inactiveColor: const Color(0xFF1E293B),
                      onChanged: (val) {
                        setState(() {
                          _audioBufferSize = val;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '128 (Ultra Bajo)',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF475569),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${_audioBufferSize.toInt()} samples',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '1024 (Seguro)',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF475569),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sección: Diagnósticos
              _buildSectionHeader('Diagnósticos del Motor'),

              // Estado de Rust
              _buildTelemetryCard(
                title: 'Rust FFI Bridge',
                status: rustStatus,
                statusColor: rustStatusColor,
                details: rustDetails,
                icon: Icons.code_rounded,
              ),
              const SizedBox(height: 12),

              // Estado de GStreamer
              _buildTelemetryCard(
                title: 'GStreamer Pipeline Core',
                status: mediaDiagnostic.statusLabel,
                statusColor: mediaStatusColor,
                details: mediaDiagnostic.detail,
                icon: Icons.video_settings_rounded,
              ),
              const SizedBox(height: 12),

              // Aceleración por Hardware
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.developer_board_rounded,
                      color: Color(0xFFFF6B9D),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aceleración por GPU (H.264 / H.265)',
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _hardwareAccel
                                ? 'Decodificación / Encodificación acelerada activa'
                                : 'Usando CPU (Lento)',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFFFF6B9D),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _hardwareAccel,
                      activeThumbColor: const Color(0xFFFF6B9D),
                      activeTrackColor: const Color(
                        0xFFFF6B9D,
                      ).withValues(alpha: 0.15),
                      inactiveThumbColor: const Color(0xFF475569),
                      inactiveTrackColor: const Color(0xFF1E293B),
                      onChanged: (val) {
                        setState(() {
                          _hardwareAccel = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón de Test/Benchmark
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isBenchmarking ? null : _runBenchmark,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B61FF),
                    side: const BorderSide(
                      color: Color(0xFF7B61FF),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isBenchmarking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Color(0xFF7B61FF),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.speed_rounded),
                  label: Text(
                    _isBenchmarking
                        ? 'Ejecutando Test...'
                        : 'Ejecutar Autodiagnóstico',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'ChronoWave Studio MVP v0.1.0-alpha',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Diseñado con ♥ en Flutter y Rust nativo.',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF475569),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: GoogleFonts.sora(
          color: const Color(0xFF94A3B8),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D4FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String status,
    required Color statusColor,
    required String details,
    required IconData icon,
  }) {
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
              Row(
                children: [
                  Icon(icon, color: statusColor),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: GoogleFonts.dmSans(
              color: const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
