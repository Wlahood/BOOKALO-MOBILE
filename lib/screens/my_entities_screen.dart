import 'package:flutter/material.dart';

import '../repositories/me_repository.dart';
import '../services/api_client.dart';
import '../models/my_entity.dart';

import 'band_detail_screen.dart';
import 'venue_detail_screen.dart';

class MyEntitiesScreen extends StatefulWidget {
  const MyEntitiesScreen({super.key});

  @override
  State<MyEntitiesScreen> createState() => _MyEntitiesScreenState();
}

class _MyEntitiesScreenState extends State<MyEntitiesScreen> {
  late final MeRepository _repo;
  late Future<MeSummary> _future;

  @override
  void initState() {
    super.initState();
    _repo = MeRepository(ApiClient());
    _future = _repo.summary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('I miei spazi')),
      body: FutureBuilder<MeSummary>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(
              error: snap.error.toString(),
              onRetry: () => setState(() => _future = _repo.summary()),
            );
          }

          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'I miei locali / Le mie band',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${data.user.name} • ${data.user.email}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Locali',
                emptyText: 'Non gestisci ancora nessun locale.',
                items: data.venues,
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Band',
                emptyText: 'Non gestisci ancora nessuna band.',
                items: data.bands,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<MyEntity> items;
  final String emptyText;

  String _roleLabel(String? role) {
    if (role == null || role.isEmpty) return '—';
    return role.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
            else
              ...items.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e.type == 'venue'
                        ? Icons.store_mall_directory_outlined
                        : Icons.music_note_outlined,
                  ),
                  title: Text(e.name),
                  subtitle: Text('Ruolo: ${_roleLabel(e.role)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => e.type == 'venue'
                            ? VenueDetailScreen(venueId: e.id)
                            : BandDetailScreen(bandId: e.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Errore nel caricamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}
