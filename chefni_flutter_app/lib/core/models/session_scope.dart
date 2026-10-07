import 'package:flutter/material.dart';
import 'user_session.dart';

/// Holds the signed-in account for the widget tree. Navigation surfaces and
/// feature gates read from here, so capability always follows the account
/// rather than a manual toggle.
class SessionController extends ChangeNotifier {
  SessionController([UserSession? initial]) : _session = initial ?? UserSession.guest;

  UserSession _session;
  UserSession get session => _session;

  bool get isAuthenticated => _session.id != 0;

  void signIn(UserSession session) {
    _session = session;
    notifyListeners();
  }

  void signOut() {
    _session = UserSession.guest;
    notifyListeners();
  }

  /// Applied after a successful checkout so creator tooling unlocks
  /// immediately without a round-trip.
  void applySubscription(SubscriptionTier tier, {bool trialActive = true}) {
    _session = _session.copyWith(
      tier: tier,
      trialActive: trialActive,
      trialEndsAt: trialActive ? DateTime.now().add(const Duration(days: 14)) : null,
    );
    notifyListeners();
  }
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope is missing from the widget tree.');
    return scope!.notifier!;
  }

  static UserSession sessionOf(BuildContext context) => of(context).session;
}
