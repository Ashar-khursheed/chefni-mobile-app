import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/models/session_scope.dart';
import 'core/models/user_session.dart';
import 'core/navigation/app_shell.dart';
import 'core/services/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/phone_entry_screen.dart';
import 'features/onboarding/views/onboarding_screen.dart';
import 'features/welcome/views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChefniApp());
}

class ChefniApp extends StatefulWidget {
  const ChefniApp({super.key});

  @override
  State<ChefniApp> createState() => _ChefniAppState();
}

class _ChefniAppState extends State<ChefniApp> {
  final Services _services = Services();
  final SessionController _session = SessionController();

  @override
  void dispose() {
    _session.dispose();
    _services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ServiceScope(
      services: _services,
      child: SessionScope(
        controller: _session,
        child: MaterialApp(
          title: 'Chefni AI — Fine. Fast. Fab.',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const _RootGate(),
        ),
      ),
    );
  }
}

enum _Stage { splash, onboarding, auth }

/// Restores a stored session first; if none exists, runs the
/// splash → onboarding → auth flow. Once authenticated, the shell derives
/// navigation from the account's role and tier.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  /// Set once the intro has been seen, so returning users — and every hot
  /// reload during development — land on sign-in rather than the splash.
  static const _seenIntroKey = 'chefni_seen_intro';

  _Stage _stage = _Stage.splash;
  Future<UserSession?>? _restore;

  @override
  void initState() {
    super.initState();
    _loadIntroState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inherited widgets are only safe to read from here, not initState.
    _restore ??= ServiceScope.of(context).auth.restoreSession();
  }

  Future<void> _loadIntroState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool(_seenIntroKey) ?? false) {
      setState(() => _stage = _Stage.auth);
    }
  }

  Future<void> _markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenIntroKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = SessionScope.of(context);

    if (controller.isAuthenticated) {
      return const AppShell();
    }

    return FutureBuilder<UserSession?>(
      future: _restore,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BootSplash();
        }

        if (snapshot.hasError) {
          // If the server is down or the token is corrupted, we must not
          // trap the user on the splash screen.
          return _buildOnboardingFlow(controller);
        }

        // A restored session signs in on the next frame; the gate then
        // rebuilds into the shell.
        final restored = snapshot.data;
        if (restored != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) controller.signIn(restored);
          });
          return const _BootSplash();
        }

        return _buildOnboardingFlow(controller);
      },
    );
  }

  Widget _buildOnboardingFlow(SessionController controller) {
    switch (_stage) {
      case _Stage.splash:
        return SplashScreen(
          onGetStarted: () => setState(() => _stage = _Stage.onboarding),
        );
      case _Stage.onboarding:
        return OnboardingScreen(
          onFinishOnboarding: () {
            _markIntroSeen();
            setState(() => _stage = _Stage.auth);
          },
        );
      case _Stage.auth:
        // Phone is the primary credential; the email form is still reachable
        // from a link on this screen.
        return PhoneEntryScreen(onAuthenticated: controller.signIn);
    }
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.coralPrimary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
