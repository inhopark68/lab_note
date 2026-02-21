import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static final Session instance = Session._();
  Session._();

  static const _tokenKey = 'access_token';

  String? _token;
  String get token => _token ?? '';
  bool get hasToken => (_token ?? '').isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clear() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
