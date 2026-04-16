import 'package:flutter/material.dart';

import '../models/notification_preference.dart';
import '../repositories/notifications_repository.dart';
import '../services/api_client.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late final NotificationsRepository _repo;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<NotificationPreference> _items = const [];

  @override
  void initState() {
    super.initState();
    _repo = NotificationsRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repo.fetchPreferences();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggle(int index, bool value) {
    setState(() {
      _items = List<NotificationPreference>.from(_items);
      _items[index] = _items[index].copyWith(mailEnabled: value);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await _repo.updatePreferences(_items);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Preferenze salvate.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferenze notifiche')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _PreferencesErrorState(error: _error!, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Scegli per quali categorie ricevere email.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < _items.length; i++) ...[
                        SwitchListTile(
                          value: _items[i].mailEnabled,
                          onChanged: (value) => _toggle(i, value),
                          title: Text(_items[i].label),
                          subtitle: Text(_items[i].type),
                        ),
                        if (i < _items.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Salvataggio...' : 'Salva preferenze'),
                ),
              ],
            ),
    );
  }
}

class _PreferencesErrorState extends StatelessWidget {
  const _PreferencesErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Errore nel caricamento delle preferenze',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}
