import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';

/// Meer: noodplan, kluis, informatie en instellingen op één rustige plek.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget row(IconData icon, String title, String sub, String route) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            onTap: () => context.push(route),
            child: Row(children: [
              IconBadge(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: t.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(sub, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
            ]),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            const PageTitle(S.moreTitle),
            row(Icons.build_circle_outlined, S.maintTitle, S.moreMaintSub, '/start/onderhoud'),
            row(Icons.info_outline_rounded, S.infoTitle, S.moreInfoSub, '/info'),
            row(Icons.tune_rounded, S.settingsTitle, S.moreSettingsSub, '/instellingen'),
            const SizedBox(height: Gap.s),
            Text(S.disclaimer, style: t.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
