import 'package:flutter/material.dart';
import '../../repositories/workspace_repository.dart';
import '../../services/auth_controller.dart';
import '../band_detail_screen.dart';
import '../venue_detail_screen.dart';
import '../band_members_screen.dart';
import '../venue_members_screen.dart';
import 'common.dart';
import 'form_specs.dart';
import 'workflow_form_screen.dart';
import 'messages_screen.dart';
import 'board_screen.dart';
import 'account_screen.dart';
import 'admin_screen.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});
  @override
  Widget build(BuildContext context) => RemotePage(
    title: 'Il mio Bookalo',
    path: '/me/profile',
    builder: (context, profile, reload) {
      final user = object(profile['user']);
      return [
        Text(
          '${user['name'] ?? ''}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('${user['email'] ?? ''}'),
        if (user['email_verified_at'] == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Verifica l’email per accedere alle funzioni riservate.',
                  ),
                  FilledButton(
                    onPressed: () => runAction(
                      context,
                      '/me/email/verification-notification',
                    ),
                    child: const Text('Invia link di verifica'),
                  ),
                ],
              ),
            ),
          ),
        menuTile(
          'Dashboard e i miei spazi',
          Icons.dashboard_outlined,
          () => openPage(context, const DashboardScreen()),
        ),
        menuTile(
          'Messaggi e trattative',
          Icons.forum_outlined,
          () => openPage(context, const MessagesScreen()),
        ),
        menuTile(
          'Bacheca',
          Icons.campaign_outlined,
          () => openPage(context, const BoardScreen()),
        ),
        menuTile(
          'Notifiche',
          Icons.notifications_outlined,
          () => openPage(context, const NotificationsScreen()),
        ),
        menuTile(
          'Crea una band',
          Icons.add,
          () => openPage(
            context,
            WorkflowFormScreen(
              title: 'Nuova band',
              path: '/workspace/my/bands',
              fields: entityFields('bands'),
            ),
          ),
        ),
        menuTile(
          'Crea un locale',
          Icons.add_business,
          () => openPage(
            context,
            WorkflowFormScreen(
              title: 'Nuovo locale',
              path: '/workspace/my/venues',
              fields: entityFields('venues'),
            ),
          ),
        ),
        menuTile(
          'Rivendica un profilo',
          Icons.verified_user_outlined,
          () => openPage(context, const ClaimSearchScreen()),
        ),
        menuTile(
          'Le mie rivendicazioni',
          Icons.fact_check_outlined,
          () => openPage(context, const ClaimsScreen()),
        ),
        menuTile(
          'Inviti',
          Icons.mail_outline,
          () => openPage(context, const InviteScreen()),
        ),
        menuTile('Profilo e sicurezza', Icons.settings_outlined, () async {
          await openPage(context, const AccountScreen());
          reload();
        }),
        if (isStaff)
          menuTile(
            'Amministrazione',
            Icons.admin_panel_settings_outlined,
            () => openPage(context, const AdminScreen()),
          ),
        OutlinedButton.icon(
          onPressed: () => AuthController.instance.logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Esci'),
        ),
      ];
    },
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => RemotePage(
    title: 'Dashboard',
    path: '/workspace/dashboard',
    builder: (context, data, reload) => [
      for (final type in ['bands', 'venues']) ...[
        Text(
          type == 'bands' ? 'Le mie band' : 'I miei locali',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (records(data[type]).isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Nessun profilo associato.'),
          ),
        for (final entity in records(data[type]))
          menuTile(
            '${entity['name']}',
            type == 'bands' ? Icons.music_note : Icons.store,
            () => openPage(
              context,
              EntityWorkspaceScreen(type: type, entity: entity),
            ),
            subtitle: 'Ruolo: ${entity['pivot_role'] ?? ''}',
          ),
      ],
      const Divider(),
      Text('Attività recenti', style: Theme.of(context).textTheme.titleLarge),
      for (final c in records(data['recentCampaigns']))
        ListTile(
          title: Text('${c['title'] ?? 'Campagna'}'),
          subtitle: Text('${c['status']}'),
          onTap: () => openPage(context, const MessagesScreen()),
        ),
      for (final e in records(data['recentEvents']))
        ListTile(
          title: Text('${e['title']}'),
          subtitle: Text('${e['start_datetime']}'),
        ),
      for (final r in records(data['pendingBookingRequests']))
        ListTile(
          title: Text('${r['band']?['name']} → ${r['venue']?['name']}'),
          subtitle: const Text('Booking da gestire'),
          onTap: () =>
              openPage(context, BookingInboxScreen(venueId: r['venue_id'])),
        ),
      for (final invite in records(data['pendingInvites']))
        ListTile(
          title: Text('Invito: ${invite['email']}'),
          subtitle: Text('${invite['role']}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await runAction(
                context,
                '/me/invites/${invite['id']}',
                method: 'DELETE',
                confirm: true,
              );
              reload();
            },
          ),
        ),
    ],
  );
}

