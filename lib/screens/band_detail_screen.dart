import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/band_detail.dart';
import '../repositories/bands_repository.dart';
import '../services/api_client.dart';

import '../models/events_page.dart';
import '../repositories/events_repository.dart';
import 'event_detail_screen.dart';

class BandDetailScreen extends StatefulWidget {
  const BandDetailScreen({super.key, required this.bandId});
  final int bandId;

  @override
  State<BandDetailScreen> createState() => _BandDetailScreenState();
}

class _BandDetailScreenState extends State<BandDetailScreen> {
  late final BandsRepository repo;

  bool loading = true;
  String? error;
  BandDetail? band;

  late final EventsRepository eventsRepo;

  bool eventsLoading = true;
  String? eventsError;
  List<EventListItem> upcoming = const [];

  String _yyyyMmDd(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  void initState() {
    super.initState();
    repo = BandsRepository(ApiClient());
    eventsRepo = EventsRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final b = await repo.fetchBand(widget.bandId);
      setState(() => band = b);
      await _loadUpcomingEvents(b.id);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadUpcomingEvents(int bandId) async {
    setState(() {
      eventsLoading = true;
      eventsError = null;
    });

    final now = DateTime.now();
    final startDate = _yyyyMmDd(now);
    final endDate = _yyyyMmDd(now.add(const Duration(days: 30)));

    try {
      final list = await eventsRepo.fetchBandUpcomingEvents(
        bandId: bandId,
        startDate: startDate,
        endDate: endDate,
        perPage: 20,
      );
      setState(() => upcoming = list);
    } catch (e) {
      setState(() => eventsError = e.toString());
    } finally {
      setState(() => eventsLoading = false);
    }
  }

  String _locationLine(LocationMini? l) {
    if (l == null) return '';
    final parts = <String>[
      l.name,
      if ((l.provinceCode ?? '').isNotEmpty) '(${l.provinceCode})',
      if ((l.region ?? '').isNotEmpty) l.region!,
    ];
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Band')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(error!),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Riprova')),
              ],
            )
          : _BandBody(
              band: band!,
              locationLine: _locationLine,
              openExternal: _openExternal,
              openMail: _openMail,
              eventsLoading: eventsLoading,
              eventsError: eventsError,
              upcoming: upcoming,
            ),
    );
  }
}

class _BandBody extends StatelessWidget {
  const _BandBody({
    required this.band,
    required this.locationLine,
    required this.openExternal,
    required this.openMail,
    required this.eventsLoading,
    required this.eventsError,
    required this.upcoming,
  });

  final BandDetail band;
  final String Function(LocationMini?) locationLine;
  final Future<void> Function(String) openExternal;
  final Future<void> Function(String) openMail;

  final bool eventsLoading;
  final String? eventsError;
  final List<EventListItem> upcoming;

  @override
  Widget build(BuildContext context) {
    final loc = locationLine(band.location);

    final links = <MapEntry<String, String>>[];
    void addLink(String label, String? url) {
      final u = (url ?? '').trim();
      if (u.isEmpty) return;
      links.add(MapEntry(label, u));
    }

    addLink('Sito', band.website);
    addLink('Instagram', band.socials['instagram']);
    addLink('Facebook', band.socials['facebook']);
    addLink('YouTube', band.socials['youtube']);
    addLink('Spotify', band.socials['spotify']);
    addLink('SoundCloud', band.socials['soundcloud']);
    addLink('Bandcamp', band.socials['bandcamp']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: (band.imageUrl ?? '').isNotEmpty
                  ? NetworkImage(band.imageUrl!)
                  : null,
              child: (band.imageUrl ?? '').isEmpty
                  ? const Icon(Icons.group)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          band.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (band.verified) const Icon(Icons.verified, size: 20),
                    ],
                  ),
                  if (loc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(loc)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (band.genres.isNotEmpty) ...[
          Text('Generi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: band.genres
                .map((g) => Chip(label: Text(g.name)))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        if ((band.bio ?? '').trim().isNotEmpty) ...[
          Text('Bio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(band.bio!.trim()),
          const SizedBox(height: 16),
        ],

        if ((band.email ?? '').trim().isNotEmpty) ...[
          ElevatedButton.icon(
            onPressed: () => openMail(band.email!.trim()),
            icon: const Icon(Icons.email),
            label: const Text('Contatta via email'),
          ),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 16),
        Text('Prossimi eventi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        if (eventsLoading)
          const Center(child: CircularProgressIndicator())
        else if (eventsError != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eventsError!),
              const SizedBox(height: 8),
              const Text('Riapri la pagina per riprovare.'),
            ],
          )
        else if (upcoming.isEmpty)
          const Text('Nessun evento nei prossimi 30 giorni.')
        else
          ...upcoming.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(e.title),
              subtitle: Text(
                [
                  if (e.start != null)
                    '${e.start!.day}/${e.start!.month}/${e.start!.year}',
                  if ((e.venueName ?? '').trim().isNotEmpty)
                    e.venueName!.trim(),
                  if ((e.city ?? '').trim().isNotEmpty) e.city!.trim(),
                ].join(' • '),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventDetailScreen(eventId: e.id),
                  ),
                );
              },
            ),
          ),

        if (links.isNotEmpty) ...[
          Text('Link', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...links.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(e.key),
              subtitle: Text(e.value),
              onTap: () => openExternal(e.value),
            ),
          ),
        ],
      ],
    );
  }
}
