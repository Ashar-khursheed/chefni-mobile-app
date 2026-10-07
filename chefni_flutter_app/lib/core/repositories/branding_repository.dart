import '../network/api_client.dart';

class Branding {
  const Branding({
    required this.whiteLabelEnabled,
    this.brandName,
    this.brandLogoUrl,
  });

  final bool whiteLabelEnabled;
  final String? brandName;
  final String? brandLogoUrl;

  factory Branding.fromJson(Map<String, dynamic> json) => Branding(
        whiteLabelEnabled: json['white_label_enabled'] as bool? ?? false,
        brandName: json['brand_name'] as String?,
        brandLogoUrl: json['brand_logo_url'] as String?,
      );
}

class BrandingRepository {
  BrandingRepository(this._api);

  final ApiClient _api;

  Future<Branding> fetch() async {
    final json = await _api.get('/branding');
    return Branding.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Branding> update({
    required bool whiteLabelEnabled,
    String? brandName,
    String? brandLogoUrl,
  }) async {
    final json = await _api.patch('/branding', body: {
      'white_label_enabled': whiteLabelEnabled,
      if (brandName != null) 'brand_name': brandName,
      if (brandLogoUrl != null) 'brand_logo_url': brandLogoUrl,
    });
    return Branding.fromJson(json['data'] as Map<String, dynamic>);
  }
}
