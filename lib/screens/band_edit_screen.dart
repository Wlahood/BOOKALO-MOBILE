import 'package:flutter/material.dart';

import '../models/band_detail.dart';
import '../models/location_option.dart';
import '../repositories/bands_repository.dart';
import '../services/api_client.dart';

class BandEditScreen extends StatefulWidget {
  const BandEditScreen({super.key, required this.bandId});

  final int bandId;

  @override
  State<BandEditScreen> createState() => _BandEditScreenState();
}

class _BandEditScreenState extends State<BandEditScreen> {
  late final BandsRepository repo;

  final _formKey = GlobalKey<FormState>();

  bool loading = true;
  bool saving = false;
  String? error;

  BandDetail? band;

  List<String> regions = const [];
  List<LocationOption> provinces = const [];
  List<GenreMini> allGenres = const [];

  String? selectedRegion;
  int? selectedLocationId;
  Set<int> selectedGenreIds = <int>{};

  final nameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final instagramCtrl = TextEditingController();
  final facebookCtrl = TextEditingController();
  final youtubeCtrl = TextEditingController();
  final spotifyCtrl = TextEditingController();
  final youtubeMusicCtrl = TextEditingController();
  final deezerCtrl = TextEditingController();
  final amazonMusicCtrl = TextEditingController();
  final soundcloudCtrl = TextEditingController();
  final bandcampCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    repo = BandsRepository(ApiClient());
    _load();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    emailCtrl.dispose();
    websiteCtrl.dispose();
    instagramCtrl.dispose();
    facebookCtrl.dispose();
    youtubeCtrl.dispose();
    spotifyCtrl.dispose();
    youtubeMusicCtrl.dispose();
    deezerCtrl.dispose();
    amazonMusicCtrl.dispose();
    soundcloudCtrl.dispose();
    bandcampCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final loadedBand = await repo.fetchBand(widget.bandId);
      final loadedRegions = await repo.fetchRegions();
      final loadedGenres = await repo.fetchGenres();

      final region = loadedBand.location?.region;
      final loadedProvinces = region == null || region.isEmpty
          ? <LocationOption>[]
          : await repo.fetchProvinces(region);

      nameCtrl.text = loadedBand.name;
      bioCtrl.text = loadedBand.bio ?? '';
      emailCtrl.text = loadedBand.email ?? '';
      websiteCtrl.text = loadedBand.website ?? '';
      instagramCtrl.text = loadedBand.socials['instagram'] ?? '';
      facebookCtrl.text = loadedBand.socials['facebook'] ?? '';
      youtubeCtrl.text = loadedBand.socials['youtube'] ?? '';
      spotifyCtrl.text = loadedBand.socials['spotify'] ?? '';
      youtubeMusicCtrl.text = loadedBand.socials['youtube_music'] ?? '';
      deezerCtrl.text = loadedBand.socials['deezer'] ?? '';
      amazonMusicCtrl.text = loadedBand.socials['amazon_music'] ?? '';
      soundcloudCtrl.text = loadedBand.socials['soundcloud'] ?? '';
      bandcampCtrl.text = loadedBand.socials['bandcamp'] ?? '';

      setState(() {
        band = loadedBand;
        regions = loadedRegions;
        allGenres = loadedGenres;
        provinces = loadedProvinces;
        selectedRegion = region;
        selectedLocationId = loadedBand.location?.id;
        selectedGenreIds = loadedBand.genres.map((g) => g.id).toSet();
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _onRegionChanged(String? region) async {
    setState(() {
      selectedRegion = region;
      selectedLocationId = null;
      provinces = const [];
    });

    if (region == null || region.isEmpty) {
      return;
    }

    try {
      final loaded = await repo.fetchProvinces(region);
      setState(() => provinces = loaded);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore caricamento province: $e')),
      );
    }
  }

  String? _emptyToNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRegion == null || selectedRegion!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona una regione')));
      return;
    }
    if (selectedLocationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona una provincia')));
      return;
    }

    setState(() => saving = true);

    try {
      await repo.updateBand(widget.bandId, {
        'name': nameCtrl.text.trim(),
        'region': selectedRegion,
        'location_id': selectedLocationId,
        'description': _emptyToNull(bioCtrl.text),
        'email': _emptyToNull(emailCtrl.text),
        'website_url': _emptyToNull(websiteCtrl.text),
        'instagram_url': _emptyToNull(instagramCtrl.text),
        'facebook_url': _emptyToNull(facebookCtrl.text),
        'youtube_url': _emptyToNull(youtubeCtrl.text),
        'spotify_url': _emptyToNull(spotifyCtrl.text),
        'youtube_music_url': _emptyToNull(youtubeMusicCtrl.text),
        'deezer_url': _emptyToNull(deezerCtrl.text),
        'amazon_music_url': _emptyToNull(amazonMusicCtrl.text),
        'soundcloud_url': _emptyToNull(soundcloudCtrl.text),
        'bandcamp_url': _emptyToNull(bandcampCtrl.text),
        'genres': selectedGenreIds.toList(),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, stack) {
      debugPrint('❌ ERRORE SALVATAGGIO: $e');
      debugPrint('📌 STACK: $stack');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifica band')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifica band')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Riprova')),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Modifica band')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome band',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Il nome è obbligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Regione',
                border: OutlineInputBorder(),
              ),
              items: regions
                  .map(
                    (region) => DropdownMenuItem<String>(
                      value: region,
                      child: Text(region),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _onRegionChanged(value),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              initialValue: selectedLocationId,
              decoration: const InputDecoration(
                labelText: 'Provincia',
                border: OutlineInputBorder(),
              ),
              items: provinces
                  .map(
                    (p) => DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(p.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedLocationId = value),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: bioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: websiteCtrl,
              decoration: const InputDecoration(
                labelText: 'Sito web',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: instagramCtrl,
              decoration: const InputDecoration(
                labelText: 'Instagram URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: facebookCtrl,
              decoration: const InputDecoration(
                labelText: 'Facebook URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: youtubeCtrl,
              decoration: const InputDecoration(
                labelText: 'YouTube URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: spotifyCtrl,
              decoration: const InputDecoration(
                labelText: 'Spotify URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: youtubeMusicCtrl,
              decoration: const InputDecoration(
                labelText: 'YouTube Music URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: deezerCtrl,
              decoration: const InputDecoration(
                labelText: 'Deezer URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: amazonMusicCtrl,
              decoration: const InputDecoration(
                labelText: 'Amazon Music URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: soundcloudCtrl,
              decoration: const InputDecoration(
                labelText: 'SoundCloud URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: bandcampCtrl,
              decoration: const InputDecoration(
                labelText: 'Bandcamp URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Text('Generi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allGenres.map((genre) {
                final selected = selectedGenreIds.contains(genre.id);
                return FilterChip(
                  label: Text(genre.name),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selectedGenreIds.add(genre.id);
                      } else {
                        selectedGenreIds.remove(genre.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(saving ? 'Salvataggio...' : 'Salva modifiche'),
            ),
          ],
        ),
      ),
    );
  }
}
