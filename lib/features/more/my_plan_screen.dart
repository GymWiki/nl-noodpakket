import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/category_palette.dart';
import '../../core/ui.dart';
import '../dashboard/dashboard_providers.dart';
import '../deel/deel_providers.dart';

/// Mijn plan: noodplan, gesprek met je huishouden en de documentenkluis bij elkaar.
/// Delen en scannen zitten samen in één rij ("Delen met een ander toestel").
class MyPlanScreen extends ConsumerWidget {
  const MyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final st = ref.watch(planVaultStatusProvider);
    final shared = ref.watch(sharedPlansProvider).value ?? const [];
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
        const PageTitle(S.myPlanTitle, subtitle: S.myPlanSub),
        CalmListGroup(children: [
          row(Icons.assignment_outlined, S.planTitle,
              st.planStarted ? S.planCardSub(st.planDone, st.planTotal) : S.planCardStart, '/plan', MenuItemKind.plan),
          row(Icons.forum_outlined, S.planTalk, S.myPlanTalkSub, '/plan/gesprek', MenuItemKind.talk),
          row(Icons.lock_outline, S.vaultTitle, S.vaultEntrySub, '/kluis', MenuItemKind.vault),
          StatusRow(
            icon: Icons.qr_code_2_rounded,
            tint: menuTint(MenuItemKind.share),
            title: S.deelTitle,
            subtitle: S.deelSub,
            onTap: () => _shareSheet(context),
            semanticLabel: '${S.deelTitle}. ${S.deelSub}',
          ),
        ]),
        if (shared.isNotEmpty)
          CalmSection(
            title: S.sharedWithMe,
            child: CalmListGroup(children: [
              for (final p in shared)
                row(
                    Icons.people_outline_rounded,
                    p.fromName.isEmpty ? S.sharedWithMe : S.sharedFrom(p.fromName),
                    S.sharedVersionLine(p.version, '${p.receivedAt.day}-${p.receivedAt.month}-${p.receivedAt.year}'),
                    '/delen/gedeeld/${p.planId}',
                    MenuItemKind.plan),
            ]),
          ),
        const SizedBox(height: Space.section),
        Text(S.disclaimer, style: t.textTheme.bodySmall),
      ],
    );
  }

  void _shareSheet(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.screen),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CalmListGroup(children: [
                StatusRow(
                  icon: Icons.qr_code_2_rounded,
                  tint: menuTint(MenuItemKind.share),
                  title: S.deelSheetShare,
                  subtitle: S.deelSheetShareSub,
                  onTap: () {
                    Navigator.pop(sheet);
                    context.push('/delen');
                  },
                ),
                StatusRow(
                  icon: Icons.qr_code_scanner_rounded,
                  tint: menuTint(MenuItemKind.scan),
                  title: S.scanTitle,
                  subtitle: S.scanSub,
                  onTap: () {
                    Navigator.pop(sheet);
                    context.push('/delen/scan');
                  },
                ),
              ]),
            ]),
          ),
        ),
      );
}
