import 'package:flutter/material.dart';
import 'pages/shell.dart';
import 'api/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.instance.load();
  runApp(const LabMvpApp());
}

class LabMvpApp extends StatelessWidget {
  const LabMvpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const Shell(),
    );
  }
}
