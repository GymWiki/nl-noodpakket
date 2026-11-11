import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/dialer.dart';
import '../../core/l10n/strings.dart';
import '../../core/legal.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';

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
    final c = t.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(S.infoTitle)),
      body: ListView(
        padding: Gap.page,
        children: [
          SoftCard(
            color: c.tertiaryContainer,
            borderColor: Colors.transparent,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: c.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(S.disclaimer,
                    style: t.textTheme.bodyMedium?.copyWith(
                        color: c.onTertiaryContainer, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SectionHeader(S.infoWhyTitle),
          const SoftCard(child: Text(S.infoWhyBody)),
          const SectionHeader(S.infoTipsTitle),
          SoftCard(
            child: Column(children: [
              for (final tip in S.infoTips)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 12),
                      child: Icon(Icons.check_circle_rounded, size: 20, color: c.secondary),
                    ),
                    Expanded(child: Text(tip)),
                  ]),
                ),
            ]),
          ),
          const SectionHeader(S.infoLinkTitle),
          SoftCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(S.infoLinkBody),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _open(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text(S.infoLinkButton),
              ),
            ]),
          ),
          const SectionHeader(S.infoPrivacyTitle),
          SoftCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lock_outline_rounded, color: c.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text(S.infoPrivacyBody)),
            ]),
          ),
          const SectionHeader(S.legalTitle),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text(S.legalPrivacy),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => openExternal(context, privacyUrl),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text(S.legalTerms),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => openExternal(context, termsUrl),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text(S.legalLicenses),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: S.appName,
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(S.legalOpensInBrowser, style: t.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
