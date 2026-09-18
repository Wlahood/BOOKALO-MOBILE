import 'package:flutter/material.dart';
import '../../repositories/workspace_repository.dart';
import 'common.dart';
import 'workflow_form_screen.dart';
import 'messages_screen.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});
  @override
  Widget build(BuildContext context) => RecordListScreen(
    title: 'Bacheca',
    path: '/workspace/my/bacheca',
    listKey: 'posts',
    filters: const {
      'type': 'Tipo: band_offer / venue_offer',
      'region': 'Regione',
      'province': 'Sigla provincia',
      'status': 'Stato: open / closed',
      'start_date': 'Dal (AAAA-MM-GG)',
      'end_date': 'Al (AAAA-MM-GG)',
    },
    itemBuilder: (context, post, reload) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${post['title'] ?? post['band']?['name'] ?? post['venue']?['name'] ?? 'Annuncio'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${post['band']?['name'] ?? post['venue']?['name'] ?? ''}'),
            Text('${post['start_date']} → ${post['end_date']}'),
            Text('${post['region'] ?? ''} ${post['province_code'] ?? ''}'),
            SelectableText('${post['message'] ?? ''}'),
            Text('Stato: ${post['status']}'),
            if (post['status'] == 'open')
              Wrap(
                children: [
                  TextButton(
                    onPressed: () async {
                      try {
                        final data = await WorkspaceRepository().load(
                          '/workspace/my/bacheca/${post['id']}/contact',
                        );
                        final options = records(data['options']);
                        if (!context.mounted) return;
                        final result = await openPage<Map<String, dynamic>>(
                          context,
                          WorkflowFormScreen(
                            title: 'Contatta annuncio',
                            path: '/workspace/my/bacheca/${post['id']}/contact',
                            fields: [
                              FormFieldSpec(
                                '${data['contactType']}_id',
                                'Invia come',
                                kind: InputKind.choice,
                                choices: {
                                  for (final e in options)
                                    '${e['id']}': '${e['name']}',
                                },
                                required: true,
                              ),
                              const FormFieldSpec(
                                'body',
                                'Messaggio',
                                kind: InputKind.multiline,
                                required: true,
                              ),
                            ],
                          ),
                        );
                        if (result != null && context.mounted) {
                          final id = RegExp(
                            r'/threads/(\d+)',
                          ).firstMatch('${result['web_url']}')?.group(1);
                          if (id != null) {
                            await openPage(
                              context,
                              ThreadScreen(threadId: int.parse(id)),
                            );
                          }
                        }
                        reload();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                    child: const Text('Contatta'),
                  ),
                  if (post['can_close'] == true)
                    TextButton(
                      onPressed: () async {
                        await runAction(
                          context,
                          '/workspace/my/bacheca/${post['id']}/close',
                          confirm: true,
                        );
                        reload();
                      },
                      child: const Text('Chiudi annuncio'),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
