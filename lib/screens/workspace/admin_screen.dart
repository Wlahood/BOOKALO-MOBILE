import 'package:flutter/material.dart';
import '../../repositories/workspace_repository.dart';
import 'common.dart';
import 'form_specs.dart';
import 'workflow_form_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Amministrazione')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final type in ['bands', 'venues'])
          menuTile(
            type == 'bands' ? 'Gestisci band' : 'Gestisci locali',
            Icons.edit_note,
            () => openPage(context, AdminEntitiesScreen(type: type)),
          ),
        menuTile(
          'Generi musicali',
          Icons.music_note,
          () => openPage(context, const GenresScreen()),
        ),
        for (final type in ['band', 'venue'])
          menuTile(
            type == 'band' ? 'Rivendicazioni band' : 'Rivendicazioni locali',
            Icons.fact_check,
            () => openPage(context, ReviewClaimsScreen(type: type)),
          ),
      ],
    ),
  );
}

class AdminEntitiesScreen extends StatelessWidget {
  const AdminEntitiesScreen({super.key, required this.type});
  final String type;
  @override
  Widget build(BuildContext context) => RecordListScreen(
    title: type == 'bands' ? 'Gestisci band' : 'Gestisci locali',
    path: '/workspace/manage/$type',
    listKey: type,
    filters: const {
      'q': 'Nome',
      'region': 'Regione',
      'province': 'Sigla provincia',
    },
    actions: [
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => openPage(
          context,
          WorkflowFormScreen(
            title: 'Crea profilo',
            path: '/workspace/manage/$type',
            fields: entityFields(type, admin: true),
          ),
        ),
      ),
    ],
    itemBuilder: (context, row, reload) => Card(
      child: ListTile(
        title: Text('${row['name']}'),
        onTap: () async {
          try {
            final data = await WorkspaceRepository().load(
              '/workspace/manage/$type/${row['id']}/edit',
            );
            final initial = object(data[type == 'bands' ? 'band' : 'venue']);
            initial['region'] = initial['location']?['region'];
            initial['genres'] = records(
              initial['genres'],
            ).map((g) => g['id']).toList();
            if (context.mounted) {
              await openPage(
                context,
                WorkflowFormScreen(
                  title: 'Modifica profilo',
                  path: '/workspace/manage/$type/${row['id']}',
                  method: 'PUT',
                  fields: entityFields(type, admin: true),
                  initial: initial,
                ),
              );
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
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await runAction(
              context,
              '/workspace/manage/$type/${row['id']}',
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

class ReviewClaimsScreen extends StatelessWidget {
  const ReviewClaimsScreen({super.key, required this.type});
  final String type;
  @override
  Widget build(BuildContext context) => RecordListScreen(
    title: 'Revisione rivendicazioni',
    path: '/workspace/manage/$type-claims',
    listKey: 'claims',
    filters: const {'status': 'Stato: pending / approved / rejected'},
    itemBuilder: (context, row, reload) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${row[type]?['name']}'),
            Text('${row['user']?['name']} · ${row['user']?['email']}'),
            SelectableText(
              'Metodo: ${row['method']}\nCodice: ${row['token'] ?? ''}\n${row['message'] ?? ''}',
            ),
            Text('Stato: ${row['status']}'),
            if (row['status'] == 'pending')
              Wrap(
                children: [
                  for (final action in ['approve', 'reject'])
                    TextButton(
                      onPressed: () async {
                        await runAction(
                          context,
                          '/workspace/manage/$type-claims/${row['id']}/$action',
                          confirm: true,
                        );
                        reload();
                      },
                      child: Text(action == 'approve' ? 'Approva' : 'Rifiuta'),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

class GenresScreen extends StatelessWidget {
  const GenresScreen({super.key});
  @override
  Widget build(BuildContext context) => RecordListScreen(
    title: 'Generi musicali',
    path: '/workspace/manage/genres',
    listKey: 'genres',
    actions: [
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => openPage(
          context,
          const WorkflowFormScreen(
            title: 'Nuovo genere',
            path: '/workspace/manage/genres',
            fields: [FormFieldSpec('name', 'Nome', required: true)],
          ),
        ),
      ),
    ],
    itemBuilder: (context, row, reload) => ListTile(
      title: Text('${row['name']}'),
      subtitle: Text('${row['bands_count'] ?? 0} band'),
      onTap: () async {
        await openPage(
          context,
          WorkflowFormScreen(
            title: 'Modifica genere',
            path: '/workspace/manage/genres/${row['id']}',
            method: 'PUT',
            initial: row,
            fields: const [FormFieldSpec('name', 'Nome', required: true)],
          ),
        );
        reload();
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await runAction(
            context,
            '/workspace/manage/genres/${row['id']}',
            method: 'DELETE',
            confirm: true,
          );
          reload();
        },
      ),
    ),
  );
}
