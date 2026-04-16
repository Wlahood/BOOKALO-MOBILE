import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event_detail.dart';
import '../repositories/events_repository.dart';
import '../services/api_client.dart';
import 'band_detail_screen.dart';
import 'venue_detail_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late final EventsRepository repo;

  bool loading = true;
  EventDetail? event;
  String? error;

  @override
  void initState() {
    super.initState();
    repo = EventsRepository(ApiClient());
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final e = await repo.fetchEvent(widget.eventId);
      if (!mounted) return;
      setState(() => event = e);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> openUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openMaps(EventDetail e) async {
    final venueName = e.venue?.name.trim() ?? '';
    final city = e.venue?.location?.name?.trim() ?? '';
    final province = e.venue?.location?.provinceCode?.trim() ?? '';
    final region = e.venue?.location?.region?.trim() ?? '';

    final queryParts = <String>[
      if (venueName.isNotEmpty) venueName,
      if (city.isNotEmpty) city,
      if (province.isNotEmpty) province,
      if (region.isNotEmpty) region,
    ];

    if (queryParts.isEmpty) return;

    final query = queryParts.join(', ');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> shareEvent(EventDetail e) async {
    final textParts = <String>[
      e.title,
      if (e.start != null) _formatDateOnly(e.start!),
      if ((e.venue?.name ?? '').trim().isNotEmpty) e.venue!.name,
      if (e.webUrl.trim().isNotEmpty) e.webUrl.trim(),
    ];

    await SharePlus.instance.share(ShareParams(text: textParts.join('\n')));
  }

  String _formatDateOnly(DateTime? dt) {
    if (dt == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  String _formatVenueLine(EventDetail e) {
    final venueName = e.venue?.name.trim() ?? '';
    final city = e.venue?.location?.name?.trim() ?? '';
    final province = e.venue?.location?.provinceCode?.trim() ?? '';

    final tail = <String>[
      if (city.isNotEmpty) city,
      if (province.isNotEmpty) '($province)',
    ].join(' ');

    if (venueName.isNotEmpty && tail.isNotEmpty) {
      return '$venueName — $tail';
    }
    if (venueName.isNotEmpty) return venueName;
    return tail;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evento')),
        body: Center(child: Text(error!)),
      );
    }

    final e = event!;
    final venueLine = _formatVenueLine(e);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evento'),
        actions: [
          IconButton(
            tooltip: 'Condividi',
            onPressed: () => shareEvent(e),
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: 'Apri mappa',
            onPressed: () => openMaps(e),
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if ((e.posterImageUrl ?? '').trim().isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Image.network(
                    e.posterImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(e.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (e.start != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateOnly(e.start),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            if (venueLine.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final venue = e.venue;
                  if (venue == null) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VenueDetailScreen(venueId: venue.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          venueLine,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ],
            if (e.bands.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Band partecipanti',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: e.bands
                    .map(
                      (b) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BandDetailScreen(bandId: b.id),
                            ),
                          );
                        },
                        child: Chip(label: Text(b.name)),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => shareEvent(e),
                    icon: const Icon(Icons.share),
                    label: const Text('Condividi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openMaps(e),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Apri mappa'),
                  ),
                ),
              ],
            ),
            if ((e.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Descrizione',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(e.description!),
            ],
            if (e.webUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => openUrl(e.webUrl),
                child: const Text('Apri sul sito'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
