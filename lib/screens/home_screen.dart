// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/home_response.dart';
import '../repositories/home_repository.dart';
import '../services/api_client.dart';
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
  bool loadingMore = false;
  String? error;

  String? selectedProvince;
  String? selectedCity;

  final events = <EventCompact>[];
  String? nextUrl;

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    repo = HomeRepository(ApiClient());
    _load();

    scrollController.addListener(() async {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 300) {
        await _loadMore();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await repo.fetchHome(
        provinceCode: selectedProvince,
        city: selectedCity,
        perPage: 20,
      );

      setState(() {
        home = res;
        events
          ..clear()
          ..addAll(res.data.events.data);
        nextUrl = res.data.events.links.next;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (loadingMore || nextUrl == null) return;
    setState(() => loadingMore = true);

    try {
      final page = await repo.fetchNextPage(nextUrl!);
      setState(() {
        events.addAll(page.data);
        nextUrl = page.links.next;
      });
    } catch (_) {
      // volutamente silenzioso: non blocchiamo la Home per un loadMore fallito
    } finally {
      setState(() => loadingMore = false);
    }
  }

  Future<void> _onProvinceChanged(String? value) async {
    setState(() {
      selectedProvince = value;
      selectedCity =
          null; // reset city: nel backend cities dipende dalla provincia
    });
    await _load();
  }

  Future<void> _onCityChanged(String? value) async {
    setState(() => selectedCity = value);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final availableProvinces = home?.data.available.provinces ?? const [];
    final availableCities = home?.data.available.cities ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Bookalo')),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedProvince,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Tutte le province'),
                              ),
                              ...availableProvinces.map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              ),
                            ],
                            onChanged: (v) => _onProvinceChanged(v),
                            decoration: const InputDecoration(
                              labelText: 'Provincia',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCity,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Tutte le città'),
                              ),
                              ...availableCities.map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              ),
                            ],
                            onChanged: selectedProvince == null
                                ? null
                                : (v) => _onCityChanged(v),
                            decoration: const InputDecoration(
                              labelText: 'Città',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: events.length + (loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= events.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final e = events[index];
                        final venue = e.venue?.name ?? '';
                        final city = e.venue?.location?.name ?? '';
                        final prov = e.venue?.location?.provinceCode ?? '';
                        final bands = e.bands.map((b) => b.name).join(', ');

                        return ListTile(
                          title: Text(e.title),
                          subtitle: Text(
                            [
                              if (bands.isNotEmpty) bands,
                              if (venue.isNotEmpty) venue,
                              if (city.isNotEmpty || prov.isNotEmpty)
                                '$city ${prov.isNotEmpty ? "($prov)" : ""}',
                            ].where((s) => s.trim().isNotEmpty).join(' • '),
                          ),
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
