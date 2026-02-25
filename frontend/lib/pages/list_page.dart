import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../api/entities_api.dart';

enum ListPageMode { normal, indexed }

class ListPage extends StatefulWidget {
  const ListPage({super.key, required this.kind, required this.api, this.mode = ListPageMode.normal});

  final EntityKind kind;
  final EntitiesApi api;
  final ListPageMode mode;

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic>? _selected;

  final _search = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.api.list(widget.kind);
      setState(() {
        _rows = rows;
        if (_selected != null) {
          final id = _selected!['id'];
          _selected = rows.where((e) => e['id'] == id).cast<Map<String, dynamic>?>().firstWhere((e) => e != null, orElse: () => null);
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    bool hit(Map<String, dynamic> r) {
      final values = [
        (r['name'] ?? '').toString(),
        (r['title'] ?? '').toString(),
        (r['experiment_type'] ?? '').toString(),
        (r['tags'] ?? '').toString(),
        (r['status'] ?? '').toString(),
      ].join(' ').toLowerCase();
      return values.contains(q);
    }

    return _rows.where(hit).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    if (widget.mode == ListPageMode.indexed) {
      final recent = [..._rows]..sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      final top = recent.take(10).toList();
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 실험기록', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: top.length,
                itemBuilder: (_, i) {
                  final r = top[i];
                  final title = (r['title'] ?? r['name'] ?? 'Untitled').toString();
                  final date = (r['date'] ?? '').toString();
                  final status = (r['status'] ?? '').toString();
                  return Card(
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text([date, status].where((e) => e.isNotEmpty).join(' · ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => setState(() => _selected = r),
                    ),
                  );
                },
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 8),
              Expanded(child: _Detail(kind: widget.kind, api: widget.api, item: _selected!, onSaved: _onSaved, onDeleted: _onDeleted)),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 380,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '검색', isDense: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _createNew(context),
                      icon: const Icon(Icons.add),
                      label: const Text('추가'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final r = _filtered[i];
                    final title = (r['name'] ?? r['title'] ?? 'Untitled').toString();
                    final sub = [
                      (r['experiment_type'] ?? '').toString(),
                      (r['date'] ?? '').toString(),
                      (r['status'] ?? '').toString(),
                    ].where((e) => e.isNotEmpty).join(' · ');
                    return ListTile(
                      selected: _selected?['id'] == r['id'],
                      title: Text(title),
                      subtitle: sub.isEmpty ? null : Text(sub),
                      onTap: () => setState(() => _selected = r),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selected == null
              ? Center(child: Text('${widget.kind.label}를 선택하거나 추가하세요', style: Theme.of(context).textTheme.titleMedium))
              : _Detail(kind: widget.kind, api: widget.api, item: _selected!, onSaved: _onSaved, onDeleted: _onDeleted),
        ),
      ],
    );
  }

  Future<void> _createNew(BuildContext context) async {
    final created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CreateDialog(kind: widget.kind),
    );
    if (created == null) return;
    try {
      final saved = await widget.api.create(widget.kind, created);
      await _load();
      setState(() => _selected = saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('생성 실패: $e')));
    }
  }

  Future<void> _onSaved(Map<String, dynamic> saved) async {
    await _load();
    setState(() => _selected = saved);
  }

  Future<void> _onDeleted() async {
    await _load();
    setState(() => _selected = null);
  }
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({required this.kind});
  final EntityKind kind;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _title = TextEditingController(text: '');
  final _type = TextEditingController(text: '');
  final _date = TextEditingController(text: '');
  final _name = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.kind.label} 추가'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.kind == EntityKind.records || widget.kind == EntityKind.templates)
              TextField(controller: _title, decoration: const InputDecoration(labelText: '제목')),
            if (widget.kind == EntityKind.records || widget.kind == EntityKind.templates)
              TextField(controller: _type, decoration: const InputDecoration(labelText: '실험 유형')),
            if (widget.kind == EntityKind.records)
              TextField(controller: _date, decoration: const InputDecoration(labelText: '날짜 (YYYY-MM-DD)')),
            if (widget.kind == EntityKind.equipment ||
                widget.kind == EntityKind.facilities ||
                widget.kind == EntityKind.reagents ||
                widget.kind == EntityKind.sops)
              TextField(controller: _name, decoration: const InputDecoration(labelText: '이름')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final body = <String, dynamic>{};
            switch (widget.kind) {
              case EntityKind.records:
                body['title'] = _title.text.trim().isEmpty ? 'New Record' : _title.text.trim();
                body['experiment_type'] = _type.text.trim();
                if (_date.text.trim().isNotEmpty) body['date'] = _date.text.trim();
                body['status'] = '계획';
                body['method_markdown'] = _defaultScaffold();
                break;
              case EntityKind.templates:
                body['title'] = _title.text.trim().isEmpty ? 'New Template' : _title.text.trim();
                body['experiment_type'] = _type.text.trim();
                body['body_markdown'] = _defaultScaffold();
                break;
              default:
                body['name'] = _name.text.trim().isEmpty ? 'New Item' : _name.text.trim();
                break;
            }
            Navigator.pop(context, body);
          },
          child: const Text('생성'),
        ),
      ],
    );
  }

  String _defaultScaffold() => """# 실험기록

## 목적
-

## 샘플/조건
- 샘플:
- 조건/처리:

## 방법
- 설계:
- 파라미터:

## 결과
-

## 결론
-

## 이슈/편차
-

## 후속실험 추천
1.
""";
}

