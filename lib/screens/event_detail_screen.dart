import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositories/events_repository.dart';
import '../services/api_client.dart';
import '../models/event_detail.dart';

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
      setState(() => event = e);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String format(DateTime? dt) {
    if (dt == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text(error!)));
    }

    final e = event!;

    return Scaffold(
      appBar: AppBar(title: const Text('Evento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(e.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(format(e.start)),
          const SizedBox(height: 8),
          if (e.venue != null)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VenueDetailScreen(venueId: e.venue!.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.place, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.venue!.name,
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
          const SizedBox(height: 16),
          if ((e.description ?? '').isNotEmpty) Text(e.description!),
          const SizedBox(height: 16),
          if (e.bands.isNotEmpty) ...[
            const Text("Band:"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
            const SizedBox(height: 16),
          ],
          if (e.webUrl.isNotEmpty)
            ElevatedButton(
              onPressed: () => openUrl(e.webUrl),
              child: const Text("Apri sul sito"),
            ),
        ],
      ),
    );
  }
}
