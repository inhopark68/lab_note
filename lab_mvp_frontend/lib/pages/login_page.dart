import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/session.dart';
import 'shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  late final AuthApi auth = AuthApi(ApiClient(baseUrl: _baseUrl));
  static const _baseUrl = 'http://127.0.0.1:8000/api';

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = _isRegister
          ? await auth.register(_email.text.trim(), _pw.text, name: null)
          : await auth.login(_email.text.trim(), _pw.text);
      await Session.instance.setToken(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Lab MVP', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: _pw, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 12),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_isRegister ? 'Register' : 'Login'),
                ),
                TextButton(
                  onPressed: _loading ? null : () => setState(() => _isRegister = !_isRegister),
                  child: Text(_isRegister ? 'Already have an account? Login' : 'Need an account? Register'),
                ),
                const SizedBox(height: 4),
                const Text('Backend baseUrl is hardcoded: http://127.0.0.1:8000/api'),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
