import '../network/api_client.dart';

class LegalSection {
  const LegalSection({required this.heading, required this.content});

  final String heading;
  final String content;

  factory LegalSection.fromJson(Map<String, dynamic> json) => LegalSection(
        heading: json['heading'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );
}

/// A legal document as the server serves it: either a list of headed
/// sections (privacy policy) or a single block of text (terms).
class LegalDocument {
  const LegalDocument({
    required this.title,
    this.lastUpdated,
    this.sections = const [],
    this.content,
  });

  final String title;
  final String? lastUpdated;
  final List<LegalSection> sections;
  final String? content;

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
        title: json['title'] as String? ?? '',
        lastUpdated: json['last_updated'] as String?,
        sections: (json['sections'] as List?)
                ?.map((e) => LegalSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        content: json['content'] as String?,
      );
}

class LegalRepository {
  LegalRepository(this._api);

  final ApiClient _api;

  Future<LegalDocument> fetchPrivacyPolicy() async {
    final json = await _api.get('/legal/privacy-policy');
    return LegalDocument.fromJson(json);
  }

  Future<LegalDocument> fetchTerms() async {
    final json = await _api.get('/legal/terms');
    return LegalDocument.fromJson(json);
  }
}
