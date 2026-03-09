import 'dart:async';

import 'package:flutter/material.dart';

import '../models/location_filters.dart';
import '../models/search_response.dart';
import '../repositories/home_repository.dart';
import '../repositories/search_repository.dart';
import '../services/api_client.dart';
import '../widgets/event_web_card.dart';
import 'band_detail_screen.dart';
import 'event_detail_screen.dart';
import 'venue_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchRepository repo;
  late final HomeRepository homeRepo;

  final controller = TextEditingController();
  Timer? debounce;

  bool loading = false;
  bool loadingFilters = true;
  String? error;

  SearchResponse? data;

  String? selectedRegion;
  String? selectedProvinceCode;
  String? selectedStartDate;
  String? selectedEndDate;

  List<RegionOption> availableRegions = [];
  List<ProvinceOption> availableProvinces = [];

  @override
  void initState() {
    super.initState();
    repo = SearchRepository(ApiClient());
    homeRepo = HomeRepository(ApiClient());
    _loadFilters();
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    setState(() {
      loadingFilters = true;
      error = null;
    });

    try {
      final res = await homeRepo.fetchHome(
        region: selectedRegion,
        provinceCode: selectedProvinceCode,
        startDate: selectedStartDate,
        endDate: selectedEndDate,
        perPage: 1,
      );

      final provinces = res.available.provinces;
      final provinceStillValid = provinces.any(
        (p) => p.code == selectedProvinceCode,
      );

      setState(() {
        availableRegions = res.available.regions;
        availableProvinces = provinces;
        if (!provinceStillValid) {
          selectedProvinceCode = null;
        }
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loadingFilters = false;
      });
    }
  }

  void _onTextChanged(String value) {
    setState(() {});
    debounce?.cancel();

    debounce = Timer(const Duration(milliseconds: 350), () {
      final q = value.trim();
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

  Future<void> _runSearch([String? rawQuery]) async {
    final q = (rawQuery ?? controller.text).trim();

    if (q.isEmpty) {
      setState(() {
        data = null;
        error = null;
        loading = false;
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await repo.search(
        q: q,
        region: selectedRegion,
        provinceCode: selectedProvinceCode,
        startDate: selectedStartDate,
        endDate: selectedEndDate,
        limit: 10,
      );

      setState(() {
        data = res;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _refreshSearchIfNeeded() async {
    final q = controller.text.trim();
    if (q.isNotEmpty) {
      await _runSearch(q);
    }
  }

  Future<void> _onRegionChanged(String? value) async {
    setState(() {
      selectedRegion = value;
      selectedProvinceCode = null;
    });
    await _loadFilters();
    await _refreshSearchIfNeeded();
  }

  Future<void> _onProvinceChanged(String? value) async {
    setState(() {
      selectedProvinceCode = value;
    });
    await _refreshSearchIfNeeded();
  }

  Future<void> _pickStartDate() async {
    final initial = _parseDate(selectedStartDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    final pickedText = _formatApiDate(picked);

    setState(() {
      selectedStartDate = pickedText;

      if (selectedEndDate != null) {
        final end = _parseDate(selectedEndDate!);
        if (end != null && end.isBefore(picked)) {
          selectedEndDate = pickedText;
        }
      }
    });

    await _loadFilters();
    await _refreshSearchIfNeeded();
  }

  Future<void> _pickEndDate() async {
    final initial =
        _parseDate(selectedEndDate) ??
        _parseDate(selectedStartDate) ??
        DateTime.now();

    final firstDate = _parseDate(selectedStartDate) ?? DateTime(2020);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      selectedEndDate = _formatApiDate(picked);
    });

    await _loadFilters();
    await _refreshSearchIfNeeded();
  }

  Future<void> _resetFilters() async {
    setState(() {
      selectedRegion = null;
      selectedProvinceCode = null;
      selectedStartDate = null;
      selectedEndDate = null;
    });

    await _loadFilters();
    await _refreshSearchIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final d = data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca'),
        actions: [
          IconButton(
            tooltip: 'Reset filtri',
            onPressed: _resetFilters,
            icon: const Icon(Icons.filter_alt_off),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: _onTextChanged,
                  onSubmitted: _runSearch,
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
                              _onTextChanged('');
                            },
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: loading ? null : () => _runSearch(),
                child: const Text('Cerca'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: loadingFilters
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtri',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: selectedRegion,
                          decoration: const InputDecoration(
                            labelText: 'Regione',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tutte le regioni'),
                            ),
                            ...availableRegions.map(
                              (region) => DropdownMenuItem<String?>(
                                value: region.name,
                                child: Text(region.name),
                              ),
                            ),
                          ],
                          onChanged: _onRegionChanged,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: selectedProvinceCode,
                          decoration: const InputDecoration(
                            labelText: 'Provincia',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tutte le province'),
                            ),
                            ...availableProvinces.map(
                              (province) => DropdownMenuItem<String?>(
                                value: province.code,
                                child: Text(province.label),
                              ),
                            ),
                          ],
                          onChanged: _onProvinceChanged,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickStartDate,
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  selectedStartDate == null
                                      ? 'Data da'
                                      : 'Da: $selectedStartDate',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickEndDate,
                                icon: const Icon(Icons.event),
                                label: Text(
                                  selectedEndDate == null
                                      ? 'Data a'
                                      : 'A: $selectedEndDate',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
              onPressed: () => _runSearch(),
              child: const Text('Riprova'),
            ),
          ],
          if (!loading && error == null && d == null)
            const Text('Scrivi qualcosa per iniziare la ricerca.'),
          if (!loading && error == null && d != null) ...[
            _SectionTitle('Eventi (${d.events.length})'),
            if (d.events.isEmpty)
              const Text('Nessun evento trovato.')
            else
              ...d.events.map((e) {
                final venueLine = [
                  if ((e.venueName ?? '').trim().isNotEmpty)
                    e.venueName!.trim(),
                  if ((e.city ?? '').trim().isNotEmpty)
                    '${e.city!.trim()}${(e.provinceCode ?? '').trim().isNotEmpty ? ' (${e.provinceCode!.trim()})' : ''}',
                ].where((s) => s.isNotEmpty).join(' — ');

                final bandLine = e.bandNames.join(', ');

                return EventWebCard(
                  title: e.title,
                  dateText: _formatDateOnly(e.start),
                  venueLine: venueLine,
                  bandLine: bandLine,
                  posterImageUrl: e.posterImageUrl,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: e.id),
                      ),
                    );
                  },
                );
              }),
            const SizedBox(height: 16),
            _SectionTitle('Band (${d.bands.length})'),
            if (d.bands.isEmpty)
              const Text('Nessuna band trovata.')
            else
              ...d.bands.map(
                (b) => ListTile(
                  title: Text(b.name),
                  subtitle: Text(
                    [
                      if ((b.region ?? '').trim().isNotEmpty) b.region!.trim(),
                      if ((b.city ?? '').trim().isNotEmpty) b.city!.trim(),
                      if ((b.provinceCode ?? '').trim().isNotEmpty)
                        '(${b.provinceCode})',
                    ].join(' • '),
                  ),
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
            _SectionTitle('Locali (${d.venues.length})'),
            if (d.venues.isEmpty)
              const Text('Nessun locale trovato.')
            else
              ...d.venues.map(
                (v) => ListTile(
                  title: Text(v.name),
                  subtitle: Text(
                    [
                      if ((v.region ?? '').trim().isNotEmpty) v.region!.trim(),
                      if ((v.city ?? '').trim().isNotEmpty) v.city!.trim(),
                      if ((v.provinceCode ?? '').trim().isNotEmpty)
                        '(${v.provinceCode})',
                      if ((v.address ?? '').trim().isNotEmpty)
                        v.address!.trim(),
                    ].join(' • '),
                  ),
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

DateTime? _parseDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}

String _formatApiDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatDateOnly(DateTime? dt) {
  if (dt == null) return '';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
}
