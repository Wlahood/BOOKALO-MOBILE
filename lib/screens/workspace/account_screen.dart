import 'package:flutter/material.dart';
import '../../repositories/workspace_repository.dart';
import '../../services/auth_controller.dart';
import 'common.dart';
import 'form_specs.dart';
import 'workflow_form_screen.dart';
import 'messages_screen.dart';
import '../event_detail_screen.dart';
import '../band_detail_screen.dart';
import '../venue_detail_screen.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.slug, required this.title});
  final String slug, title;
  @override
  Widget build(BuildContext context) => RemotePage(
    title: title,
    path: '/legal/$slug',
    builder: (context, data, reload) => [
      for (final paragraph in data['paragraphs'] as List? ?? [])
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SelectableText('$paragraph'),
        ),
    ],
  );
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) => RemotePage(
    title: 'Profilo e sicurezza',
    path: '/me/profile',
    builder: (context, data, reload) => [
      menuTile('Modifica profilo', Icons.person_outline, () async {
        await openPage(
          context,
          WorkflowFormScreen(
            title: 'Profilo',
            path: '/me/profile',
            method: 'PATCH',
            fields: profileFields,
            initial: object(data['user']),
          ),
        );
        await AuthController.instance.bootstrap();
        reload();
      }),
      menuTile(
        'Cambia password',
        Icons.lock_outline,
        () => openPage(
          context,
          const WorkflowFormScreen(
            title: 'Cambia password',
            path: '/me/password',
            method: 'PUT',
            fields: passwordFields,
          ),
        ),
      ),
      menuTile(
        'Preferenze email',
        Icons.notifications_outlined,
        () => openPage(context, const NotificationPreferencesScreen()),
      ),
      menuTile(
        'Verifica indirizzo email',
        Icons.mark_email_read_outlined,
        () => runAction(context, '/me/email/verification-notification'),
      ),
      menuTile('Ho ricevuto il link di verifica', Icons.link, () async {
        await openPage(
          context,
          const WorkflowFormScreen(
            title: 'Verifica email',
            path: '/me/email/verify',
            fields: [
              FormFieldSpec(
                'url',
                'Incolla il link ricevuto via email',
                required: true,
              ),
            ],
          ),
        );
        await AuthController.instance.bootstrap();
        reload();
      }),
      ListTile(
        leading: const Icon(Icons.delete_forever),
        title: const Text('Elimina account'),
        subtitle: const Text('L’eliminazione è definitiva.'),
        onTap: () async {
          final result = await openPage<Map<String, dynamic>>(
            context,
            const WorkflowFormScreen(
              title: 'Elimina definitivamente l’account',
              path: '/me/profile',
              method: 'DELETE',
              fields: [
                FormFieldSpec(
                  'password',
                  'Conferma con la password',
                  kind: InputKind.password,
                  required: true,
                ),
              ],
            ),
          );
          if (result != null) {
            await AuthController.instance.logout();
            if (context.mounted) Navigator.pop(context);
          }
        },
      ),
    ],
  );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => RecordListScreen(
    title: 'Notifiche',
    path: '/me/notifications',
    listKey: 'data',
    actions: [
      IconButton(
        tooltip: 'Segna tutte come lette',
        onPressed: () => runAction(context, '/me/notifications/read-all'),
        icon: const Icon(Icons.done_all),
      ),
    ],
    itemBuilder: (context, row, reload) => Card(
      child: ListTile(
        leading: Icon(
          row['read_at'] == null
              ? Icons.mark_email_unread
              : Icons.mark_email_read_outlined,
        ),
        title: Text('${row['title']}'),
        subtitle: Text('${row['body'] ?? ''}'),
        onTap: () async {
          await runAction(context, '/me/notifications/${row['id']}/read');
          if (!context.mounted) return;
          final payload = object(row['payload']);
          final link =
              '${row['deep_link'] ?? row['web_url'] ?? payload['url'] ?? ''}';
          final thread = RegExp(r'threads?/(\d+)').firstMatch(link);
          final event = RegExp(r'events?/(\d+)').firstMatch(link);
          final band = RegExp(r'bands?/(\d+)').firstMatch(link);
          final venue = RegExp(r'venues?/(\d+)').firstMatch(link);
          if (thread != null) {
            await openPage(
              context,
              ThreadScreen(threadId: int.parse(thread.group(1)!)),
            );
          } else if (event != null) {
            await openPage(
              context,
              EventDetailScreen(eventId: int.parse(event.group(1)!)),
            );
          } else if (band != null) {
            await openPage(
              context,
              BandDetailScreen(bandId: int.parse(band.group(1)!)),
            );
          } else if (venue != null) {
            await openPage(
              context,
              VenueDetailScreen(venueId: int.parse(venue.group(1)!)),
            );
          }
          reload();
        },
      ),
    ),
  );
}

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await WorkspaceRepository().load(
        '/me/notification-preferences',
      );
      if (mounted) setState(() => _items = records(data['data']));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await WorkspaceRepository().save('/me/notification-preferences', {
        'preferences': _items,
      }, method: 'PUT');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preferenze email')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) Text(_error!),
        if (_items == null && _error == null) const LinearProgressIndicator(),
        for (final item in _items ?? <Map<String, dynamic>>[])
          SwitchListTile(
            title: Text('${item['label']}'),
            value: item['mail_enabled'] == true,
            onChanged: _busy
                ? null
                : (v) => setState(() => item['mail_enabled'] = v),
          ),
        FilledButton(
          onPressed: _items == null || _busy ? null : _save,
          child: const Text('Salva'),
        ),
      ],
    ),
  );
}

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});
  @override
  Widget build(BuildContext context) => const WorkflowFormScreen(
    title: 'Accetta invito',
    path: '/me/invites/accept',
    fields: [
      FormFieldSpec(
        'token',
        'Codice o link dell’invito ricevuto',
        required: true,
      ),
      FormFieldSpec(
        'kind',
        'Tipo di invito',
        kind: InputKind.choice,
        choices: {
          'entity': 'Invito a gestire un profilo',
          'campaign': 'Invito campagna',
        },
        initial: 'entity',
        required: true,
      ),
    ],
  );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => RemotePage(
    title: 'Guide Bookalo',
    path: '/instructions',
    builder: (context, data, reload) => [
      for (final page in records(data['pages']))
        ExpansionTile(
          title: Text('${page['title']}'),
          subtitle: Text('${page['excerpt']}'),
          children: [
            for (final section in records(page['sections']))
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${section['title']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final paragraph
                        in (section['paragraphs'] as List? ?? []))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('$paragraph'),
                      ),
                  ],
                ),
              ),
          ],
        ),
    ],
  );
}
