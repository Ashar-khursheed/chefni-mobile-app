import '../models/user_session.dart';
import '../network/api_client.dart';

class PlanTier {
  const PlanTier({
    required this.tier,
    required this.name,
    required this.monthly,
    required this.yearly,
    required this.features,
    this.badge = false,
  });

  final String tier;
  final String name;
  final String monthly;
  final String yearly;
  final List<String> features;
  final bool badge;

  factory PlanTier.fromJson(Map<String, dynamic> json) => PlanTier(
        tier: json['tier'] as String? ?? 'free',
        name: json['name'] as String? ?? '',
        monthly: json['monthly'] as String? ?? '',
        yearly: json['yearly'] as String? ?? '',
        badge: json['badge'] as bool? ?? false,
        features: (json['features'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  String priceFor({required bool yearlyBilling}) =>
      yearlyBilling ? yearly : monthly;

  SubscriptionTier get asTier => SubscriptionTierX.fromApi(tier);
}

class SubscriptionRepository {
  SubscriptionRepository(this._api);

  final ApiClient _api;

  Future<List<PlanTier>> fetchPlans({String region = 'PK'}) async {
    final json = await _api.get('/subscriptions/plans', query: {'region': region});
    return (json['data'] as List)
        .map((e) => PlanTier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Starts the trial and returns the updated account, so the caller can
  /// refresh the session and unlock creator tooling immediately.
  Future<UserSession> checkout({
    required String tier,
    required bool yearlyBilling,
    required String paymentMethod,
    String region = 'PK',
  }) async {
    final json = await _api.post('/subscriptions/checkout', body: {
      'tier': tier,
      'billing_cycle': yearlyBilling ? 'yearly' : 'monthly',
      'payment_method': paymentMethod,
      'region': region,
    });

    return UserSession.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<UserSession> cancel() async {
    final json = await _api.post('/subscriptions/cancel');
    return UserSession.fromJson(json['user'] as Map<String, dynamic>);
  }
}
