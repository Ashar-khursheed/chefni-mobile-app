import 'package:flutter/foundation.dart';

/// Account role as stored on the backend `users.role` column.
/// Creator tooling is NOT a role — it is unlocked by [SubscriptionTier].
enum UserRole { user, admin }

/// Backend `users.subscription_tier`.
enum SubscriptionTier { free, creatorTrial, creator, restaurantPro }

extension UserRoleX on UserRole {
  static UserRole fromApi(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  String get apiValue => this == UserRole.admin ? 'admin' : 'user';
  bool get isAdmin => this == UserRole.admin;
}

extension SubscriptionTierX on SubscriptionTier {
  static SubscriptionTier fromApi(String? value) {
    switch (value) {
      case 'creator_trial':
        return SubscriptionTier.creatorTrial;
      case 'creator':
        return SubscriptionTier.creator;
      case 'restaurant_pro':
        return SubscriptionTier.restaurantPro;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }

  String get apiValue {
    switch (this) {
      case SubscriptionTier.creatorTrial:
        return 'creator_trial';
      case SubscriptionTier.creator:
        return 'creator';
      case SubscriptionTier.restaurantPro:
        return 'restaurant_pro';
      case SubscriptionTier.free:
        return 'free';
    }
  }

  String get label {
    switch (this) {
      case SubscriptionTier.creatorTrial:
        return 'Creator (trial)';
      case SubscriptionTier.creator:
        return 'Creator';
      case SubscriptionTier.restaurantPro:
        return 'Restaurant Pro';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  /// Paid tiers (and the trial) unlock Creator Studio: uploads, analytics,
  /// publishing. Free accounts see the consumer app plus upgrade prompts.
  bool get unlocksCreatorTools => this != SubscriptionTier.free;
}

/// The signed-in account. Drives which navigation surface the app renders —
/// there is no manual mode switcher; capability follows the account.
@immutable
class UserSession {
  const UserSession({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.user,
    this.tier = SubscriptionTier.free,
    this.trialActive = false,
    this.trialEndsAt,
    this.countryCode = 'PK',
    this.uploadQuotaRemaining,
    this.uploadQuotaTotal,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final SubscriptionTier tier;
  final bool trialActive;
  final DateTime? trialEndsAt;
  final String countryCode;

  /// Video extractions left this period. Null means unlimited — the API sends
  /// null for tiers without a cap, so null is not "unknown".
  final int? uploadQuotaRemaining;

  /// What the tier grants per period, so the UI can show "2 of 10" without
  /// guessing the denominator from the tier.
  final int? uploadQuotaTotal;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRoleX.fromApi(json['role'] as String?),
      tier: SubscriptionTierX.fromApi(json['subscription_tier'] as String?),
      trialActive: json['trial_active'] as bool? ?? false,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.tryParse(json['trial_ends_at'].toString())
          : null,
      countryCode: json['country_code'] as String? ?? 'PK',
      uploadQuotaRemaining:
          (json['upload_quota_remaining'] as num?)?.toInt(),
      uploadQuotaTotal: (json['upload_quota_total'] as num?)?.toInt(),
    );
  }

  /// Guest / logged-out placeholder used before authentication completes.
  static const UserSession guest = UserSession(
    id: 0,
    name: 'Guest',
    email: '',
  );

  bool get isAdmin => role.isAdmin;

  /// Creator Studio visibility. Admins are platform operators, not creators,
  /// so they get the admin surface instead.
  bool get hasCreatorTools => !isAdmin && tier.unlocksCreatorTools;

  /// Free consumers see upgrade banners and the paywall.
  bool get showUpgradePrompts => !isAdmin && tier == SubscriptionTier.free;

  int? get trialDaysRemaining {
    if (!trialActive || trialEndsAt == null) return null;
    final days = trialEndsAt!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _take(parts.first, 2);
    return '${_take(parts.first, 1)}${_take(parts[1], 1)}';
  }

  static String _take(String value, int count) {
    final upper = value.toUpperCase();
    return upper.length <= count ? upper : upper.substring(0, count);
  }

  UserSession copyWith({
    String? name,
    String? email,
    UserRole? role,
    SubscriptionTier? tier,
    bool? trialActive,
    DateTime? trialEndsAt,
    String? countryCode,
  }) {
    return UserSession(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      tier: tier ?? this.tier,
      trialActive: trialActive ?? this.trialActive,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      countryCode: countryCode ?? this.countryCode,
    );
  }
}
