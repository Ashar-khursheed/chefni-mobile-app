import '../network/api_client.dart';

class HaccpLog {
  const HaccpLog({
    required this.id,
    required this.type,
    required this.label,
    required this.status,
    this.storeId,
    this.value,
    this.loggedBy,
    this.notes,
    this.createdAt,
  });

  final int id;
  final String type; // temperature | hygiene
  final String label;
  final String status; // pass | warning | fail
  final int? storeId;
  final String? value;
  final String? loggedBy;
  final String? notes;
  final DateTime? createdAt;

  factory HaccpLog.fromJson(Map<String, dynamic> json) => HaccpLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        type: json['type'] as String? ?? 'temperature',
        label: json['label'] as String? ?? '',
        status: json['status'] as String? ?? 'pass',
        storeId: (json['store_id'] as num?)?.toInt(),
        value: json['value'] as String?,
        loggedBy: json['logged_by'] as String?,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}

class HaccpRepository {
  HaccpRepository(this._api);

  final ApiClient _api;

  Future<({List<HaccpLog> logs, int failCount})> fetchAll({int? storeId}) async {
    final json = await _api.get('/haccp-logs', query: {
      if (storeId != null) 'store_id': '$storeId',
    });
    final logs = (json['data'] as List)
        .map((e) => HaccpLog.fromJson(e as Map<String, dynamic>))
        .toList();
    return (logs: logs, failCount: (json['fail_count'] as num?)?.toInt() ?? 0);
  }

  Future<HaccpLog> log({
    required String type,
    required String label,
    required String status,
    String? value,
    String? loggedBy,
    String? notes,
    int? storeId,
  }) async {
    final json = await _api.post('/haccp-logs', body: {
      'type': type,
      'label': label,
      'status': status,
      if (value != null && value.isNotEmpty) 'value': value,
      if (loggedBy != null && loggedBy.isNotEmpty) 'logged_by': loggedBy,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (storeId != null) 'store_id': storeId,
    });
    return HaccpLog.fromJson(json['data'] as Map<String, dynamic>);
  }
}
