import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_ui.dart';

/// Step two: the six digits from the SMS. Verifying creates the account if the
/// number is new, so there is no separate sign-up step.
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({
    super.key,
    required this.phone,
    required this.onAuthenticated,
  });

  final String phone;
  final ValueChanged<UserSession> onAuthenticated;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  /// The server's resend cooldown, mirrored so the button matches the API.
  static const int _resendCooldown = 60;

  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isSubmitting = false;
  String? _error;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    // Typing the sixth digit submits, and the button submits too. Without this
    // guard both fire: the first call consumes the code and the second is told
    // it is invalid, so a successful sign-in shows an error.
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final session = await ServiceScope.of(context).auth.verifyOtp(
            phone: widget.phone,
            code: code,
          );
      if (!mounted) return;
      // Stays submitting on success: the gate swaps this screen out, and
      // re-enabling would let a second submit reuse a spent code.
      widget.onAuthenticated(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        // A rejected code is the common case; clear it so the next attempt
        // starts from an empty field.
        _error = e.errorFor('code') ?? e.message;
        _codeController.clear();
        _isSubmitting = false;
      });
      _focusNode.requestFocus();
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await ServiceScope.of(context).auth.requestOtp(widget.phone);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New code sent.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.bgShell,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkText),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Change number',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // On a browser this screen would otherwise stretch the code boxes
            // across the whole window.
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Text('Enter the code', style: AppTheme.display(size: 24)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTheme.body(size: 13.5, color: AppTheme.mutedText),
                          children: [
                            const TextSpan(text: 'Sent to '),
                            TextSpan(
                              text: widget.phone,
                              style: AppTheme.body(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Change',
                        style: AppTheme.body(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: AppTheme.coralPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _buildCodeBoxes(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTheme.body(size: 12.5, color: AppTheme.alertRed),
                  ),
                ],
                const SizedBox(height: 20),
                ChefniPrimaryButton(
                  label: _isSubmitting ? 'Verifying…' : 'Verify & continue',
                  onPressed: _isSubmitting || _codeController.text.length != 6
                      ? null
                      : _verify,
                ),
                const SizedBox(height: 16),
                Center(
                  child: _secondsLeft > 0
                      ? Text(
                          'Didn’t get it? Resend in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                          style: AppTheme.body(size: 12.5, color: AppTheme.mutedText),
                        )
                      : TextButton(
                          onPressed: _resend,
                          child: Text(
                            'Resend code',
                            style: AppTheme.body(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppTheme.coralPrimary,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Six boxes that mirror one hidden field — one input to manage, but the
  /// digit-per-box look the design asks for.
  Widget _buildCodeBoxes() {
    final digits = _codeController.text.split('');

    return Stack(
      children: [
        Row(
          children: List.generate(6, (i) {
            final filled = i < digits.length;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 5 ? 0 : 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.bgWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: filled ? AppTheme.coralPrimary : AppTheme.inputBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      filled ? digits[i] : '',
                      style: AppTheme.display(size: 20),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _codeController,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (value) {
                setState(() {});
                if (value.length == 6) _verify();
              },
            ),
          ),
        ),
      ],
    );
  }
}
