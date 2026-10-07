import 'package:flutter/material.dart';

import '../../../core/models/session_scope.dart';
import '../../../core/repositories/subscription_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import 'checkout_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  static const Map<String, String> _regions = {
    'PK': 'Pakistan',
    'AE': 'UAE',
    'US': 'Global',
  };

  String? _region;
  bool _yearly = false;
  String _selectedTier = 'creator';

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    final session = SessionScope.sessionOf(context);
    final region = _region ??= _regions.containsKey(session.countryCode)
        ? session.countryCode
        : 'PK';

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        title: Text('Choose your plan', style: AppTheme.display(size: 19)),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AsyncView<List<PlanTier>>(
        key: ValueKey(region),
        load: () => services.subscriptions.fetchPlans(region: region),
        builder: (context, plans, reload) {
          final selected = plans.firstWhere(
            (p) => p.tier == _selectedTier,
            orElse: () => plans.first,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(
                'Start with a 14-day free trial. No card charged today — cancel anytime.',
                style: AppTheme.body(
                    size: 13.5, color: AppTheme.mutedText, height: 1.5),
              ),
              const SizedBox(height: 18),
              _buildRegionPicker(region),
              const SizedBox(height: 14),
              ChefniSegmented(
                labels: const ['Monthly', 'Yearly'],
                selectedIndex: _yearly ? 1 : 0,
                onChanged: (i) => setState(() => _yearly = i == 1),
              ),
              const SizedBox(height: 20),
              ...plans.map(_buildTierCard),
              const SizedBox(height: 8),
              ChefniPrimaryButton(
                label: selected.tier == 'free'
                    ? 'Continue on Free'
                    : 'Start 14-day free trial',
                onPressed: () => _continue(selected, region),
              ),
              const SizedBox(height: 12),
              Text(
                'Payments in Pakistan support JazzCash, EasyPaisa and bank transfer.',
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
              ),
            ],
          );
        },
      ),
    );
  }

  void _continue(PlanTier plan, String region) {
    if (plan.tier == 'free') {
      Navigator.of(context).maybePop();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          tier: plan.tier,
          tierName: plan.name,
          priceLabel: plan.priceFor(yearlyBilling: _yearly),
          yearlyBilling: _yearly,
          region: region,
        ),
      ),
    );
  }

  Widget _buildRegionPicker(String region) {
    return Row(
      children: _regions.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChefniChip(
            label: e.value,
            selected: e.key == region,
            selectedColor: AppTheme.tealPrimary,
            showBorder: true,
            onTap: () => setState(() => _region = e.key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTierCard(PlanTier plan) {
    final selected = _selectedTier == plan.tier;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => setState(() => _selectedTier = plan.tier),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.coralPrimary : AppTheme.inputBorder,
              width: 2,
            ),
            boxShadow: selected ? AppTheme.cardShadow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(plan.name, style: AppTheme.display(size: 17)),
                  if (plan.badge) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.tintCoral,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'MOST POPULAR',
                        style: AppTheme.display(
                          size: 9.5,
                          weight: FontWeight.w700,
                          color: AppTheme.coralPrimary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(plan.priceFor(yearlyBilling: _yearly),
                      style: AppTheme.display(size: 15)),
                ],
              ),
              const SizedBox(height: 12),
              ...plan.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 15, color: AppTheme.tealPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            Text(f, style: AppTheme.body(size: 13, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
