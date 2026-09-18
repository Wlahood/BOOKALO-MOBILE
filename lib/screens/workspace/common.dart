import 'package:flutter/material.dart';
import '../../repositories/workspace_repository.dart';
import '../../services/api_client.dart';
import '../../services/auth_controller.dart';
import '../login_screen.dart';
import 'workflow_form_screen.dart';

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.push<T>(context, MaterialPageRoute(builder: (_) => page));
Future<void> runAction(
  BuildContext context,
  String path, {
  String method = 'POST',
  Map<String, dynamic> body = const {},
  bool confirm = false,
}) async {
  if (confirm) {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confermi l’operazione?'),
        content: const Text('Questa operazione modifica i dati di Bookalo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
    if (yes != true) return;
  }
  try {
    final result = await WorkspaceRepository().save(path, body, method: method);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result['success'] ?? result['status'] ?? 'Operazione completata.'}',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Operazione non completata'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class RemotePage extends StatefulWidget {
  const RemotePage({
    super.key,
    required this.title,
    required this.path,
    required this.builder,
    this.query = const {},
    this.actions = const [],
  });
  final String title, path;
  final Map<String, String> query;
  final List<Widget> actions;
  final List<Widget> Function(BuildContext, Map<String, dynamic>, VoidCallback)
  builder;
  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  late Future<Map<String, dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = WorkspaceRepository().load(widget.path, query: widget.query);
  }

  void _reload() {
    if (mounted) {
      setState(
        () => _future = WorkspaceRepository().load(
          widget.path,
          query: widget.query,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        ...widget.actions,
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          tooltip: 'Aggiorna',
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final e = snapshot.error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$e'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Riprova'),
                  ),
                  if (e is ApiException && e.statusCode == 401)
                    TextButton(
                      onPressed: () async {
                        await openPage(context, const LoginScreen());
                        _reload();
                      },
                      child: const Text('Accedi'),
                    ),
                  if (e is ApiException && e.statusCode == 403)
                    TextButton(
                      onPressed: () => runAction(
                        context,
                        '/me/email/verification-notification',
                      ),
                      child: const Text('Invia email di verifica'),
                    ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _future;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: widget.builder(context, snapshot.data!, _reload),
          ),
        );
      },
    ),
  );
}

class RecordListScreen extends StatefulWidget {
  const RecordListScreen({
    super.key,
    required this.title,
    required this.path,
    required this.listKey,
    required this.itemBuilder,
    this.filters = const {},
    this.actions = const [],
  });
  final String title, path, listKey;
  final Map<String, String> filters;
  final List<Widget> actions;
  final Widget Function(BuildContext, Map<String, dynamic>, VoidCallback)
  itemBuilder;
  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final _filterLabels = <String, String>{};

  Widget _filter(MapEntry<String, String> entry) {
    final key = entry.key;
    final controller = _controllers[key]!;
    Map<String, String>? choices;
    if (key == 'type') {
      choices = {
        '': 'Tutti',
        'band_offer': 'Proposte delle band',
        'venue_offer': 'Proposte dei locali',
      };
    }
    if (key == 'status') {
      choices = widget.path.contains('bacheca')
          ? {'open': 'Aperti', 'closed': 'Chiusi'}
          : {
              'pending': 'In attesa',
              'approved': 'Approvate',
              'rejected': 'Rifiutate',
              'cancelled': 'Annullate',
            };
    }
    if (choices != null) {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: key == 'type' ? 'Tipo di annuncio' : 'Stato',
        ),
        initialValue: controller.text.isEmpty ? null : controller.text,
        items: choices.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) => controller.text = v ?? '',
      );
    }
    if (['band_id', 'venue_id', 'region', 'province'].contains(key)) {
      return ListTile(
        title: Text(entry.value.replaceAll('ID ', '')),
        subtitle: Text(_filterLabels[key] ?? 'Tutti'),
        trailing: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => setState(() {
            controller.clear();
            _filterLabels.remove(key);
          }),
        ),
        onTap: () async {
          final source = key == 'region'
              ? '/locations/regions'
              : key == 'province'
              ? '/locations/provinces?region=${Uri.encodeComponent(_controllers['region']?.text ?? '')}'
              : key == 'band_id'
              ? '/bands'
              : '/venues';
          final result = await openPage<List<Map<String, dynamic>>>(
            context,
            LookupScreen(title: entry.value, source: source),
          );
          if (result != null && result.isNotEmpty && mounted) {
            setState(() {
              controller.text =
                  '${key == 'province' ? result.first['code'] : result.first['id']}';
              _filterLabels[key] = '${result.first['name']}';
              if (key == 'region') {
                _controllers['province']?.clear();
                _filterLabels.remove('province');
              }
            });
          }
        },
      );
    }
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: entry.value.replaceAll(' (AAAA-MM-GG)', ''),
      ),
      readOnly: key.endsWith('_date'),
      onTap: key.endsWith('_date')
          ? () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDate:
                    DateTime.tryParse(controller.text) ?? DateTime.now(),
              );
              if (date != null) {
                controller.text =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              }
            }
          : null,
      onSubmitted: (_) {
        _page = 1;
        _load();
      },
    );
  }

  int _page = 1, _last = 1;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  final _controllers = <String, TextEditingController>{};
  @override
  void initState() {
    super.initState();
    for (final key in widget.filters.keys) {
      _controllers[key] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await WorkspaceRepository().load(
        widget.path,
        query: {
          'page': '$_page',
          for (final e in _controllers.entries)
            if (e.value.text.isNotEmpty) e.key: e.value.text,
        },
      );
      dynamic page = widget.listKey.isEmpty ? data : data[widget.listKey];
      dynamic rows = page is Map ? page['data'] : page;
      if (rows is Map) rows = rows['data'];
      final list = (rows as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final last = page is Map
          ? (page['last_page'] ?? object(data['meta'])['last_page'])
          : object(data['meta'])['last_page'];
      if (mounted) {
        setState(() {
          _rows = list;
          _last = (last as num?)?.toInt() ?? 1;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        ...widget.actions,
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        if (widget.filters.isNotEmpty)
          ExpansionTile(
            title: const Text('Filtri di ricerca'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final entry in widget.filters.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _filter(entry),
                      ),
                    FilledButton(
                      onPressed: () {
                        _page = 1;
                        _load();
                      },
                      child: const Text('Cerca'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                if (!_busy && _rows.isEmpty)
                  const ListTile(title: Text('Nessun risultato')),
                for (final row in _rows)
                  widget.itemBuilder(context, row, () => _load()),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _page > 1 && !_busy
                  ? () {
                      _page--;
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$_page / $_last'),
            IconButton(
              onPressed: _page < _last && !_busy
                  ? () {
                      _page++;
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    ),
  );
}

bool get isStaff => [
  'admin',
  'curator',
].contains(AuthController.instance.state.value.user?.role);
Widget menuTile(
  String title,
  IconData icon,
  VoidCallback onTap, {
  String? subtitle,
}) => Card(
  child: ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  ),
);
Map<String, dynamic> object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> records(dynamic value) =>
    (value as List? ?? []).map(object).toList();
