import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChronoWave Studio')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          _ProjectStatusCard(
            title: 'Android first',
            description: 'Mobile editor baseline targeting Android 10+.',
          ),
          SizedBox(height: 12),
          _ProjectStatusCard(
            title: 'Flutter + Rust + GStreamer/GES',
            description: 'UI, portable core, and planned multimedia engine.',
          ),
          SizedBox(height: 12),
          _ProjectStatusCard(
            title: 'Local projects ready for future sync',
            description: 'Offline-first project data with cloud-ready IDs.',
          ),
        ],
      ),
    );
  }
}

class _ProjectStatusCard extends StatelessWidget {
  const _ProjectStatusCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}
