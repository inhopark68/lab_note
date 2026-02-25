import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/entities_api.dart';
import 'list_page.dart';

/// App Shell:
/// - Wide(Web/Desktop): persistent left sidebar
/// - Narrow(Mobile): Drawer
/// - Connected to real project widgets (ListPage + EntitiesApi)
///
/// Menu order:
/// 인덱스 → SOP → 실험기록 → 시약 → 장비 → 시설 → 템플릿
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  static const double wideBreakpoint = 900; // px
  static const double sidebarWidth = 260; // px

  // 🔧 Backend base URL (adjust if needed)
  // Uvicorn: http://127.0.0.1:8000, API prefix: /api
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api';

  late final EntitiesApi _api = EntitiesApi(ApiClient(baseUrl: apiBaseUrl));

  _NavItem _selected = _NavItem.home;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= wideBreakpoint;

        final menu = _SideMenu(
          selected: _selected,
          onSelect: (item) {
            setState(() => _selected = item);
            if (!isWide) Navigator.of(context).pop(); // close Drawer
          },
        );

        final content = _buildBody(_selected);

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: sidebarWidth,
                  child: Material(
                    elevation: 2,
                    color: Colors.white,
                    child: SafeArea(child: menu),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_selected.label)),
          drawer: Drawer(child: SafeArea(child: menu)),
          body: content,
        );
      },
    );
  }

  Widget _buildBody(_NavItem item) {
    switch (item) {
      case _NavItem.home:
        return _HomeDashboard(
          onNavigate: (nav) => setState(() => _selected = nav),
        );

      case _NavItem.sop:
        return ListPage(kind: EntityKind.sops, api: _api);

      case _NavItem.experimentLog:
        return ListPage(kind: EntityKind.records, api: _api);

      case _NavItem.reagent:
        return ListPage(kind: EntityKind.reagents, api: _api);

      case _NavItem.equipment:
        return ListPage(kind: EntityKind.equipment, api: _api);

      case _NavItem.facility:
        return ListPage(kind: EntityKind.facilities, api: _api);

      case _NavItem.template:
        return ListPage(kind: EntityKind.templates, api: _api);
    }
  }
}

/// ✅ Requested order is defined by enum declaration order.
/// (Do NOT use name `index` — it conflicts with Enum.index)
enum _NavItem {
  home('인덱스', Icons.home_rounded),
  sop('SOP', Icons.checklist_rounded),
  experimentLog('실험기록', Icons.assignment_rounded),
  reagent('시약', Icons.biotech_rounded),
  equipment('장비', Icons.science_rounded),
  facility('시설', Icons.apartment_rounded),
  template('템플릿', Icons.grid_view_rounded);

  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({
    required this.selected,
    required this.onSelect,
  });

  final _NavItem selected;
  final ValueChanged<_NavItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Text(
            'Lab MVP',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ..._NavItem.values.map(
          (item) => _SideMenuTile(
            item: item,
            selected: item == selected,
            onTap: () => onSelect(item),
          ),
        ),
      ],
    );
  }
}

class _SideMenuTile extends StatelessWidget {
  const _SideMenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        item.icon,
        color: selected ? theme.colorScheme.primary : theme.iconTheme.color,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? theme.colorScheme.primary : null,
        ),
      ),
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}

/// 메인(인덱스) 화면: 빠른 이동 + 요약 카드 + 최근 항목(데이터 연결은 추후)
class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({required this.onNavigate});

  final ValueChanged<_NavItem> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Row(
                children: [
                  Text('인덱스', style: theme.textTheme.headlineSmall),
                  const Spacer(),
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '검색 (SOP, 실험기록, 시약...)',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (q) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('검색: $q (연결 예정)')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickAction(
                    icon: Icons.checklist_rounded,
                    title: 'SOP 보기',
                    subtitle: '표준절차서',
                    onTap: () => onNavigate(_NavItem.sop),
                  ),
                  _QuickAction(
                    icon: Icons.assignment_rounded,
                    title: '실험기록',
                    subtitle: '새 기록/조회',
                    onTap: () => onNavigate(_NavItem.experimentLog),
                  ),
                  _QuickAction(
                    icon: Icons.biotech_rounded,
                    title: '시약',
                    subtitle: '재고/관리',
                    onTap: () => onNavigate(_NavItem.reagent),
                  ),
                  _QuickAction(
                    icon: Icons.science_rounded,
                    title: '장비',
                    subtitle: '현황/점검',
                    onTap: () => onNavigate(_NavItem.equipment),
                  ),
                  _QuickAction(
                    icon: Icons.apartment_rounded,
                    title: '시설',
                    subtitle: '예약/관리',
                    onTap: () => onNavigate(_NavItem.facility),
                  ),
                  _QuickAction(
                    icon: Icons.grid_view_rounded,
                    title: '템플릿',
                    subtitle: '기록 템플릿',
                    onTap: () => onNavigate(_NavItem.template),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      title: '오늘의 실험기록',
                      value: '—',
                      hint: 'API 연결 예정',
                      icon: Icons.assignment_rounded,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: '점검 필요 장비',
                      value: '—',
                      hint: 'API 연결 예정',
                      icon: Icons.science_rounded,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: '재고 임박 시약',
                      value: '—',
                      hint: 'API 연결 예정',
                      icon: Icons.biotech_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('최근 활동', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          TextButton(
                            onPressed: () => onNavigate(_NavItem.experimentLog),
                            child: const Text('실험기록으로 이동'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _ActivityRow(
                        icon: Icons.info_outline_rounded,
                        title: '연결 복구',
                        subtitle: '각 메뉴가 ListPage(실제 API)로 연결되었습니다.',
                        time: '방금',
                      ),
                      const Divider(height: 18),
                      const _ActivityRow(
                        icon: Icons.check_circle_outline_rounded,
                        title: '다음 단계',
                        subtitle: '템플릿 화면을 커스텀으로 만들려면 TemplateScreenWithResizedPanels에 실제 위젯을 연결하세요.',
                        time: '—',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(radius: 18, child: Icon(icon, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(radius: 18, child: Icon(icon, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(value, style: theme.textTheme.headlineSmall),
                      const SizedBox(width: 10),
                      Text(hint, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(time, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
