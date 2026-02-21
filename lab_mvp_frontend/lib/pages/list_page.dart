import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/entities_api.dart';

class ListPage extends StatefulWidget {
  const ListPage._({
    required this.title,
    required this.type,
    required this.api,
    required this.loader,
  });

  final String title;
  final String type;
  final EntitiesApi api;
  final Future<List<dynamic>> Function() loader;

  static Widget equipment({required EntitiesApi api}) =>
      ListPage._(title: '장비', type: 'equipment', api: api, loader: api.listEquipment);
  static Widget facilities({required EntitiesApi api}) =>
      ListPage._(title: '시설', type: 'facility', api: api, loader: api.listFacilities);
  static Widget reagents({required EntitiesApi api}) =>
      ListPage._(title: '시약', type: 'reagent', api: api, loader: api.listReagents);
  static Widget records({required EntitiesApi api}) =>
      ListPage._(title: '실험기록', type: 'record', api: api, loader: api.listRecords);
  static Widget sops({required EntitiesApi api}) =>
      ListPage._(title: 'SOP', type: 'sop', api: api, loader: api.listSops);
  static Widget templates({required EntitiesApi api}) =>
      ListPage._(title: '템플릿', type: 'template', api: api, loader: api.listTemplates);

  static Widget index({required EntitiesApi api}) => _IndexPage(api: api);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  String q = '';
  dynamic selected;
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      selected = null;
    });
    try {
      items = await widget.loader();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = q.isEmpty
        ? items
        : items.where((it) {
            final s = (it['name'] ?? it['title'] ?? '').toString().toLowerCase();
            final tags = (it['tags'] ?? '').toString().toLowerCase();
            return s.contains(q.toLowerCase()) || tags.contains(q.toLowerCase());
          }).toList();

    return Row(
      children: [
        SizedBox(
          width: 390,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: '검색 (name/title, tags)',
                  ),
                  onChanged: (v) => setState(() => q = v),
                ),
              ),
              if (loading) const LinearProgressIndicator(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, idx) {
                    final it = filtered[idx] as Map<String, dynamic>;
                    final label = (it['name'] ?? it['title'] ?? 'Untitled').toString();
                    final subtitle = (it['tags'] ?? '').toString();
                    final isSel = selected != null && selected['id'] == it['id'];
                    return ListTile(
                      title: Text(label),
                      subtitle: subtitle.isEmpty ? null : Text(subtitle),
                      selected: isSel,
                      onTap: () => setState(() => selected = it),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildCreateButtons(),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? Center(child: Text('${widget.title} 항목을 선택하세요'))
              : _DetailEditor(
                  api: widget.api,
                  type: widget.type,
                  item: selected as Map<String, dynamic>,
                  onChanged: (updated) => setState(() => selected = updated),
                  onDeleted: () async {
                    await _load();
                    setState(() => selected = null);
                  },
                ),
        )
      ],
    );
  }

  Widget _buildCreateButtons() {
    // record는 "템플릿으로 새 기록"도 제공
    if (widget.type == 'record') {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                final created = await widget.api.create(widget.type, _emptyFor(widget.type));
                await _load();
                setState(() => selected = created);
              },
              icon: const Icon(Icons.add),
              label: const Text('빈 기록'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                final body = await showDialog<Map<String, dynamic>?>(
                  context: context,
                  builder: (_) => _RecordWizardDialog(api: widget.api),
                );
                if (body == null) return;
                final created = await widget.api.create('record', body);
                await _load();
                setState(() => selected = created);
              },
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('템플릿으로 새 기록'),
            ),
          ),
        ],
      );
    }

    return FilledButton.icon(
      onPressed: () async {
        final created = await widget.api.create(widget.type, _emptyFor(widget.type));
        await _load();
        setState(() => selected = created);
      },
      icon: const Icon(Icons.add),
      label: const Text('새로 만들기'),
    );
  }

  Map<String, dynamic> _emptyFor(String type) {
    switch (type) {
      case 'equipment':
        return {
          'name': 'New Equipment',
          'status': '사용중',
          'domain': '공용',
          'body_markdown': _equipmentTemplate(),
        };
      case 'facility':
        return {
          'name': 'New Facility',
          'facility_type': '기타',
          'bsl_level': '해당없음',
          'rules_summary': _facilityTemplate(),
        };
      case 'reagent':
        return {
          'name': 'New Reagent',
          'category': '기타',
          'storage_temp': 'RT',
          'body_markdown': _reagentTemplate(),
        };
      case 'record':
        return {
          'title': 'New Experiment Record',
          'status': '계획',
          'experiment_type': '기타',
          'method_markdown': _recordTemplate(),
        };
      case 'sop':
        return {'title': 'New SOP', 'version': 'v1.0', 'domain': '공용', 'body_markdown': _sopTemplate()};
      case 'template':
        return {'title': 'New Template', 'experiment_type': '공용', 'body_markdown': _templateTemplate()};
      default:
        return {'title': 'New Item'};
    }
  }

  String _equipmentTemplate() => '''**✅ 한 줄 요약(용도)**\n- \n\n**🧪 사용 전 체크리스트**\n- [ ] \n\n**🧭 기본 사용법**\n1. \n\n**⚠️ 주의사항**\n- \n\n**🧼 사용 후 정리**\n- \n''';

  String _facilityTemplate() => '''**📌 운영 규칙(핵심 5줄)**\n1. \n2. \n3. \n4. \n5. \n\n**🚨 사고/오염 대응(요약)**\n- 1차 조치: \n- 보고/연락: \n''';

  String _reagentTemplate() => '''**✅ 용도**\n- \n\n**🧊 보관/취급**\n- \n\n**⚠️ 안전(요약)**\n- PPE: \n\n**🧭 사용법**\n- \n\n**❗ 주의사항**\n- \n''';

  String _recordTemplate() => _RecordWizardDialog.defaultScaffold();

  String _sopTemplate() => '''# SOP\n\n## 목적\n- \n\n## 절차\n1. \n\n## 주의사항\n- \n''';

  String _templateTemplate() => '''# 템플릿\n\n## 섹션\n- \n''';
}

