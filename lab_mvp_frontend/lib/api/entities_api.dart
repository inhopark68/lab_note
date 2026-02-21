import 'api_client.dart';
import 'dart:typed_data';

class EntitiesApi {
  EntitiesApi(this.client);
  final ApiClient client;

  Future<List<dynamic>> listFacilities() => client.getList('/facilities/');
  Future<List<dynamic>> listEquipment() => client.getList('/equipment/');
  Future<List<dynamic>> listReagents() => client.getList('/reagents/');
  Future<List<dynamic>> listRecords() => client.getList('/records/');
  Future<List<dynamic>> listSops() => client.getList('/sops/');
  Future<List<dynamic>> listTemplates() => client.getList('/templates/');

  Future<Map<String, dynamic>> create(String type, Map<String, dynamic> body) {
    switch (type) {
      case 'facility': return client.postJson('/facilities/', body);
      case 'equipment': return client.postJson('/equipment/', body);
      case 'reagent': return client.postJson('/reagents/', body);
      case 'record': return client.postJson('/records/', body);
      case 'sop': return client.postJson('/sops/', body);
      case 'template': return client.postJson('/templates/', body);
      default: throw Exception('Unknown type');
    }
  }

  Future<Map<String, dynamic>> update(String type, int id, Map<String, dynamic> body) {
    switch (type) {
      case 'facility': return client.putJson('/facilities/$id', body);
      case 'equipment': return client.putJson('/equipment/$id', body);
      case 'reagent': return client.putJson('/reagents/$id', body);
      case 'record': return client.putJson('/records/$id', body);
      case 'sop': return client.putJson('/sops/$id', body);
      case 'template': return client.putJson('/templates/$id', body);
      default: throw Exception('Unknown type');
    }
  }

  Future<void> remove(String type, int id) {
    switch (type) {
      case 'facility': return client.delete('/facilities/$id');
      case 'equipment': return client.delete('/equipment/$id');
      case 'reagent': return client.delete('/reagents/$id');
      case 'record': return client.delete('/records/$id');
      case 'sop': return client.delete('/sops/$id');
      case 'template': return client.delete('/templates/$id');
      default: throw Exception('Unknown type');
    }
  }

  Future<Map<String, dynamic>> search(String q, {String type = 'all'}) =>
      client.getJson('/search/?q=${Uri.encodeComponent(q)}&type=$type');

    // ----- Record <-> Equipment/Reagent links -----

  Future<Map<String, dynamic>> getRecordEquipmentIds(int recordId) =>
      client.getJson('/records/$recordId/equipment-ids');

  Future<Map<String, dynamic>> getRecordReagentIds(int recordId) =>
      client.getJson('/records/$recordId/reagent-ids');

  Future<Map<String, dynamic>> setRecordEquipmentIds(int recordId, List<int> ids) =>
      client.postJson('/records/$recordId/set-equipment', {'ids': ids});

  Future<Map<String, dynamic>> setRecordReagentIds(int recordId, List<int> ids) =>
      client.postJson('/records/$recordId/set-reagents', {'ids': ids});

  // ----- Attachments (/uploads) -----
  Future<List<dynamic>> listAttachments(String entityType, int entityId) =>
      client.getList('/uploads/$entityType/$entityId');

  Future<Map<String, dynamic>> uploadAttachment(
    String entityType,
    int entityId, {
    required String filename,
    required Uint8List bytes,
    String note = '',
  }) {
    final q = 'entity_type=$entityType&entity_id=$entityId&note=${Uri.encodeComponent(note)}';
    return client.postMultipart('/uploads/?$q', bytes: bytes, filename: filename);
  }
}
