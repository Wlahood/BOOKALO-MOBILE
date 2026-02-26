import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/venue_detail.dart';
import '../repositories/venues_repository.dart';
import '../services/api_client.dart';

import '../models/events_page.dart';
import '../repositories/events_repository.dart';
import 'event_detail_screen.dart';

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({super.key, required this.venueId});
  final int venueId;

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  late final VenuesRepository repo;

  bool loading = true;
  String? error;
  VenueDetail? venue;

  String _yyyyMmDd(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  void initState() {
    super.initState();
    repo = VenuesRepository(ApiClient());
    eventsRepo = EventsRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final v = await repo.fetchVenue(widget.venueId);
      setState(() => venue = v);
      await _loadUpcomingEvents(v.id);
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

  Future<void> _loadUpcomingEvents(int venueId) async {
    setState(() {
      eventsLoading = true;
      eventsError = null;
    });

    final now = DateTime.now();
    final startDate = _yyyyMmDd(now);
    final endDate = _yyyyMmDd(now.add(const Duration(days: 30)));

    try {
      final list = await eventsRepo.fetchVenueUpcomingEvents(
        venueId: venueId,
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
      appBar: AppBar(title: const Text('Locale')),
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
          : _VenueBody(
              venue: venue!,
              locationLine: _locationLine,
              openExternal: _openExternal,
              openMail: _openMail,
              eventsLoading: eventsLoading,
              eventsError: eventsError,
              upcoming: upcoming,
            ),
    );
  }

  late final EventsRepository eventsRepo;

  bool eventsLoading = true;
  String? eventsError;
  List<EventListItem> upcoming = const [];
}

class _VenueBody extends StatelessWidget {
  const _VenueBody({
    required this.venue,
    required this.locationLine,
    required this.openExternal,
    required this.openMail,
    required this.eventsLoading,
    required this.eventsError,
    required this.upcoming,
  });

  final VenueDetail venue;
  final String Function(LocationMini?) locationLine;
  final Future<void> Function(String) openExternal;
  final Future<void> Function(String) openMail;

  final bool eventsLoading;
  final String? eventsError;
  final List<EventListItem> upcoming;

  @override
  Widget build(BuildContext context) {
    final loc = locationLine(venue.location);
    final address = venue.address.toOneLine();

    final links = <MapEntry<String, String>>[];
    void addLink(String label, String? url) {
      final u = (url ?? '').trim();
      if (u.isEmpty) return;
      links.add(MapEntry(label, u));
    }

    addLink('Sito', venue.website);
    addLink('Instagram', venue.socials['instagram']);
    addLink('Facebook', venue.socials['facebook']);
    addLink('YouTube', venue.socials['youtube']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: (venue.imageUrl ?? '').isNotEmpty
                  ? NetworkImage(venue.imageUrl!)
                  : null,
              child: (venue.imageUrl ?? '').isEmpty
                  ? const Icon(Icons.location_city)
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
                          venue.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (venue.verified) const Icon(Icons.verified, size: 20),
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

        if (address.trim().isNotEmpty) ...[
          Text('Indirizzo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.map, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(address)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if ((venue.bio ?? '').trim().isNotEmpty) ...[
          Text('Descrizione', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(venue.bio!.trim()),
          const SizedBox(height: 16),
        ],

        if ((venue.email ?? '').trim().isNotEmpty) ...[
          ElevatedButton.icon(
            onPressed: () => openMail(venue.email!.trim()),
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
