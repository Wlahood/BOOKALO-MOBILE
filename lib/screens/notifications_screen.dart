import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../repositories/notifications_repository.dart';
import '../services/api_client.dart';
import 'band_detail_screen.dart';
import 'event_detail_screen.dart';
import 'venue_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsRepository _repo;

  bool _loading = true;
  String? _error;
  List<NotificationItem> _items = const [];
  int _unreadCount = 0;
  bool _markingAll = false;

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
      final results = await Future.wait([
        _repo.fetchNotifications(),
        _repo.fetchUnreadCount(),
      ]);

      setState(() {
        _items = results[0] as List<NotificationItem>;
        _unreadCount = results[1] as int;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _markingAll = true);

    try {
      await _repo.markAllAsRead();
      setState(() {
        _unreadCount = 0;
        _items = _items
            .map(
              (item) => item.isRead
                  ? item
                  : NotificationItem(
                      id: item.id,
                      type: item.type,
                      title: item.title,
                      body: item.body,
                      webUrl: item.webUrl,
                      deepLink: item.deepLink,
                      readAt: DateTime.now(),
                      createdAt: item.createdAt,
                      payload: item.payload,
                    ),
            )
            .toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutte le notifiche sono state segnate come lette.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _markingAll = false);
      }
    }
  }

  Future<void> _markOneAsRead(NotificationItem item) async {
    if (item.isRead) {
      return;
    }

    try {
      final updated = await _repo.markAsRead(item.id);
      setState(() {
        _items = _items.map((e) => e.id == item.id ? updated : e).toList();
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  int? _readInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  int? _extractIdFromDeepLink(String? deepLink, String segment) {
    if (deepLink == null || deepLink.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(deepLink);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    final index = segments.indexOf(segment);

    if (index == -1 || index + 1 >= segments.length) {
      return null;
    }

    return int.tryParse(segments[index + 1]);
  }

  Future<void> _openNotificationTarget(NotificationItem item) async {
    final payload = item.payload;

    final eventId =
        _readInt(payload['event_id']) ??
        _readInt(payload['eventId']) ??
        _extractIdFromDeepLink(item.deepLink, 'events');

    final bandId =
        _readInt(payload['band_id']) ??
        _readInt(payload['bandId']) ??
        _extractIdFromDeepLink(item.deepLink, 'bands');

    final venueId =
        _readInt(payload['venue_id']) ??
        _readInt(payload['venueId']) ??
        _extractIdFromDeepLink(item.deepLink, 'venues');

    if (eventId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId)),
      );
      return;
    }

    if (bandId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BandDetailScreen(bandId: bandId)),
      );
      return;
    }

    if (venueId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VenueDetailScreen(venueId: venueId)),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Destinazione non disponibile per questa notifica.'),
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationItem item) async {
    await _markOneAsRead(item);

    if (!mounted) {
      return;
    }

    await _openNotificationTarget(item);
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifiche'),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '$_unreadCount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          IconButton(
            onPressed: _loading || _markingAll || _unreadCount == 0
                ? null
                : _markAllAsRead,
            icon: _markingAll
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all),
            tooltip: 'Segna tutte come lette',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _NotificationsErrorState(error: _error!, onRetry: _load)
          : _items.isEmpty
          ? const _NotificationsEmptyState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    elevation: item.isRead ? 0 : 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(
                        item.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                      ),
                      title: Text(item.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((item.body ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(item.body!.trim()),
                          ],
                          if (item.createdAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(item.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      trailing: item.isRead
                          ? const Icon(Icons.done, size: 18)
                          : const Icon(Icons.circle, size: 12),
                      onTap: () => _handleNotificationTap(item),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Non hai ancora notifiche.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({required this.error, required this.onRetry});

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
              'Errore nel caricamento delle notifiche',
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
