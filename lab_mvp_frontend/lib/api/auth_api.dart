import 'api_client.dart';

class AuthApi {
  AuthApi(this.client);
  final ApiClient client;

  Future<String> login(String email, String password) async {
    final out = await client.postJson('/auth/login', {'email': email, 'password': password}, auth: false);
    return out['access_token'] as String;
  }

  Future<String> register(String email, String password, {String? name}) async {
    final out = await client.postJson('/auth/register', {'email': email, 'password': password, 'name': name}, auth: false);
    return out['access_token'] as String;
  }
}
