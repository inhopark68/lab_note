import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/entities_api.dart';
import '../api/session.dart';
import 'login_page.dart';
import 'list_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  static const _baseUrl = 'http://127.0.0.1:8000/api';
  late final EntitiesApi api = EntitiesApi(ApiClient(baseUrl: _baseUrl));

  int index = 0;
  final tabs = const [
    ('인덱스', Icons.home),
    ('장비', Icons.precision_manufacturing),
    ('시설', Icons.apartment),
    ('시약', Icons.science),
    ('실험기록', Icons.note_alt),
    ('SOP', Icons.rule),
    ('템플릿', Icons.dashboard_customize),
  ];

  @override
  Widget build(BuildContext context) {
    final (label, _) = tabs[index];
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await Session.instance.clear();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Lab MVP')),
            for (var i=0; i<tabs.length; i++)
              ListTile(
                leading: Icon(tabs[i].$2),
                title: Text(tabs[i].$1),
                selected: i == index,
                onTap: () { setState(() => index = i); Navigator.pop(context); },
              ),
          ],
        ),
      ),
      body: _buildBody(index),
    );
  }

  Widget _buildBody(int i) {
    switch (i) {
      case 0:
        return ListPage.index(api: api);
      case 1:
        return ListPage.equipment(api: api);
      case 2:
        return ListPage.facilities(api: api);
      case 3:
        return ListPage.reagents(api: api);
      case 4:
        return ListPage.records(api: api);
      case 5:
        return ListPage.sops(api: api);
      case 6:
        return ListPage.templates(api: api);
      default:
        return const SizedBox.shrink();
    }
  }
}