class EntityWorkspaceScreen extends StatelessWidget {
  const EntityWorkspaceScreen({
    super.key,
    required this.type,
    required this.entity,
  });
  final String type;
  final Map<String, dynamic> entity;
  @override
  Widget build(BuildContext context) {
    final id = entity['id'] as int;
    final band = type == 'bands';
    final capabilities = object(entity['capabilities']);
    final manage = capabilities['manageBookings'] == true;
    return Scaffold(
      appBar: AppBar(title: Text('${entity['name']}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          menuTile(
            'Profilo pubblico',
            Icons.public,
            () => openPage(
              context,
              band
                  ? BandDetailScreen(bandId: id)
                  : VenueDetailScreen(venueId: id),
            ),
          ),
          if (capabilities['editProfile'] == true)
            menuTile(
              'Modifica profilo e immagini',
              Icons.edit_outlined,
              () async {
                try {
                  final response = await WorkspaceRepository().load(
                    '/workspace/my/$type/$id/edit',
                  );
                  final initial = object(response[band ? 'band' : 'venue']);
                  initial['region'] = initial['location']?['region'];
                  initial['genres'] = records(
                    initial['genres'],
                  ).map((g) => g['id']).toList();
                  if (context.mounted) {
                    await openPage(
                      context,
                      WorkflowFormScreen(
                        title: 'Modifica ${entity['name']}',
                        path: '/workspace/my/$type/$id',
                        method: 'PUT',
                        fields: entityFields(type),
                        initial: initial,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
            ),
          if (capabilities['manageMembers'] == true)
            menuTile(
              'Membri e inviti',
              Icons.group_outlined,
              () => openPage(
                context,
                band
                    ? BandMembersScreen(bandId: id)
                    : VenueMembersScreen(venueId: id),
              ),
            ),
          if (manage) ...[
            menuTile(
              'Nuova campagna',
              Icons.send_outlined,
              () => openPage(
                context,
                WorkflowFormScreen(
                  title: 'Nuova campagna',
                  path: '/workspace/my/$type/$id/campaigns',
                  fields: campaignFields(type),
                ),
              ),
            ),
            menuTile(
              'Pubblica in bacheca',
              Icons.campaign_outlined,
              () => openPage(
                context,
                WorkflowFormScreen(
                  title: 'Nuovo annuncio',
                  path: '/workspace/my/$type/$id/board-posts',
                  fields: boardFields(type),
                ),
              ),
            ),
            if (band)
              menuTile(
                'Richiedi un booking',
                Icons.event_available,
                () => openPage(
                  context,
                  WorkflowFormScreen(
                    title: 'Richiesta booking',
                    path: '/workspace/bands/$id/booking-requests',
                    fields: bookingFields,
                  ),
                ),
              ),
            if (!band) ...[
              menuTile(
                'Richieste booking ricevute',
                Icons.inbox_outlined,
                () => openPage(context, BookingInboxScreen(venueId: id)),
              ),
              menuTile(
                'Gestisci eventi',
                Icons.event,
                () => openPage(context, VenueEventsScreen(venueId: id)),
              ),
            ],
          ],
          if (capabilities['delete'] == true)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Elimina profilo'),
              onTap: () => runAction(
                context,
                '/workspace/my/$type/$id',
                method: 'DELETE',
                confirm: true,
              ),
            ),
        ],
      ),
    );
  }
}

class BookingInboxScreen extends StatelessWidget {
  const BookingInboxScreen({super.key, required this.venueId});
  final int venueId;
  @override
  Widget build(BuildContext context) => RecordListScreen(
    title: 'Richieste booking',
    path: '/workspace/my/venues/$venueId/booking-requests',
    listKey: 'requests',
    itemBuilder: (context, row, reload) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${row['band']?['name']}'),
            Text('${row['start_date']} → ${row['end_date']}'),
            Text('${row['message'] ?? ''}'),
            Text('Stato: ${row['status']}'),
            if (row['status'] == 'pending')
              Wrap(
                children: [
                  for (final decision in ['accept', 'reject'])
                    TextButton(
                      onPressed: () async {
                        await openPage(
                          context,
                          WorkflowFormScreen(
                            title: decision == 'accept'
                                ? 'Accetta booking'
                                : 'Rifiuta booking',
                            path:
                                '/workspace/booking-requests/${row['id']}/$decision',
                            fields: const [
                              FormFieldSpec(
                                'response',
                                'Risposta',
                                kind: InputKind.multiline,
                              ),
                            ],
                          ),
                        );
                        reload();
                      },
                      child: Text(
                        decision == 'accept'
                            ? 'Accetta e crea evento'
                            : 'Rifiuta',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

class VenueEventsScreen extends StatelessWidget {
  const VenueEventsScreen({super.key, required this.venueId});
  final int venueId;
  @override
  Widget build(BuildContext context) => RecordListScreen(
    title: 'Eventi del locale',
    path: '/workspace/venues/$venueId/events',
    listKey: 'events',
    actions: [
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => openPage(
          context,
          WorkflowFormScreen(
            title: 'Nuovo evento',
            path: '/workspace/venues/$venueId/events',
            fields: eventFields,
          ),
        ),
      ),
    ],
    itemBuilder: (context, event, reload) => Card(
      child: ListTile(
        title: Text('${event['title']}'),
        subtitle: Text('${event['start_datetime']}'),
        onTap: () async {
          final initial = {
            ...event,
            'band_ids': records(event['bands']).map((b) => b['id']).toList(),
          };
          await openPage(
            context,
            WorkflowFormScreen(
              title: 'Modifica evento',
              path: '/workspace/venues/$venueId/events/${event['id']}',
              method: 'PUT',
              fields: eventFields,
              initial: initial,
            ),
          );
          reload();
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await runAction(
              context,
              '/workspace/venues/$venueId/events/${event['id']}',
              method: 'DELETE',
              confirm: true,
            );
            reload();
          },
        ),
      ),
    ),
  );
}

class ClaimSearchScreen extends StatelessWidget {
  const ClaimSearchScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rivendica un profilo')),
    body: ListView(
      children: [
        for (final type in ['bands', 'venues'])
          menuTile(
            type == 'bands' ? 'Cerca una band' : 'Cerca un locale',
            Icons.search,
            () async {
              final selected = await openPage<List<Map<String, dynamic>>>(
                context,
                LookupScreen(
                  title: 'Cerca',
                  source: '/workspace/claim-$type/search',
                ),
              );
              if (selected == null || selected.isEmpty || !context.mounted) {
                return;
              }
              await openPage(
                context,
                WorkflowFormScreen(
                  title: 'Rivendica ${selected.first['name']}',
                  path: '/workspace/$type/${selected.first['id']}/claim',
                  fields: claimFields,
                ),
              );
            },
          ),
      ],
    ),
  );
}

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});
  @override
  Widget build(BuildContext context) => RemotePage(
    title: 'Le mie rivendicazioni',
    path: '/workspace/my/claim-requests',
    builder: (context, data, reload) => [
      for (final type in ['band', 'venue'])
        for (final claim in records(data['${type}Claims']))
          Card(
            child: ListTile(
              title: Text('${claim[type]?['name']}'),
              subtitle: SelectableText(
                'Stato: ${claim['status']}\nCodice: ${claim['token'] ?? ''}\n${claim['message'] ?? ''}',
              ),
              trailing: claim['status'] == 'pending'
                  ? IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: () async {
                        await runAction(
                          context,
                          '/workspace/my/${type}s/${claim['${type}_id']}/claims',
                          method: 'DELETE',
                          confirm: true,
                        );
                        reload();
                      },
                    )
                  : null,
            ),
          ),
    ],
  );
}
