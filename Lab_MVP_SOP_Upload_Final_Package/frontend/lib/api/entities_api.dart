import 'api_client.dart';

enum EntityKind {
  equipment('equipment', '장비'),
  facilities('facilities', '시설'),
  reagents('reagents', '시약'),
  records('records', '실험기록'),
  sops('sops', 'SOP'),
  templates('templates', '템플릿');

  const EntityKind(this.path, this.label);
  final String path;
  final String label;
}

class EntitiesApi {
  EntitiesApi(this.client);
  final ApiClient client;

  // -------- Auth --------
  Future<String> login({required String email, required String password}) async {
    // Expecting: {"access_token": "...", "token_type": "bearer"}
    final res = await client.postJson('/auth/login', {'email': email, 'password': password});
    final token = (res['access_token'] ?? res['token'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException(500, 'Login response has no token', body: res);
    }
    return token;
  }

  Future<void> register({required String email, required String password, String? name}) async {
    await client.postJson('/auth/register', {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
    });
  }

  // -------- Generic entity CRUD --------
  Future<List<Map<String, dynamic>>> list(EntityKind kind) async {
    final rows = await client.getList('/${kind.path}');
    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> create(EntityKind kind, Map<String, dynamic> body) async {
    return client.postJson('/${kind.path}', body);
  }

  Future<Map<String, dynamic>> update(EntityKind kind, int id, Map<String, dynamic> body) async {
    return client.putJson('/${kind.path}/$id', body);
  }

  Future<void> remove(EntityKind kind, int id) async {
    await client.delete('/${kind.path}/$id');
  }

  // -------- Records links/attachments (optional endpoints) --------
  Future<List<Map<String, dynamic>>> listRecordLinks(int recordId) async {
    final rows = await client.getList('/records/$recordId/links');
    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listRecordAttachments(int recordId) async {
    final rows = await client.getList('/records/$recordId/attachments');
    return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}


  // -------- SOP upload/download (custom endpoints) --------
  Future<Map<String, dynamic>> uploadSop({
    required String title,
    required String category,
    required String version,
    required List<int> fileBytes,
    required String filename,
    String contentType = 'application/pdf',
    String? code,
  }) async {
    final res = await client.postMultipart(
      '/sops/upload',
      fields: {
        'title': title,
        'category': category,
        'version': version,
        if (code != null) 'code': code,
      },
      fileField: 'file',
      fileBytes: fileBytes,
      filename: filename,
      contentType: contentType,
    );
    return res;
  }

  String sopDownloadUrl(int id) {
    return '${client.baseUrl}/sops/$id/download';
  }