class _DetailEditor extends StatefulWidget {
  const _DetailEditor({
    required this.api,
    required this.type,
    required this.item,
    required this.onChanged,
    required this.onDeleted,
  });

  final EntitiesApi api;
  final String type;
  final Map<String, dynamic> item;
  final void Function(Map<String, dynamic>) onChanged;
  final VoidCallback onDeleted;

  @override
  State<_DetailEditor> createState() => _DetailEditorState();
}

class _DetailEditorState extends State<_DetailEditor> {
  late Map<String, dynamic> draft;
  bool saving = false;
  String? error;

  // record links
  List<dynamic> _allEquipment = [];
  List<dynamic> _allReagents = [];
  Set<int> _eqIds = {};
  Set<int> _reagentIds = {};
  bool _linksLoading = false;

  // attachments
  List<dynamic> _attachments = [];
  bool _attLoading = false;

  @override
  void initState() {
    super.initState();
    draft = Map<String, dynamic>.from(widget.item);
    _loadLinksIfRecord();
    _loadAttachments();
  }

  @override
  void didUpdateWidget(covariant _DetailEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['id'] != widget.item['id']) {
      draft = Map<String, dynamic>.from(widget.item);
      _loadLinksIfRecord();
      _loadAttachments();
    }
  }

  Future<void> _loadLinksIfRecord() async {
    if (widget.type != 'record') return;
    final recordId = (draft['id'] as int);

    setState(() => _linksLoading = true);
    try {
      _allEquipment = await widget.api.listEquipment();
      _allReagents = await widget.api.listReagents();

      final eq = await widget.api.getRecordEquipmentIds(recordId);
      final rg = await widget.api.getRecordReagentIds(recordId);

      _eqIds = ((eq['ids'] as List<dynamic>? ?? const [])).map((e) => e as int).toSet();
      _reagentIds = ((rg['ids'] as List<dynamic>? ?? const [])).map((e) => e as int).toSet();
    } catch (_) {
      // MVP: ignore
    } finally {
      if (mounted) setState(() => _linksLoading = false);
    }
  }

  String? _labelById(List<dynamic> items, int id) {
    for (final it in items) {
      final m = it as Map<String, dynamic>;
      if (m['id'] == id) return (m['name'] ?? m['title'] ?? '').toString();
    }
    return null;
  }

  Future<void> _loadAttachments() async {
    final id = draft['id'];
    if (id == null) return;
    setState(() => _attLoading = true);
    try {
      _attachments = await widget.api.listAttachments(widget.type, id as int);
    } catch (_) {
      // ignore in MVP
      _attachments = [];
    } finally {
      if (mounted) setState(() => _attLoading = false);
    }
  }

  Future<void> _pickAndUploadAttachment() async {
    final id = draft['id'];
    if (id == null) return;

    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.isEmpty) return;

    final f = picked.files.first;
    final bytes = f.bytes;
    if (bytes == null) {
      setState(() => error = '파일 데이터를 읽을 수 없습니다. (withData:true 필요)');
      return;
    }

    setState(() => _attLoading = true);
    try {
      await widget.api.uploadAttachment(
        widget.type,
        id as int,
        filename: f.name,
        bytes: bytes,
        note: '',
      );
      await _loadAttachments();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => _attLoading = false);
    }
  }

  Future<void> _openAttachment(dynamic att) async {
    try {
      final m = att as Map<String, dynamic>;
      final rel = (m['url'] ?? '').toString();
      if (rel.isEmpty) return;
      final uri = Uri.parse('${widget.api.client.baseUrl}$rel');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final titleKey = draft.containsKey('name') ? 'name' : 'title';
    final bodyKey = _bodyKeyFor(widget.type);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: draft[titleKey]?.toString() ?? '')
                    ..selection = TextSelection.collapsed(offset: (draft[titleKey]?.toString() ?? '').length),
                  decoration: const InputDecoration(labelText: '제목'),
                  onChanged: (v) => draft[titleKey] = v,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          final updated = await widget.api.update(widget.type, draft['id'] as int, draft);
                          widget.onChanged(updated);
                          setState(() => draft = Map<String, dynamic>.from(updated));
                          await _loadLinksIfRecord();
                        } catch (e) {
                          setState(() => error = e.toString());
                        } finally {
                          setState(() => saving = false);
                        }
                      },
                icon: const Icon(Icons.save),
                label: const Text('저장'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        await widget.api.remove(widget.type, draft['id'] as int);
                        widget.onDeleted();
                      },
                icon: const Icon(Icons.delete),
                label: const Text('삭제'),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 12),

          // Record links UI
          if (widget.type == 'record') ...[
            Row(
              children: [
                Text('연결된 장비/시약', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 12),
                if (_linksLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _linksLoading
                      ? null
                      : () async {
                          final out = await showDialog<List<dynamic>>(
                            context: context,
                            builder: (_) => _MultiSelectDialog(
                              title: '장비 선택',
                              items: _allEquipment,
                              selectedIds: _eqIds,
                            ),
                          );
                          if (out == null) return;
                          final ids = out.map((e) => e as int).toList();
                          await widget.api.setRecordEquipmentIds(draft['id'] as int, ids);
                          await _loadLinksIfRecord();
                        },
                  child: Text('장비 편집 (${_eqIds.length})'),
                ),
                FilledButton.tonal(
                  onPressed: _linksLoading
                      ? null
                      : () async {
                          final out = await showDialog<List<dynamic>>(
                            context: context,
                            builder: (_) => _MultiSelectDialog(
                              title: '시약 선택',
                              items: _allReagents,
                              selectedIds: _reagentIds,
                            ),
                          );
                          if (out == null) return;
                          final ids = out.map((e) => e as int).toList();
                          await widget.api.setRecordReagentIds(draft['id'] as int, ids);
                          await _loadLinksIfRecord();
                        },
                  child: Text('시약 편집 (${_reagentIds.length})'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in _eqIds) Chip(label: Text(_labelById(_allEquipment, id) ?? 'Equipment#$id')),
                for (final id in _reagentIds) Chip(label: Text(_labelById(_allReagents, id) ?? 'Reagent#$id')),
              ],
            ),
            Row(
              children: [
                Text('첨부파일', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 12),
                if (_attLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: _attLoading ? null : _pickAndUploadAttachment,
                  child: Text('파일 업로드 (${_attachments.length})'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_attachments.isEmpty)
              const Text('첨부파일이 없습니다. (Upload 버튼으로 추가)'),
            if (_attachments.isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView.separated(
                  itemCount: _attachments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = _attachments[i] as Map<String, dynamic>;
                    final name = (m['filename'] ?? '').toString();
                    final note = (m['note'] ?? '').toString();
                    return ListTile(
                      dense: true,
                      title: Text(name.isEmpty ? '(no name)' : name),
                      subtitle: note.isEmpty ? null : Text(note),
                      trailing: TextButton(
                        onPressed: () => _openAttachment(m),
                        child: const Text('열기'),
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 24),

          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _KeyValueForm(
                    data: draft,
                    excludeKeys: {'id', 'created_at', 'updated_at', bodyKey},
                    onChanged: (k, v) => setState(() => draft[k] = v),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('본문(Markdown)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: (draft[bodyKey] ?? '').toString())
                            ..selection = TextSelection.collapsed(offset: (draft[bodyKey] ?? '').toString().length),
                          onChanged: (v) => draft[bodyKey] = v,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('미리보기', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor)),
                          child: Markdown(data: (draft[bodyKey] ?? '').toString()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _bodyKeyFor(String type) {
    switch (type) {
      case 'record':
        return 'method_markdown';
      case 'facility':
        return 'rules_summary';
      case 'equipment':
        return 'body_markdown';
      case 'reagent':
        return 'body_markdown';
      case 'sop':
        return 'body_markdown';
      case 'template':
        return 'body_markdown';
      default:
        return 'body_markdown';
    }
  }
}

class _KeyValueForm extends StatelessWidget {
  const _KeyValueForm({required this.data, required this.excludeKeys, required this.onChanged});
  final Map<String, dynamic> data;
  final Set<String> excludeKeys;
  final void Function(String key, dynamic value) onChanged;

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.where((k) => !excludeKeys.contains(k)).toList()..sort();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (_, idx) {
        final k = keys[idx];
        final v = data[k];
        final isBool = v is bool;
        final label = k;
        if (isBool) {
          return SwitchListTile(
            title: Text(label),
            value: v as bool,
            onChanged: (nv) => onChanged(k, nv),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: TextEditingController(text: v?.toString() ?? '')
              ..selection = TextSelection.collapsed(offset: (v?.toString() ?? '').length),
            decoration: InputDecoration(labelText: label),
            onChanged: (nv) => onChanged(k, nv),
          ),
        );
      },
    );
  }
}

class _IndexPage extends StatefulWidget {
  const _IndexPage({required this.api});
  final EntitiesApi api;

  @override
  State<_IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<_IndexPage> {
  final _q = TextEditingController();
  bool loading = false;
  String? error;
  Map<String, dynamic>? results;

  Future<void> _search() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      results = await widget.api.search(_q.text.trim());
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('통합 검색', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: '검색어 (이름/태그/자산번호/Cat#/목적...)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: loading ? null : _search, child: const Text('검색')),
            ],
          ),
          if (loading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          if (results != null) Expanded(child: _Results(results: results!)),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.results});
  final Map<String, dynamic> results;

  @override
  Widget build(BuildContext context) {
    Widget section(String title, List<dynamic> items) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$title (${items.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final it in items.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• ${(it['name'] ?? it['title'] ?? '').toString()}  ${(it['tags'] ?? '').toString()}'),
              ),
          ]),
        ),
      );
    }

    return ListView(
      children: [
        section('장비', (results['equipment'] as List<dynamic>? ?? const [])),
        section('시설', (results['facilities'] as List<dynamic>? ?? const [])),
        section('시약', (results['reagents'] as List<dynamic>? ?? const [])),
        section('실험기록', (results['records'] as List<dynamic>? ?? const [])),
      ],
    );
  }
}

// ------------------------------
// Multi select dialog (Equipment/Reagent linking)
// ------------------------------
class _MultiSelectDialog extends StatefulWidget {
  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.selectedIds,
  });

  final String title;
  final List<dynamic> items; // Map with id + name/title + tags
  final Set<int> selectedIds;

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late Set<int> ids;
  String q = '';

  @override
  void initState() {
    super.initState();
    ids = Set<int>.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = q.isEmpty
        ? widget.items
        : widget.items.where((it) {
            final m = it as Map<String, dynamic>;
            final label = (m['name'] ?? m['title'] ?? '').toString().toLowerCase();
            final tags = (m['tags'] ?? '').toString().toLowerCase();
            return label.contains(q.toLowerCase()) || tags.contains(q.toLowerCase());
          }).toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        height: 520,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '검색 (이름/태그)'),
              onChanged: (v) => setState(() => q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, idx) {
                  final m = filtered[idx] as Map<String, dynamic>;
                  final id = m['id'] as int;
                  final label = (m['name'] ?? m['title'] ?? '').toString();
                  return CheckboxListTile(
                    value: ids.contains(id),
                    title: Text(label),
                    subtitle: (m['tags'] ?? '').toString().isEmpty ? null : Text((m['tags'] ?? '').toString()),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) ids.add(id);
                        else ids.remove(id);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('취소')),
        FilledButton(onPressed: () => Navigator.pop(context, ids.toList()), child: const Text('저장')),
      ],
    );
  }
}

