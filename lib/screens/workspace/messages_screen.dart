import 'package:flutter/material.dart';
import '../../services/auth_controller.dart';
import 'common.dart';
import 'workflow_form_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context) => RecordListScreen(
    title: 'Messaggi e trattative',
    path: '/workspace/my/messages',
    listKey: 'threads',
    filters: isStaff
        ? const {
            'thread_id': 'Numero conversazione',
            'band_id': 'ID band',
            'venue_id': 'ID locale',
            'start_date': 'Dal (AAAA-MM-GG)',
            'end_date': 'Al (AAAA-MM-GG)',
          }
        : const {},
    itemBuilder: (context, row, reload) => Card(
      child: ListTile(
        leading: Badge(
          isLabelVisible: (row['unread_count'] ?? 0) > 0,
          label: Text('${row['unread_count'] ?? 0}'),
          child: const Icon(Icons.forum_outlined),
        ),
        title: Text('${row['band']?['name']} · ${row['venue']?['name']}'),
        subtitle: Text(
          '${row['latest_message']?['body'] ?? row['target']?['campaign']?['title'] ?? ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () async {
          await openPage(context, ThreadScreen(threadId: row['id']));
          reload();
        },
      ),
    ),
  );
}

class ThreadScreen extends StatelessWidget {
  const ThreadScreen({super.key, required this.threadId});
  final int threadId;
  @override
  Widget build(BuildContext context) => RemotePage(
    title: 'Conversazione',
    path: '/workspace/my/threads/$threadId',
    builder: (context, data, reload) {
      final thread = object(data['thread']);
      final target = object(thread['target']);
      final campaign = object(target['campaign']);
      final userId = AuthController.instance.state.value.user?.id;
      final dates = (data['campaignDateOptions'] as List? ?? [])
          .map((e) => '$e')
          .toList();
      Future<void> proposal([Map<String, dynamic> initial = const {}]) async {
        await openPage(
          context,
          WorkflowFormScreen(
            title: 'Proposta',
            path: '/workspace/my/threads/$threadId/proposals',
            initial: initial,
            fields: [
              FormFieldSpec(
                'date',
                'Data',
                kind: InputKind.choice,
                choices: {for (final d in dates) d: d},
                required: true,
              ),
              const FormFieldSpec('fee', 'Compenso', kind: InputKind.number),
              const FormFieldSpec('currency', 'Valuta', initial: 'EUR'),
              const FormFieldSpec('notes', 'Note', kind: InputKind.multiline),
              const FormFieldSpec(
                'proposal_body',
                'Messaggio',
                kind: InputKind.multiline,
              ),
            ],
          ),
        );
        reload();
      }

      return [
        Text(
          '${thread['band']?['name']} · ${thread['venue']?['name']}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text('${data['threadOriginLabel'] ?? ''}'),
        if (campaign.isNotEmpty)
          Text('${campaign['title'] ?? ''} · ${target['status'] ?? ''}'),
        if (data['counterpartIsUnclaimed'] == true)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Questo profilo non è ancora rivendicato. Consulta i suoi recapiti pubblici per contattarlo.',
              ),
            ),
          ),
        for (final message in records(data['messages']))
          Card(
            color: message['sender_user_id'] == userId
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${message['sender']?['name'] ?? 'Bookalo'} · ${message['created_at'] ?? ''}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  SelectableText('${message['body'] ?? ''}'),
                  if (message['type'] == 'proposal') ...[
                    Text('Data: ${message['payload_json']?['date'] ?? ''}'),
                    Text(
                      'Compenso: ${message['payload_json']?['fee'] ?? 'Da concordare'} ${message['payload_json']?['currency'] ?? ''}',
                    ),
                    Text('${message['payload_json']?['notes'] ?? ''}'),
                    if (message['payload_json']?['accepted_at'] != null)
                      const Text('Proposta accettata'),
                    if (message['id'] == data['latestProposalId'] &&
                        message['sender_user_id'] != userId &&
                        message['payload_json']?['accepted_at'] == null &&
                        data['canSendProposal'] == true)
                      Wrap(
                        children: [
                          TextButton(
                            onPressed: () async {
                              await runAction(
                                context,
                                '/workspace/my/threads/$threadId/proposals/${message['id']}/accept',
                                confirm: true,
                              );
                              reload();
                            },
                            child: const Text('Accetta proposta'),
                          ),
                          TextButton(
                            onPressed: () =>
                                proposal(object(message['payload_json'])),
                            child: const Text('Controproposta'),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
        FilledButton.icon(
          icon: const Icon(Icons.send),
          label: const Text('Scrivi un messaggio'),
          onPressed: () async {
            await openPage(
              context,
              WorkflowFormScreen(
                title: 'Nuovo messaggio',
                path: '/workspace/my/threads/$threadId/messages',
                fields: const [
                  FormFieldSpec(
                    'body',
                    'Messaggio',
                    kind: InputKind.multiline,
                    required: true,
                  ),
                ],
              ),
            );
            reload();
          },
        ),
        if (data['canSendProposal'] == true && dates.isNotEmpty)
          OutlinedButton(
            onPressed: proposal,
            child: const Text('Invia proposta'),
          ),
        if (data['proposalBlockedReason'] != null)
          Text('${data['proposalBlockedReason']}'),
        if (data['canConfirmEvent'] == true)
          FilledButton(
            onPressed: () async {
              await runAction(
                context,
                '/workspace/my/threads/$threadId/confirm-event',
                confirm: true,
              );
              reload();
            },
            child: const Text('Conferma evento pubblico'),
          ),
        if (data['canResumeTarget'] == true)
          OutlinedButton(
            onPressed: () async {
              await runAction(
                context,
                '/workspace/my/campaign-targets/${target['id']}/resume',
              );
              reload();
            },
            child: const Text('Riattiva trattativa'),
          ),
        if (data['canCloseCampaign'] == true)
          OutlinedButton(
            onPressed: () async {
              await runAction(
                context,
                '/workspace/my/campaigns/${campaign['id']}/close',
                confirm: true,
              );
              reload();
            },
            child: const Text('Chiudi campagna'),
          ),
      ];
    },
  );
}
