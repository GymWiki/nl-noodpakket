import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/strings.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(Uri.parse('https://www.denkvooruit.nl/'),
        mode: LaunchMode.externalApplication);
    if (!ok) messenger.showSnackBar(const SnackBar(content: Text(S.infoLinkError)));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget section(String title, Widget body) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                  header: true, child: Text(title, style: t.textTheme.titleLarge)),
              const SizedBox(height: 8),
              body,
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text(S.infoTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            color: t.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: t.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(S.disclaimer,
                        style: TextStyle(
                            color: t.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          section(S.infoWhyTitle, const Text(S.infoWhyBody)),
          section(
            S.infoTipsTitle,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tip in S.infoTips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 8),
                          child: Icon(Icons.check_circle_outline, size: 20),
                        ),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          section(
            S.infoLinkTitle,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(S.infoLinkBody),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _open(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text(S.infoLinkButton),
                ),
              ],
            ),
          ),
          section(S.infoPrivacyTitle, const Text(S.infoPrivacyBody)),
        ],
      ),
    );
  }
}
