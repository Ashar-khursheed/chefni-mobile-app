import 'package:flutter/material.dart';

import '../../../core/repositories/legal_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';

enum LegalDocumentKind { privacyPolicy, terms }

/// Renders whichever legal document the server returns — either headed
/// sections (privacy policy) or a single block of text (terms).
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.kind});

  final LegalDocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final legal = ServiceScope.of(context).legal;

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        title: Text(
          kind == LegalDocumentKind.privacyPolicy
              ? 'Privacy policy'
              : 'Terms of service',
          style: AppTheme.display(size: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AsyncView<LegalDocument>(
        load: () => kind == LegalDocumentKind.privacyPolicy
            ? legal.fetchPrivacyPolicy()
            : legal.fetchTerms(),
        builder: (context, doc, reload) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Text(doc.title, style: AppTheme.display(size: 21)),
            if (doc.lastUpdated != null) ...[
              const SizedBox(height: 6),
              Text(
                'Last updated ${doc.lastUpdated}',
                style: AppTheme.body(size: 12.5, color: AppTheme.mutedText),
              ),
            ],
            const SizedBox(height: 20),
            if (doc.content != null)
              Text(
                doc.content!,
                style: AppTheme.body(size: 14, height: 1.6),
              ),
            for (final section in doc.sections) ...[
              Text(section.heading, style: AppTheme.display(size: 15.5)),
              const SizedBox(height: 8),
              Text(
                section.content,
                style: AppTheme.body(
                    size: 13.5, color: AppTheme.mutedText, height: 1.6),
              ),
              const SizedBox(height: 22),
            ],
          ],
        ),
      ),
    );
  }
}
