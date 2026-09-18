import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../repositories/workspace_repository.dart';
import '../../services/api_client.dart';

enum InputKind {
  text,
  multiline,
  email,
  password,
  number,
  date,
  datetime,
  time,
  choice,
  toggle,
  lookup,
  file,
}

class FormFieldSpec {
  const FormFieldSpec(
    this.keyName,
    this.label, {
    this.kind = InputKind.text,
    this.required = false,
    this.choices = const {},
    this.source,
    this.multiple = false,
    this.initial,
  });
  final String keyName, label;
  final InputKind kind;
  final bool required, multiple;
  final Map<String, String> choices;
  final String? source;
  final dynamic initial;
}

class WorkflowFormScreen extends StatefulWidget {
  const WorkflowFormScreen({
    super.key,
    required this.title,
    required this.path,
    required this.fields,
    this.method = 'POST',
    this.initial = const {},
    this.repository,
  });
  final String title, path, method;
  final List<FormFieldSpec> fields;
  final Map<String, dynamic> initial;
  final WorkspaceRepository? repository;
  @override
  State<WorkflowFormScreen> createState() => _WorkflowFormScreenState();
}

class _WorkflowFormScreenState extends State<WorkflowFormScreen> {
  final _form = GlobalKey<FormState>();
  late final WorkspaceRepository _repo;
  final _values = <String, dynamic>{};
  final _controllers = <String, TextEditingController>{};
  final _files = <String, UploadFile>{};
  final _labels = <String, String>{};
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _errors = {};
  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? WorkspaceRepository();
    for (final f in widget.fields) {
      final value =
          widget.initial[f.keyName] ?? f.initial ?? (f.multiple ? [] : null);
      _values[f.keyName] = value;
      _controllers[f.keyName] = TextEditingController(
        text: value == null ? '' : '$value',
      );
      if (value is List) _labels[f.keyName] = '${value.length} selezionati';
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() {
      _busy = true;
      _error = null;
      _errors = {};
    });
    try {
      final body = <String, dynamic>{};
      for (final f in widget.fields) {
        if (f.kind == InputKind.file) continue;
        final value = _values[f.keyName];
        body[f.keyName] = value is String && value.trim().isEmpty
            ? null
            : value;
      }
      if (widget.method == 'POST' &&
          [
            '/workspace/my/bands',
            '/workspace/my/venues',
          ].contains(widget.path)) {
        final duplicates = await _repo.load(
          '${widget.path}/create/check-duplicates',
          query: {'q': '${body['name'] ?? ''}'},
        );
        final matches = [
          ...?duplicates['exact'] as List?,
          ...?duplicates['similar'] as List?,
        ];
        if (matches.isNotEmpty) {
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Profili già presenti'),
              content: Text(
                'Prima di creare un nuovo profilo, controlla questi nomi:\n${matches.map((e) => '${e['name']} — ${e['location_label'] ?? ''}').join('\n')}\n\nSe è il tuo profilo, puoi rivendicarlo dalla tua area.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Torna al modulo'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('È un altro profilo'),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }
      }
      final result = await _repo.save(
        widget.path,
        body,
        method: widget.method,
        files: _files,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Operazione completata'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result['success'] ?? result['status'] ?? 'Dati salvati.'}',
                ),
                if (result['warning'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('${result['warning']}'),
                  ),
                if (result['claim_token'] != null)
                  SelectableText(
                    'Codice di rivendicazione: ${result['claim_token']}',
                  ),
                for (final target
                    in (result['unclaimed_targets'] as List? ?? []))
                  Text(
                    '${target['name']}: ${target['email_sent'] == true ? 'email inviata' : 'contatta tramite i recapiti del profilo'}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, result);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _errors = e.errors;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Impossibile completare la richiesta. $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate(FormFieldSpec f) async {
    final current =
        DateTime.tryParse(_controllers[f.keyName]!.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    String value =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (f.kind == InputKind.datetime) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
      );
      if (time == null) return;
      value +=
          ' ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }
    if (mounted) {
      setState(() {
        _controllers[f.keyName]!.text = value;
        _values[f.keyName] = value;
      });
    }
  }

  Widget _field(FormFieldSpec f) {
    final c = _controllers[f.keyName]!;
    final error = _errors[f.keyName];
    final decoration = InputDecoration(
      labelText: '${f.label}${f.required ? ' *' : ''}',
      border: const OutlineInputBorder(),
      errorText: error == null
          ? null
          : (error is List ? error.join('\n') : '$error'),
    );
    if (f.kind == InputKind.toggle) {
      return SwitchListTile(
        title: Text(f.label),
        value: _values[f.keyName] == true || _values[f.keyName] == 1,
        onChanged: _busy ? null : (v) => setState(() => _values[f.keyName] = v),
      );
    }
    if (f.kind == InputKind.choice) {
      return DropdownButtonFormField<String>(
        initialValue: _values[f.keyName]?.toString(),
        decoration: decoration,
        items: f.choices.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: _busy ? null : (v) => setState(() => _values[f.keyName] = v),
        validator: (v) => f.required && v == null ? 'Scegli un valore' : null,
      );
    }
    if (f.kind == InputKind.lookup) {
      return FormField<dynamic>(
        validator: (_) =>
            f.required &&
                (_values[f.keyName] == null ||
                    (_values[f.keyName] is List &&
                        (_values[f.keyName] as List).isEmpty))
            ? 'Seleziona almeno un elemento'
            : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: Text(
                '${f.label}: ${_labels[f.keyName] ?? (_values[f.keyName] == null ? 'seleziona' : 'selezione presente')}',
              ),
              onPressed: _busy
                  ? null
                  : () async {
                      var source = f.source!;
                      if (source.contains('{region}')) {
                        final region =
                            _controllers['region']?.text ??
                            _values['region']?.toString() ??
                            '';
                        if (region.isEmpty) {
                          setState(
                            () => _error = 'Seleziona prima la regione.',
                          );
                          return;
                        }
                        source = source.replaceAll(
                          '{region}',
                          Uri.encodeComponent(region),
                        );
                      }
                      final selected =
                          await Navigator.push<List<Map<String, dynamic>>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LookupScreen(
                                title: f.label,
                                source: source,
                                multiple: f.multiple,
                                selected: _values[f.keyName],
                              ),
                            ),
                          );
                      if (selected != null && mounted) {
                        setState(() {
                          final ids = selected.map((e) => e['id']).toList();
                          _values[f.keyName] = f.multiple
                              ? ids
                              : (ids.isEmpty ? null : ids.first);
                          _labels[f.keyName] = selected
                              .map((e) => '${e['name']}')
                              .join(', ');
                          c.text = _values[f.keyName]?.toString() ?? '';
                          if (f.keyName == 'region') {
                            _values['location_id'] = null;
                            _labels.remove('location_id');
                          }
                        });
                      }
                    },
            ),
            if (state.hasError)
              Text(
                state.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      );
    }
    if (f.kind == InputKind.file) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.attach_file),
        label: Text(
          '${f.label}: ${_files[f.keyName]?.name ?? 'scegli immagine'}',
        ),
        onPressed: _busy
            ? null
            : () async {
                final file = await openFile(
                  acceptedTypeGroups: [
                    const XTypeGroup(
                      label: 'Immagini',
                      extensions: ['jpg', 'jpeg', 'png', 'webp'],
                      mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
                    ),
                  ],
                );
                if (file == null) return;
                final bytes = await file.readAsBytes();
                if (!mounted) return;
                if (bytes.length > 4 * 1024 * 1024) {
                  setState(
                    () => _error = 'L’immagine deve essere inferiore a 4 MB.',
                  );
                  return;
                }
                setState(
                  () => _files[f.keyName] = UploadFile(file.name, bytes),
                );
              },
      );
    }
    return TextFormField(
      controller: c,
      decoration: decoration,
      enabled: !_busy,
      obscureText: f.kind == InputKind.password,
      maxLines: f.kind == InputKind.multiline ? 4 : 1,
      keyboardType: f.kind == InputKind.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : f.kind == InputKind.email
          ? TextInputType.emailAddress
          : TextInputType.text,
      readOnly: [
        InputKind.date,
        InputKind.datetime,
        InputKind.time,
      ].contains(f.kind),
      onTap: [InputKind.date, InputKind.datetime].contains(f.kind)
          ? () => _pickDate(f)
          : f.kind == InputKind.time
          ? () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (t != null) {
                c.text =
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              }
            }
          : null,
      validator: (v) {
        if (f.required && (v ?? '').trim().isEmpty) return 'Campo obbligatorio';
        if (f.kind == InputKind.number &&
            (v ?? '').isNotEmpty &&
            num.tryParse(v!.replaceAll(',', '.')) == null) {
          return 'Inserisci un numero';
        }
        return null;
      },
      onSaved: (v) => _values[f.keyName] = f.kind == InputKind.number
          ? num.tryParse((v ?? '').replaceAll(',', '.'))
          : v,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          for (final f in widget.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _field(f),
            ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Salvataggio…' : 'Conferma'),
          ),
        ],
      ),
    ),
  );
}

