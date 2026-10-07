import 'package:flutter/material.dart';

import '../../../core/models/session_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import 'payment_success_screen.dart';

class _PaymentOption {
  const _PaymentOption(this.id, this.name, this.sub, this.badge, this.badgeColor);
  final String id;
  final String name;
  final String sub;
  final String badge;
  final Color badgeColor;
}

const List<_PaymentOption> _options = [
  _PaymentOption('card', 'Credit / Debit Card',
      'Visa, Mastercard, Amex — via Stripe', 'card', AppTheme.tealPrimary),
  _PaymentOption('jazzcash', 'JazzCash', 'Mobile wallet, Pakistan', 'JC',
      AppTheme.coralPrimaryDark),
  _PaymentOption('easypaisa', 'EasyPaisa', 'Mobile wallet, Pakistan', 'EP',
      AppTheme.successGreen),
  _PaymentOption('bank', 'Bank Transfer', 'Manual, Pakistan only', 'BT',
      AppTheme.mutedText),
];

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.tier,
    required this.tierName,
    required this.priceLabel,
    required this.yearlyBilling,
    required this.region,
  });

  final String tier;
  final String tierName;
  final String priceLabel;
  final bool yearlyBilling;
  final String region;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selected = 'card';
  bool _isSubmitting = false;

  Future<void> _confirm() async {
    setState(() => _isSubmitting = true);

    try {
      final updated = await ServiceScope.of(context).subscriptions.checkout(
            tier: widget.tier,
            yearlyBilling: widget.yearlyBilling,
            paymentMethod: _selected,
            region: widget.region,
          );

      if (!mounted) return;
      // The account now carries the new tier, so creator tooling unlocks.
      SessionScope.of(context).signIn(updated);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(tierName: widget.tierName),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiError(context, e);
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        title: Text('Payment', style: AppTheme.display(size: 19)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 22),
          Text('Payment method',
              style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._options.map(_buildMethodTile),
          const SizedBox(height: 16),
          _buildMethodFields(),
          const SizedBox(height: 22),
          _isSubmitting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: CircularProgressIndicator(
                        color: AppTheme.coralPrimary, strokeWidth: 2.5),
                  ),
                )
              : ChefniPrimaryButton(
                  label: 'Confirm — no charge for 14 days',
                  onPressed: _confirm,
                ),
          const SizedBox(height: 12),
          Text(
            'Secured by Stripe · 256-bit encryption',
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 11, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.tintCoral,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.tierName} plan',
                    style: AppTheme.display(size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '14-day free trial, then ${widget.priceLabel}',
                  style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
          Text(widget.priceLabel, style: AppTheme.display(size: 15)),
        ],
      ),
    );
  }

  Widget _buildMethodTile(_PaymentOption option) {
    final selected = _selected == option.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _isSubmitting ? null : () => setState(() => _selected = option.id),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppTheme.tintCoral : AppTheme.bgWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.tealPrimary : AppTheme.inputBorder,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: option.badgeColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: option.id == 'card'
                    ? const Icon(Icons.credit_card, size: 17, color: Colors.white)
                    : option.id == 'bank'
                        ? const Icon(Icons.account_balance,
                            size: 17, color: Colors.white)
                        : Text(option.badge,
                            style: AppTheme.display(size: 13, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.name,
                        style:
                            AppTheme.display(size: 13.5, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(option.sub,
                        style: AppTheme.body(size: 11, color: AppTheme.mutedText)),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppTheme.tealPrimary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppTheme.tealPrimary : AppTheme.cardBorder,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodFields() {
    switch (_selected) {
      case 'card':
        return Column(
          children: [
            TextField(
              enabled: !_isSubmitting,
              decoration: const InputDecoration(hintText: 'Card number'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(hintText: 'MM / YY'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(hintText: 'CVC'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              enabled: !_isSubmitting,
              decoration: const InputDecoration(hintText: 'Name on card'),
            ),
          ],
        );
      case 'jazzcash':
      case 'easypaisa':
        return TextField(
          enabled: !_isSubmitting,
          keyboardType: TextInputType.phone,
          decoration:
              const InputDecoration(hintText: 'Mobile number (03XX-XXXXXXX)'),
        );
      default:
        return ChefniCard(
          radius: 12,
          child: Text(
            'Bank transfer details will be emailed after checkout. Trial activates '
            'immediately; access confirmed once payment clears.',
            style: AppTheme.body(size: 12.5, color: AppTheme.mutedText, height: 1.6),
          ),
        );
    }
  }
}
