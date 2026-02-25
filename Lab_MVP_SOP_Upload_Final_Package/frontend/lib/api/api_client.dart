import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'session.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  final Map<String, dynamic>? body;
  ApiException(this.status, this.message, {this.body});

  @override
  String toString() => 'ApiException($status): $message';
}

class ApiClient {
  ApiClient({required this.baseUrl});

  /// Example: http://127.0.0.1:8000/api
  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool jsonBody = true}) {
    final h = <String, String>{};
    if (jsonBody) h['Content-Type'] = 'application/json; charset=utf-8';
    h['Accept'] = 'application/json';
    final token = Session.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers(jsonBody: false));
    return _decode(res);
  }

  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers(jsonBody: false));
    final decoded = _decodeAny(res);
    if (decoded is List) return decoded;
    throw ApiException(res.statusCode, 'Expected JSON list', body: decoded is Map ? decoded.cast<String, dynamic>() : null);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await http.post(_uri(path), headers: _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final res = await http.put(_uri(path), headers: _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<void> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers(jsonBody: false));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final decoded = _tryDecode(res.bodyBytes);
    throw ApiException(res.statusCode, 'DELETE failed', body: decoded is Map ? decoded.cast<String, dynamic>() : null);
  }


  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required List<int> fileBytes,
    required String filename,
    required String contentType,
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    // auth header only (no json header)
    final h = _headers(jsonBody: false);
    if (h.containsKey('Authorization')) req.headers['Authorization'] = h['Authorization']!;
    req.headers['Accept'] = 'application/json';
    req.fields.addAll(fields);

    req.files.add(http.MultipartFile.fromBytes(
      fileField,
      fileBytes,
      filename: filename,
      contentType: http_parser.MediaType.parse(contentType),
    ));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final decoded = _decodeAny(res);
    if (decoded is Map) return decoded.cast<String, dynamic>();
    throw ApiException(res.statusCode, 'Expected JSON object', body: null);
  }

  dynamic _decodeAny(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final decoded = _tryDecode(res.bodyBytes);
      throw ApiException(res.statusCode, 'Request failed', body: decoded is Map ? decoded.cast<String, dynamic>() : null);
    }
    return _tryDecode(res.bodyBytes);
  }

  dynamic _tryDecode(List<int> bytes) {
    if (bytes.isEmpty) return {};
    final text = utf8.decode(bytes);
    try {
      return jsonDecode(text);
    } catch (_) {
      return {'raw': text};
    }
  }
}
