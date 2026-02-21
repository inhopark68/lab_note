import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'session.dart';

class ApiClient {
  ApiClient({required this.baseUrl});
  final String baseUrl;

  Map<String, String> _headers({bool auth = true}) {
    final h = {'Content-Type': 'application/json'};
    if (auth && Session.instance.hasToken) {
      h['Authorization'] = 'Bearer ${Session.instance.token}';
    }
    return h;
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(Uri.parse('$baseUrl$path'), headers: _headers(auth: auth), body: jsonEncode(body));
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getList(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
    _throwIfBad(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final res = await http.put(Uri.parse('$baseUrl$path'), headers: _headers(), body: jsonEncode(body));
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers());
    _throwIfBad(res);
  }


  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    String fieldName = 'file',
    Map<String, String> fields = const {},
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = http.MultipartRequest('POST', uri);

    // Authorization header only (do not force JSON content-type)
    if (auth && Session.instance.hasToken) {
      req.headers['Authorization'] = 'Bearer ${Session.instance.token}';
    }
    req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void _throwIfBad(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('API ${res.statusCode}: ${res.body}');
  }
}
