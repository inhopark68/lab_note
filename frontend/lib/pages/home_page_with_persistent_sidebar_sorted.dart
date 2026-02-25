import 'package:flutter/material.dart';

/// HomePage with a persistent left sidebar on wide screens (Web/Desktop)
/// and a Drawer on narrow screens (Mobile).
///
/// ✅ Menu order (as requested):
/// 인덱스 → SOP → 실험기록 → 시약 → 장비 → 시설 → 템플릿
///
/// Usage:
///   - Put this file under: lib/pages/ (or wherever you keep pages)
///   - Set it as your home or route target:
///       MaterialApp(home: const HomePageWithPersistentSidebarSorted())
///
/// Customize:
///   - Adjust the `wideBreakpoint` and sidebar width
///   - Replace navigation logic inside `_navigate` with your router solution
class HomePageWithPersistentSidebarSorted extends StatelessWidget {
  const HomePageWithPersistentSidebarSorted({super.key});

  static const double wideBreakpoint = 900; // px
  static const double sidebarWidth = 260;   // px

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= wideBreakpoint;

        final sideMenu = _SideMenu(
          selected: _NavItem.index,
          onSelect: (item) => _navigate(context, item, isWide: isWide),
        );

        if (isWide) {
          // ✅ Persistent sidebar
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: sidebarWidth,
                  child: Material(
                    elevation: 2,
                    color: Colors.white,
                    child: SafeArea(child: sideMenu),
                  ),
                ),
                const VerticalDivider(width: 1),
                const Expanded(child: _MainContent()),
              ],
            ),
          );
        }

        // ✅ Drawer on narrow screens
        return Scaffold(
          appBar: AppBar(title: const Text('Lab MVP')),
          drawer: Drawer(child: SafeArea(child: sideMenu)),
          body: const _MainContent(),
        );
      },
    );
  }

  void _navigate(BuildContext context, _NavItem item, {required bool isWide}) {
    // Replace this with your preferred navigation:
    //   - Navigator.pushNamed(context, '/route')
    //   - go_router: context.go('/route')
    //   - auto_route: context.router.push(...)
    //
    // Example (named routes):
    // switch (item) {
    //   case _NavItem.index: Navigator.pushNamed(context, '/'); break;
    //   case _NavItem.sop: Navigator.pushNamed(context, '/sop'); break;
    //   case _NavItem.experimentLog: Navigator.pushNamed(context, '/records'); break;
    //   case _NavItem.reagent: Navigator.pushNamed(context, '/reagents'); break;
    //   case _NavItem.equipment: Navigator.pushNamed(context, '/equipment'); break;
    //   case _NavItem.facility: Navigator.pushNamed(context, '/facility'); break;
    //   case _NavItem.template: Navigator.pushNamed(context, '/templates'); break;
    // }

    // If not wide, close the drawer after selection
    if (!isWide) {
      Navigator.of(context).pop(); // closes Drawer
    }

    // Demo action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: ${item.label}')),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('메인 화면'),
    );
  }
}

/// ✅ Requested order is defined by enum declaration order.
enum _NavItem {
  index('인덱스', Icons.home_rounded),
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
        ..._NavItem.values.map((item) => _SideMenuTile(
              item: item,
              selected: item == selected,
              onTap: () => onSelect(item),
            )),
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