class _Detail extends StatefulWidget {
  const _Detail({required this.kind, required this.api, required this.item, required this.onSaved, required this.onDeleted});
  final EntityKind kind;
  final EntitiesApi api;
  final Map<String, dynamic> item;
  final Future<void> Function(Map<String, dynamic>) onSaved;
  final Future<void> Function() onDeleted;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  bool _saving = false;
  String? _error;

  late Map<String, dynamic> draft = Map<String, dynamic>.from(widget.item);

  late final _name = TextEditingController(text: (draft['name'] ?? '').toString());
  late final _title = TextEditingController(text: (draft['title'] ?? '').toString());
  late final _type = TextEditingController(text: (draft['experiment_type'] ?? '').toString());
  late final _date = TextEditingController(text: (draft['date'] ?? '').toString());
  late final _status = ValueNotifier<String>((draft['status'] ?? '계획').toString());
  late final _body = TextEditingController(text: (draft['body_markdown'] ?? draft['method_markdown'] ?? '').toString());

  @override
  void didUpdateWidget(covariant _Detail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item['id'] != widget.item['id']) {
      draft = Map<String, dynamic>.from(widget.item);
      _name.text = (draft['name'] ?? '').toString();
      _title.text = (draft['title'] ?? '').toString();
      _type.text = (draft['experiment_type'] ?? '').toString();
      _date.text = (draft['date'] ?? '').toString();
      _status.value = (draft['status'] ?? '계획').toString();
      _body.text = (draft['body_markdown'] ?? draft['method_markdown'] ?? '').toString();
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = (draft['id'] as num).toInt();
      final body = _buildBody();
      final saved = await widget.api.update(widget.kind, id, body);
      await widget.onSaved(saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 완료')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('정말 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = (draft['id'] as num).toInt();
      await widget.api.remove(widget.kind, id);
      await widget.onDeleted();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제 완료')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildBody() {
    switch (widget.kind) {
      case EntityKind.records:
        return {
          'title': _title.text.trim(),
          'experiment_type': _type.text.trim(),
          'date': _date.text.trim(),
          'status': _status.value,
          'method_markdown': _body.text,
        };
      case EntityKind.templates:
        return {
          'title': _title.text.trim(),
          'experiment_type': _type.text.trim(),
          'body_markdown': _body.text,
        };
      default:
        return {'name': _name.text.trim()};
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.item['name'] ?? widget.item['title'] ?? 'Detail').toString();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _saving ? null : _delete, icon: const Icon(Icons.delete_outline), label: const Text('삭제')),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: const Text('저장')),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          Expanded(child: _buildEditor(context)),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    switch (widget.kind) {
      case EntityKind.records:
        return Row(
          children: [
            SizedBox(
              width: 420,
              child: ListView(
                children: [
                  TextField(controller: _title, decoration: const InputDecoration(labelText: '실험 제목')),
                  const SizedBox(height: 8),
                  TextField(controller: _type, decoration: const InputDecoration(labelText: '실험 유형')),
                  const SizedBox(height: 8),
                  TextField(controller: _date, decoration: const InputDecoration(labelText: '날짜 (YYYY-MM-DD)')),
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: _status,
                    builder: (_, v, __) => DropdownButtonFormField<String>(
                      value: v,
                      decoration: const InputDecoration(labelText: '상태'),
                      items: const [
                        DropdownMenuItem(value: '계획', child: Text('계획')),
                        DropdownMenuItem(value: '진행', child: Text('진행')),
                        DropdownMenuItem(value: '완료', child: Text('완료')),
                      ],
                      onChanged: (nv) => _status.value = nv ?? '계획',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    maxLines: 18,
                    decoration: const InputDecoration(labelText: '본문(Markdown)'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Markdown(data: _body.text.isEmpty ? '(비어있음)' : _body.text),
                ),
              ),
            )
          ],
        );
      case EntityKind.templates:
        return Row(
          children: [
            SizedBox(
              width: 420,
              child: ListView(
                children: [
                  TextField(controller: _title, decoration: const InputDecoration(labelText: '템플릿 제목')),
                  const SizedBox(height: 8),
                  TextField(controller: _type, decoration: const InputDecoration(labelText: '실험 유형')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    maxLines: 22,
                    decoration: const InputDecoration(labelText: '템플릿 본문(Markdown)'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Markdown(data: _body.text.isEmpty ? '(비어있음)' : _body.text),
                ),
              ),
            )
          ],
        );
      default:
        return ListView(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: '이름')),
            const SizedBox(height: 8),
            const Text('※ 이 타입은 최소 필드(name)만 편집하도록 구성되어 있습니다.'),
          ],
        );
    }
  }
}
