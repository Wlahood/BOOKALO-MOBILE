import 'package:flutter/material.dart';
import '../models/home_response.dart';
import '../repositories/home_repository.dart';
import '../services/api_client.dart';
import '../widgets/event_web_card.dart';
import 'event_detail_screen.dart';
import 'band_detail_screen.dart';
import 'venue_detail_screen.dart';
import 'workspace/account_screen.dart';
import 'workspace/common.dart';
import 'workspace/workflow_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = HomeRepository(ApiClient());
  HomeResponse? _home;
  String? _error, _region, _province, _bandName, _venueName;
  int? _bandId, _venueId;
  int _page = 1;
  bool _busy = true, _showIntro = true;
  late DateTime _start, _end;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    _end = _start.add(const Duration(days: 7));
    _load();
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _label(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final home = await _repo.fetchHome(
        startDate: _date(_start),
        endDate: _date(_end),
        region: _region,
        provinceCode: _province,
        bandId: _bandId,
        venueId: _venueId,
        page: _page,
      );
      if (mounted && generation == _generation) setState(() => _home = home);
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = '$e');
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _selectEntity(bool band) async {
    final selected = await openPage<List<Map<String, dynamic>>>(
      context,
      LookupScreen(
        title: band ? 'Cerca band' : 'Cerca locale',
        source: band ? '/bands' : '/venues',
      ),
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    setState(() {
      if (band) {
        _bandId = selected.first['id'];
        _bandName = selected.first['name'];
      } else {
        _venueId = selected.first['id'];
        _venueName = selected.first['name'];
      }
      _page = 1;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final banner = object(_home?.content['banner']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookalo'),
        actions: [
          IconButton(
            tooltip: 'Guide e informazioni',
            icon: const Icon(Icons.help_outline),
            onPressed: () => openPage(context, const HelpScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showIntro && banner['enabled'] == true)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${banner['title'] ?? 'Benvenuto su Bookalo'}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _showIntro = false),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              Text(
                                '${banner['text'] ?? ''}'.replaceAll(
                                  RegExp(r'<[^>]*>'),
                                  '',
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    openPage(context, const HelpScreen()),
                                child: const Text('Scopri come funziona'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_home?.stats.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${_home!.stats['bands']} band · ${_home!.stats['venues']} locali · ${_home!.stats['upcoming_events']} eventi in programma',
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Settimana precedente',
                          onPressed: _busy
                              ? null
                              : () {
                                  _start = _start.subtract(
                                    const Duration(days: 7),
                                  );
                                  _end = _end.subtract(const Duration(days: 7));
                                  _page = 1;
                                  _load();
                                },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                initialDateRange: DateTimeRange(
                                  start: _start,
                                  end: _end,
                                ),
                              );
                              if (range != null) {
                                _start = range.start;
                                _end = range.end;
                                _page = 1;
                                _load();
                              }
                            },
                            child: Text('${_label(_start)} – ${_label(_end)}'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Settimana successiva',
                          onPressed: _busy
                              ? null
                              : () {
                                  _start = _start.add(const Duration(days: 7));
                                  _end = _end.add(const Duration(days: 7));
                                  _page = 1;
                                  _load();
                                },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Filtra gli eventi'),
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey('region:$_region'),
                          initialValue: _region,
                          decoration: const InputDecoration(
                            labelText: 'Regione',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Tutte le regioni'),
                            ),
                            for (final region in _home?.available.regions ?? [])
                              DropdownMenuItem(
                                value: region.name,
                                child: Text(region.name),
                              ),
                          ],
                          onChanged: (v) {
                            _region = v;
                            _province = null;
                            _page = 1;
                            _load();
                          },
                        ),
                        DropdownButtonFormField<String>(
                          key: ValueKey('province:$_province'),
                          initialValue: _province,
                          decoration: const InputDecoration(
                            labelText: 'Provincia',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Tutte le province'),
                            ),
                            for (final province
                                in _home?.available.provinces ?? [])
                              DropdownMenuItem(
                                value: province.code,
                                child: Text(province.label),
                              ),
                          ],
                          onChanged: (v) {
                            _province = v;
                            _page = 1;
                            _load();
                          },
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _selectEntity(true),
                              child: Text(_bandName ?? 'Scegli band'),
                            ),
                            OutlinedButton(
                              onPressed: () => _selectEntity(false),
                              child: Text(_venueName ?? 'Scegli locale'),
                            ),
                            TextButton(
                              onPressed: () {
                                _region = null;
                                _province = null;
                                _bandId = null;
                                _venueId = null;
                                _bandName = null;
                                _venueName = null;
                                _page = 1;
                                _load();
                              },
                              child: const Text('Azzera filtri'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null)
                      Column(
                        children: [
                          Text(_error!),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    if (!_busy && (_home?.events.isEmpty ?? true))
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nessun evento nel periodo selezionato.'),
                      ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final event = _home!.events[index];
                return EventWebCard(
                  title: event.title,
                  dateText: event.start == null ? '' : _label(event.start!),
                  venueLine: [
                    event.venueName,
                    event.city,
                    event.provinceCode,
                  ].whereType<String>().join(' · '),
                  bandLine: event.bandNames.join(', '),
                  posterImageUrl: event.posterImageUrl,
                  onTap: () =>
                      openPage(context, EventDetailScreen(eventId: event.id)),
                );
              }, childCount: _home?.events.length ?? 0),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: !_busy && _page > 1
                            ? () {
                                _page--;
                                _load();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('$_page / ${_home?.lastPage ?? 1}'),
                      IconButton(
                        onPressed: !_busy && _page < (_home?.lastPage ?? 1)
                            ? () {
                                _page++;
                                _load();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Scopri band e locali'),
                    children: [
                      for (final band in _home?.featuredBands ?? [])
                        ListTile(
                          title: Text('${band['name']}'),
                          leading: const Icon(Icons.music_note),
                          onTap: () => openPage(
                            context,
                            BandDetailScreen(bandId: band['id']),
                          ),
                        ),
                      for (final venue in _home?.featuredVenues ?? [])
                        ListTile(
                          title: Text('${venue['name']}'),
                          leading: const Icon(Icons.store),
                          onTap: () => openPage(
                            context,
                            VenueDetailScreen(venueId: venue['id']),
                          ),
                        ),
                    ],
                  ),
                  Wrap(
                    children: [
                      for (final entry in {
                        'privacy': 'Privacy',
                        'cookies': 'Cookie',
                        'terms': 'Termini',
                        'claims': 'Rivendicazioni',
                      }.entries)
                        TextButton(
                          onPressed: () => openPage(
                            context,
                            LegalScreen(slug: entry.key, title: entry.value),
                          ),
                          child: Text(entry.value),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
