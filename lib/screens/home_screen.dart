import 'package:flutter/material.dart';

import '../models/events_page.dart';
import '../models/home_response.dart';
import '../models/location_filters.dart';
import '../repositories/home_repository.dart';
import '../services/api_client.dart';
import '../widgets/event_web_card.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeRepository repo;

  HomeResponse? home;
  bool loading = true;
  String? error;

  String? selectedRegion;
  String? selectedProvinceCode;

  @override
  void initState() {
    super.initState();
    repo = HomeRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await repo.fetchHome(
        region: selectedRegion,
        provinceCode: selectedProvinceCode,
        perPage: 20,
      );

      final availableProvinces = res.available.provinces;
      final incomingProvince = res.filters.provinceCode ?? selectedProvinceCode;

      setState(() {
        home = res;
        selectedRegion = res.filters.region ?? selectedRegion;
        selectedProvinceCode =
            availableProvinces.any((p) => p.code == incomingProvince)
            ? incomingProvince
            : null;
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

  Future<void> _onRegionChanged(String? value) async {
    setState(() {
      selectedRegion = value;
      selectedProvinceCode = null;
    });
    await _load();
  }

  Future<void> _onProvinceChanged(String? value) async {
    setState(() {
      selectedProvinceCode = value;
    });
    await _load();
  }

  Future<void> _resetFilters() async {
    setState(() {
      selectedRegion = null;
      selectedProvinceCode = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final availableRegions = home?.available.regions ?? const <RegionOption>[];
    final availableProvinces =
        home?.available.provinces ?? const <ProvinceOption>[];
    final events = home?.events ?? const <EventListItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookalo'),
        actions: [
          IconButton(
            tooltip: 'Reset filtri',
            onPressed: _resetFilters,
            icon: const Icon(Icons.filter_alt_off),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(error!)),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _load,
                      child: const Text('Riprova'),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
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
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: events.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('Nessun evento trovato.')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final e = events[index];

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
                                      builder: (_) =>
                                          EventDetailScreen(eventId: e.id),
                                    ),
                                  );
                                },
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

String _formatDateOnly(DateTime? dt) {
  if (dt == null) return '';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
}
