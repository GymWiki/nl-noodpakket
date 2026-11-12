import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/category_palette.dart';
import '../../core/ui.dart';

/// Meer: onderhoud, informatie en instellingen in één rustige lijst.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    StatusRow row(IconData icon, String title, String sub, String route, MenuItemKind kind) => StatusRow(
          icon: icon,
          tint: menuTint(kind),
          title: title,
          subtitle: sub,
          onTap: () => context.push(route),
          semanticLabel: '$title. $sub',
        );

    return ScreenScaffold(
      children: [
        const PageTitle(S.moreTitle),
        CalmListGroup(children: [
          row(Icons.build_circle_outlined, S.maintTitle, S.moreMaintSub, '/start/onderhoud', MenuItemKind.maintenance),
          row(Icons.info_outline_rounded, S.infoTitle, S.moreInfoSub, '/info', MenuItemKind.info),
          row(Icons.tune_rounded, S.settingsTitle, S.moreSettingsSub, '/instellingen', MenuItemKind.settings),
        ]),
        const SizedBox(height: Space.section),
        Text(S.disclaimer, style: t.textTheme.bodySmall),
      ],
    );
  }
}
