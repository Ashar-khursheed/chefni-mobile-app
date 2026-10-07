import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/repositories/branding_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';

/// Restaurant Pro add-on: swap the Chefni watermark on exported reels for the
/// restaurant's own name/logo.
class WhiteLabelScreen extends StatefulWidget {
  const WhiteLabelScreen({super.key});

  @override
  State<WhiteLabelScreen> createState() => _WhiteLabelScreenState();
}

class _WhiteLabelScreenState extends State<WhiteLabelScreen> {
  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  bool _enabled = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _applyBranding(Branding branding) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = branding.brandName ?? '';
    _logoController.text = branding.brandLogoUrl ?? '';
    _enabled = branding.whiteLabelEnabled;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ServiceScope.of(context).branding.update(
            whiteLabelEnabled: _enabled,
            brandName: _nameController.text.trim(),
            brandLogoUrl: _logoController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Branding saved.',
              style: AppTheme.body(size: 13.5, color: Colors.white)),
          backgroundColor: AppTheme.darkText,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.bgShell,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        title: Text('White-label branding', style: AppTheme.display(size: 17)),
      ),
      body: AsyncView<Branding>(
        load: ServiceScope.of(context).branding.fetch,
        builder: (context, branding, reload) {
          _applyBranding(branding);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.tintTeal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('White-label add-on',
                              style:
                                  AppTheme.display(size: 14, weight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('Restaurant Pro only',
                              style: AppTheme.body(size: 11.5, color: AppTheme.mutedText)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Your brand', style: AppTheme.display(size: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Brand name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _logoController,
                decoration: const InputDecoration(
                  labelText: 'Logo URL',
                  hintText: 'https://…/logo.png',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              Text('Preview', style: AppTheme.display(size: 15)),
              const SizedBox(height: 10),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: AppTheme.logoGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _enabled && _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim().toUpperCase()
                              : 'CHEFNI',
                          style: AppTheme.display(size: 11, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ChefniPrimaryButton(
                label: _saving ? 'Saving…' : 'Save branding',
                onPressed: _saving ? null : _save,
              ),
            ],
          );
        },
      ),
    );
  }
}
