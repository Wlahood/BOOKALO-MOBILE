import 'dart:async';
import 'package:flutter/material.dart';

import '../models/search_response.dart';
import '../repositories/search_repository.dart';
import '../services/api_client.dart';
import 'event_detail_screen.dart';

import 'band_detail_screen.dart';
import 'venue_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchRepository repo;
  final controller = TextEditingController();

  Timer? _debounce;

  bool loading = false;
  String? error;
  SearchData? data;

  @override
  void initState() {
    super.initState();
    repo = SearchRepository(ApiClient());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = v.trim();
      if (q.isEmpty) {
        setState(() {
          data = null;
          error = null;
          loading = false;
        });
        return;
      }
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await repo.search(q);
      setState(() => data = res);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = data;

    return Scaffold(
      appBar: AppBar(title: const Text('Cerca')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cerca eventi, band, locali...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        _onChanged('');
                        setState(() {}); // aggiorna suffixIcon
                      },
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          if (loading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
          ],

          if (error != null) ...[
            Text(error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _runSearch(controller.text.trim()),
              child: const Text('Riprova'),
            ),
          ],

          if (!loading && error == null && d == null)
            const Text('Scrivi qualcosa per iniziare la ricerca.'),

          if (!loading && error == null && d != null) ...[
            _SectionTitle('Eventi'),
            if (d.events.isEmpty)
              const Text('Nessun evento trovato.')
            else
              ...d.events.map(
                (e) => ListTile(
                  title: Text(e.title),
                  subtitle: Text(
                    [
                      if ((e.startDatetime ?? '').isNotEmpty) e.startDatetime!,
                      if ((e.venueName ?? '').isNotEmpty) e.venueName!,
                      if ((e.locationName ?? '').isNotEmpty) e.locationName!,
                    ].join(' • '),
                  ),
                  leading: const Icon(Icons.event),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: e.id),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            _SectionTitle('Band'),
            if (d.bands.isEmpty)
              const Text('Nessuna band trovata.')
            else
              ...d.bands.map(
                (b) => ListTile(
                  title: Text(b.name),
                  leading: const Icon(Icons.group),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BandDetailScreen(bandId: b.id),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            _SectionTitle('Locali'),
            if (d.venues.isEmpty)
              const Text('Nessun locale trovato.')
            else
              ...d.venues.map(
                (v) => ListTile(
                  title: Text(v.name),
                  leading: const Icon(Icons.location_city),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VenueDetailScreen(venueId: v.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
