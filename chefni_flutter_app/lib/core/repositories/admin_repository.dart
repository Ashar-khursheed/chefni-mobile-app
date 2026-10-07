import '../network/api_client.dart';

class TrendPoint {
  const TrendPoint({required this.label, required this.value});

  final String label;
  final int value;

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        label: json['label'] as String? ?? '',
        value: (json['value'] as num?)?.toInt() ?? 0,
      );
}

class AdminTelemetry {
  const AdminTelemetry({
    required this.totalUsers,
    required this.activeSubscriptions,
    required this.signupsToday,
    required this.totalRecipes,
    required this.signupTrend,
  });

  final int totalUsers;
  final int activeSubscriptions;
  final int signupsToday;
  final int totalRecipes;
  final List<TrendPoint> signupTrend;

  factory AdminTelemetry.fromJson(Map<String, dynamic> json) => AdminTelemetry(
        totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
        activeSubscriptions: (json['active_subscriptions'] as num?)?.toInt() ?? 0,
        signupsToday: (json['signups_today'] as num?)?.toInt() ?? 0,
        totalRecipes: (json['total_recipes'] as num?)?.toInt() ?? 0,
        signupTrend: (json['signup_trend'] as List?)
                ?.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.plan,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String plan;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
        plan: json['plan'] as String? ?? 'Free',
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class RevenueBreakdown {
  const RevenueBreakdown({required this.byPlan, required this.gatewaySplit});

  final List<({String name, int count})> byPlan;
  final List<({String name, int pct})> gatewaySplit;

  factory RevenueBreakdown.fromJson(Map<String, dynamic> json) =>
      RevenueBreakdown(
        byPlan: (json['by_plan'] as List?)
                ?.map((e) => (
                      name: (e as Map)['name'] as String? ?? '',
                      count: (e['count'] as num?)?.toInt() ?? 0,
                    ))
                .toList() ??
            const [],
        gatewaySplit: (json['gateway_split'] as List?)
                ?.map((e) => (
                      name: (e as Map)['name'] as String? ?? '',
                      pct: (e['pct'] as num?)?.toInt() ?? 0,
                    ))
                .toList() ??
            const [],
      );
}

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<AdminTelemetry> fetchTelemetry() async {
    final json = await _api.get('/admin/telemetry');
    return AdminTelemetry.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<AdminUser>> fetchUsers({String? search}) async {
    final json = await _api.get('/admin/users', query: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (json['data'] as List)
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RevenueBreakdown> fetchRevenue() async {
    final json = await _api.get('/admin/revenue');
    return RevenueBreakdown.fromJson(json['data'] as Map<String, dynamic>);
  }
}
