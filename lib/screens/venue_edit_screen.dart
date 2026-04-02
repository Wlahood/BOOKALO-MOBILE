import 'package:flutter/material.dart';

import '../models/location_option.dart';
import '../models/venue_detail.dart';
import '../repositories/venues_repository.dart';
import '../services/api_client.dart';

class VenueEditScreen extends StatefulWidget {
  const VenueEditScreen({super.key, required this.venueId});

  final int venueId;

  @override
  State<VenueEditScreen> createState() => _VenueEditScreenState();
}

class _VenueEditScreenState extends State<VenueEditScreen> {
  late final VenuesRepository repo;

  final _formKey = GlobalKey<FormState>();

  bool loading = true;
  bool saving = false;
  String? error;

  VenueDetail? venue;

  List<String> regions = const [];
  List<LocationOption> provinces = const [];

  String? selectedRegion;
  int? selectedLocationId;

  final nameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final capacityCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final instagramCtrl = TextEditingController();
  final facebookCtrl = TextEditingController();
  final youtubeCtrl = TextEditingController();

  final streetCtrl = TextEditingController();
  final streetNumberCtrl = TextEditingController();
  final postalCodeCtrl = TextEditingController();
  final cityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    repo = VenuesRepository(ApiClient());
    _load();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    capacityCtrl.dispose();
    emailCtrl.dispose();
    websiteCtrl.dispose();
    instagramCtrl.dispose();
    facebookCtrl.dispose();
    youtubeCtrl.dispose();
    streetCtrl.dispose();
    streetNumberCtrl.dispose();
    postalCodeCtrl.dispose();
    cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final loadedVenue = await repo.fetchVenue(widget.venueId);
      final loadedRegions = await repo.fetchRegions();

      final region = loadedVenue.location?.region;
      final loadedProvinces = region == null || region.isEmpty
          ? <LocationOption>[]
          : await repo.fetchProvinces(region);

      nameCtrl.text = loadedVenue.name;
      bioCtrl.text = loadedVenue.bio ?? '';
      emailCtrl.text = loadedVenue.email ?? '';
      websiteCtrl.text = loadedVenue.website ?? '';
      instagramCtrl.text = loadedVenue.socials['instagram'] ?? '';
      facebookCtrl.text = loadedVenue.socials['facebook'] ?? '';
      youtubeCtrl.text = loadedVenue.socials['youtube'] ?? '';

      streetCtrl.text = loadedVenue.address.street ?? '';
      streetNumberCtrl.text = loadedVenue.address.streetNumber ?? '';
      postalCodeCtrl.text = loadedVenue.address.postalCode ?? '';
      cityCtrl.text = loadedVenue.address.city ?? '';

      setState(() {
        venue = loadedVenue;
        regions = loadedRegions;
        provinces = loadedProvinces;
        selectedRegion = region;
        selectedLocationId = loadedVenue.location?.id;
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

  int? _intOrNull(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
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
      await repo.updateVenue(widget.venueId, {
        'name': nameCtrl.text.trim(),
        'region': selectedRegion,
        'location_id': selectedLocationId,
        'description': _emptyToNull(bioCtrl.text),
        'capacity': _intOrNull(capacityCtrl.text),
        'email': _emptyToNull(emailCtrl.text),
        'website_url': _emptyToNull(websiteCtrl.text),
        'instagram_url': _emptyToNull(instagramCtrl.text),
        'facebook_url': _emptyToNull(facebookCtrl.text),
        'youtube_url': _emptyToNull(youtubeCtrl.text),
        'street': _emptyToNull(streetCtrl.text),
        'street_number': _emptyToNull(streetNumberCtrl.text),
        'postal_code': _emptyToNull(postalCodeCtrl.text),
        'city': _emptyToNull(cityCtrl.text),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, stack) {
      debugPrint('❌ ERRORE SALVATAGGIO VENUE: $e');
      debugPrint('📌 STACK VENUE: $stack');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Salvataggio fallito: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifica locale')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifica locale')),
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
      appBar: AppBar(title: const Text('Modifica locale')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome locale',
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
              onChanged: _onRegionChanged,
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
                labelText: 'Descrizione',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capienza',
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
              controller: streetCtrl,
              decoration: const InputDecoration(
                labelText: 'Via',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: streetNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Numero civico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: postalCodeCtrl,
              decoration: const InputDecoration(
                labelText: 'CAP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: cityCtrl,
              decoration: const InputDecoration(
                labelText: 'Città',
                border: OutlineInputBorder(),
              ),
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
