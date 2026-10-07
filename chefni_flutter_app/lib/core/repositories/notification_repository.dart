import '../network/api_client.dart';

enum NoticeSeverity { low, medium, high }

extension NoticeSeverityX on NoticeSeverity {
  static NoticeSeverity fromApi(String? value) {
    switch (value) {
      case 'high':
        return NoticeSeverity.high;
      case 'low':
        return NoticeSeverity.low;
      case 'medium':
      default:
        return NoticeSeverity.medium;
    }
  }
}

/// A notice derived from the account's live state — not a stored, dismissable
/// message. It reflects what is true right now, so it simply stops appearing
/// once the underlying condition clears (credits top up, trial renews, stock
/// is restocked).
class AppNotice {
  const AppNotice({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String type;
  final NoticeSeverity severity;
  final String title;
  final String body;
  final DateTime? createdAt;

  factory AppNotice.fromJson(Map<String, dynamic> json) => AppNotice(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        severity: NoticeSeverityX.fromApi(json['severity'] as String?),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotice>> fetchAll() async {
    final json = await _api.get('/notifications');
    return (json['data'] as List)
        .map((e) => AppNotice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
