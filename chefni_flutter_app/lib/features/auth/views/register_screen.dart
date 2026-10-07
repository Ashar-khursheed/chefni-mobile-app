import 'package:flutter/material.dart';

import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_ui.dart';

/// Sign-up and sign-in against the live API. On success the account's role
/// and subscription tier decide which surface the user lands on.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onAuthenticated});

  final ValueChanged<UserSession> onAuthenticated;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = false;
  bool _isSubmitting = false;
  String? _formError;
  Map<String, List<String>>? _fieldErrors;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _fieldError(String field) => _fieldErrors?[field]?.first;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _formError = null;
      _fieldErrors = null;
    });

    final auth = ServiceScope.of(context).auth;

    try {
      final session = _isLoginMode
          ? await auth.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await auth.register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

      if (!mounted) return;
      widget.onAuthenticated(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = e.fieldErrors == null ? e.message : null;
        _fieldErrors = e.fieldErrors;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                _isLoginMode ? 'Welcome back' : 'Create account',
                style: AppTheme.display(size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                _isLoginMode
                    ? 'Sign in to pick up where you left off.'
                    : 'Start your 14-day free trial — no card required.',
                style: AppTheme.body(size: 14, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 26),
              if (!_isLoginMode) ...[
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Full name',
                    errorText: _fieldError('name'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Email address',
                  errorText: _fieldError('email'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                enabled: !_isSubmitting,
                onSubmitted: (_) => _isSubmitting ? null : _submit(),
                decoration: InputDecoration(
                  hintText: _isLoginMode ? 'Password' : 'Password (min 8 characters)',
                  errorText: _fieldError('password'),
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.alertRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 18, color: AppTheme.alertRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formError!,
                          style: AppTheme.body(
                            size: 12.5,
                            color: AppTheme.alertRed,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _isSubmitting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: CircularProgressIndicator(
                          color: AppTheme.coralPrimary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : ChefniPrimaryButton(
                      label: _isLoginMode ? 'Log in' : 'Start free trial',
                      onPressed: _submit,
                    ),
              const SizedBox(height: 30),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: AppTheme.body(size: 14, color: AppTheme.mutedText),
                    ),
                    GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() {
                                _isLoginMode = !_isLoginMode;
                                _formError = null;
                                _fieldErrors = null;
                              }),
                      child: Text(
                        _isLoginMode ? 'Sign up' : 'Log in',
                        style: AppTheme.display(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppTheme.tealPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
