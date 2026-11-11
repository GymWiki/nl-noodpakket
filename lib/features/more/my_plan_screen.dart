import 'package:flutter/material.dart';
import '../deel/deel_providers.dart';
import '../../core/theme/category_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../dashboard/dashboard_providers.dart';

/// Mijn plan: noodplan, gesprek met je huishouden en de documentenkluis bij elkaar.
class MyPlanScreen extends ConsumerWidget {
  const MyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final st = ref.watch(planVaultStatusProvider);
    final shared = ref.watch(sharedPlansProvider).value ?? const [];
    Widget row(IconData icon, String title, String sub, String route, MenuItemKind kind) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            onTap: () => context.push(route),
            semanticLabel: '$title. $sub',
            child: Row(children: [
              IconBadge(icon, tint: menuTint(kind)),
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
            const PageTitle(S.myPlanTitle, subtitle: S.myPlanSub),
            row(Icons.assignment_outlined, S.planTitle,
                st.planStarted ? S.planCardSub(st.planDone, st.planTotal) : S.planCardStart, '/plan', MenuItemKind.plan),
            row(Icons.forum_outlined, S.planTalk, S.myPlanTalkSub, '/plan/gesprek', MenuItemKind.talk),
            row(Icons.lock_outline, S.vaultTitle, S.vaultEntrySub, '/kluis', MenuItemKind.vault),
            row(Icons.qr_code_2_rounded, S.deelTitle, S.deelSub, '/delen', MenuItemKind.share),
            row(Icons.qr_code_scanner_rounded, S.scanTitle, S.scanSub, '/delen/scan', MenuItemKind.scan),
            if (shared.isNotEmpty) ...[
              SectionHeader(S.sharedWithMe),
              for (final p in shared)
                row(Icons.people_outline_rounded, p.fromName.isEmpty ? S.sharedWithMe : S.sharedFrom(p.fromName),
                    S.sharedVersionLine(p.version, '${p.receivedAt.day}-${p.receivedAt.month}-${p.receivedAt.year}'), '/delen/gedeeld/${p.planId}', MenuItemKind.plan),
            ],
            const SizedBox(height: Gap.s),
            Text(S.disclaimer, style: t.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