// ------------------------------
// Template-based record wizard
// ------------------------------
class _RecordWizardDialog extends StatefulWidget {
  const _RecordWizardDialog({required this.api});

  final EntitiesApi api;

  static String defaultScaffold({String? templateBody}) {
    final tpl = (templateBody ?? '').trim();
    final tplSection = tpl.isEmpty
        ? ''
        : '\n\n## 방법 (Template)\n$tpl\n';

    return '''# 실험기록

## 목적
- 

## 샘플/조건
- 샘플:
- 조건/처리:

## 방법
- 설계:
- 파라미터:

$tplSection
## 결과
- 

## 결론
- 

## 이슈/편차
- 

## 후속실험 추천
1. 
''';
  }

  @override
  State<_RecordWizardDialog> createState() => _RecordWizardDialogState();
}

class _RecordWizardDialogState extends State<_RecordWizardDialog> {
  final _title = TextEditingController(text: 'New Experiment Record');
  final _type = TextEditingController(text: '기타');
  final _date = TextEditingController(text: _today());
  final _performer = TextEditingController(text: '');
  final _project = TextEditingController(text: '');
  String _status = '계획';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _templates = [];
  Map<String, dynamic>? _selectedTemplate; // may be null

  static String _today() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.api.listTemplates();
      _templates = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('템플릿 기반 실험기록 생성'),
      content: SizedBox(
        width: 720,
        height: 560,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: '실험 제목'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _type,
                          decoration: const InputDecoration(labelText: '실험 유형 (예: qPCR, 세포배양)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: TextField(
                          controller: _date,
                          decoration: const InputDecoration(labelText: '날짜 (YYYY-MM-DD)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _performer,
                          decoration: const InputDecoration(labelText: '수행자'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _project,
                          decoration: const InputDecoration(labelText: '프로젝트'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('상태:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _status,
                        items: const [
                          DropdownMenuItem(value: '계획', child: Text('계획')),
                          DropdownMenuItem(value: '진행', child: Text('진행')),
                          DropdownMenuItem(value: '완료', child: Text('완료')),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? '계획'),
                      ),
                      const Spacer(),
                      const Text('템플릿:'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<Map<String, dynamic>?>(
                          isExpanded: true,
                          value: _selectedTemplate,
                          hint: const Text('템플릿 없음(기본 스캐폴드만)'),
                          items: [
                            const DropdownMenuItem<Map<String, dynamic>?>(
                              value: null,
                              child: Text('템플릿 없음'),
                            ),
                            ..._templates.map((t) {
                              final title = (t['title'] ?? '').toString();
                              final expType = (t['experiment_type'] ?? '').toString();
                              return DropdownMenuItem<Map<String, dynamic>?>(
                                value: t,
                                child: Text(expType.isEmpty ? title : '$title  [$expType]'),
                              );
                            }),
                          ],
                          onChanged: (v) => setState(() => _selectedTemplate = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('미리보기(기본 스캐폴드 + 템플릿 본문)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor)),
                      child: Markdown(
                        data: _RecordWizardDialog.defaultScaffold(
                          templateBody: (_selectedTemplate?['body_markdown'] ?? '').toString(),
                        ),
                      ),
                    ),
                  )
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('취소')),
        FilledButton(
          onPressed: _loading
              ? null
              : () {
                  final tplId = _selectedTemplate?['id'] as int?;
                  final tplBody = (_selectedTemplate?['body_markdown'] ?? '').toString();

                  final body = <String, dynamic>{
                    'title': _title.text.trim().isEmpty ? 'New Experiment Record' : _title.text.trim(),
                    'experiment_type': _type.text.trim().isEmpty ? '기타' : _type.text.trim(),
                    'date': _date.text.trim(),
                    'performer': _performer.text.trim(),
                    'project': _project.text.trim(),
                    'status': _status,
                    'template_id': tplId,
                    'method_markdown': _RecordWizardDialog.defaultScaffold(templateBody: tplBody),
                  };
                  Navigator.pop(context, body);
                },
          child: const Text('생성'),
        ),
      ],
    );
  }
}