class LookupScreen extends StatefulWidget {
  const LookupScreen({
    super.key,
    required this.title,
    required this.source,
    this.multiple = false,
    this.selected,
  });
  final String title, source;
  final bool multiple;
  final dynamic selected;
  @override
  State<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends State<LookupScreen> {
  final _filters = <String, String>{};
  final _filterLabels = <String, String>{};
  int _page = 1, _lastPage = 1;

  Future<void> _chooseFilter(String key, String label, String source) async {
    final selected = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => LookupScreen(title: label, source: source),
      ),
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() {
      final item = selected.first;
      _filters[key] =
          '${key == 'province' ? item['code'] ?? item['province_code'] : item['id']}';
      _filterLabels[key] = '${item['name']}';
      if (key == 'region') {
        _filters.remove('province');
        _filterLabels.remove('province');
      }
      _page = 1;
    });
    await _load();
  }

  void _searchFirstPage() {
    _page = 1;
    _load();
  }

  final _search = TextEditingController();
  final _selected = <dynamic, Map<String, dynamic>>{};
  List<Map<String, dynamic>> _items = [];
  bool _busy = true;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    if (widget.selected is List) {
      for (final id in widget.selected as List) {
        _selected[id] = {'id': id, 'name': 'Selezione già presente'};
      }
    }
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(widget.source);
      final response = await ApiClient().getJson(
        uri.path,
        query: {
          ...uri.queryParameters,
          ..._filters,
          'page': '$_page',
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        },
      );
      dynamic rows =
          response['data'] ??
          response['options'] ??
          response['results'] ??
          response;
      if (rows is Map) rows = rows['data'] ?? rows['items'] ?? [];
      final list = (rows as List).map<Map<String, dynamic>>((e) {
        if (e is String) return {'id': e, 'name': e};
        final m = Map<String, dynamic>.from(e);
        return {
          ...m,
          'id': m['id'] ?? m['value'],
          'name': m['name'] ?? m['label'] ?? m['city'] ?? m['region'] ?? '',
        };
      }).toList();
      if (mounted && generation == _generation) {
        setState(() {
          _items = list;
          final meta =
              response['meta'] ??
              (response['data'] is Map ? response['data'] : response);
          _lastPage = meta['last_page'] is int ? meta['last_page'] : 1;
          for (final item in list) {
            if (_selected.containsKey(item['id'])) _selected[item['id']] = item;
          }
        });
      }
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = '$e');
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        if (widget.multiple)
          TextButton(
            onPressed: () => Navigator.pop(context, _selected.values.toList()),
            child: Text('Scegli (${_selected.length})'),
          ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: 'Cerca per nome',
              suffixIcon: IconButton(
                onPressed: _searchFirstPage,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => _searchFirstPage(),
          ),
        ),
        if (widget.source.contains('/campaigns/search/'))
          Wrap(
            children: [
              TextButton(
                onPressed: () =>
                    _chooseFilter('region', 'Regione', '/locations/regions'),
                child: Text(_filterLabels['region'] ?? 'Regione'),
              ),
              TextButton(
                onPressed: () => _chooseFilter(
                  'province',
                  'Provincia',
                  '/locations/provinces?region=${Uri.encodeComponent(_filters['region'] ?? '')}',
                ),
                child: Text(_filterLabels['province'] ?? 'Provincia'),
              ),
              if (widget.source.endsWith('/bands'))
                TextButton(
                  onPressed: () =>
                      _chooseFilter('genre_id', 'Genere', '/genres'),
                  child: Text(_filterLabels['genre_id'] ?? 'Genere'),
                ),
              if (_filters.isNotEmpty)
                IconButton(
                  tooltip: 'Azzera filtri',
                  icon: const Icon(Icons.filter_alt_off),
                  onPressed: () {
                    setState(() {
                      _filters.clear();
                      _filterLabels.clear();
                    });
                    _searchFirstPage();
                  },
                ),
            ],
          ),
        if (_error != null) Text(_error!),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: ListView(
            children: [
              if (!_busy && _items.isEmpty)
                const ListTile(
                  title: Text('Nessun risultato. Prova a cercare per nome.'),
                ),
              for (final item in _items)
                CheckboxListTile(
                  title: Text('${item['name']}'),
                  subtitle: (item['location_label'] ?? item['province']) == null
                      ? null
                      : Text('${item['location_label'] ?? item['province']}'),
                  value: _selected.containsKey(item['id']),
                  onChanged: (v) {
                    if (!widget.multiple) {
                      Navigator.pop(context, [item]);
                      return;
                    }
                    setState(() {
                      if (v == true) {
                        _selected[item['id']] = item;
                      } else {
                        _selected.remove(item['id']);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        if (_lastPage > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: !_busy && _page > 1
                    ? () {
                        _page--;
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page / $_lastPage'),
              IconButton(
                onPressed: !_busy && _page < _lastPage
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
