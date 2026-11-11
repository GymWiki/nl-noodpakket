import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dialer.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'dashboard_cards.dart';
import 'dashboard_providers.dart';

/// Start: in één blik hoe voorbereid het huishouden is en wat de logische volgende stap is.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(dashActionsProvider).ensureAnchor().catchError((Object _) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dashboardDataProvider);
    if (d.simpleStart) return const SimpleStart();
    final cards = visibleCards(d);
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            const PageTitle(S.homeTitle, subtitle: S.dashSub),
            for (final c in cards) ...[
              KeyedSubtree(key: ValueKey(c.id), child: c.build(context)),
              const SizedBox(height: Gap.m),
            ],
            Text(S.disclaimer, style: t.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Optionele "Eenvoudige start": vier grote knoppen in plaats van het dashboard.
class SimpleStart extends StatelessWidget {
  const SimpleStart({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    Widget big(IconData icon, String label, VoidCallback onTap, {bool primary = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            onTap: onTap,
            color: primary ? c.primary : null,
            semanticLabel: label,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(children: [
              IconBadge(icon,
                  size: 52,
                  background: primary ? c.onPrimary : null,
                  foreground: primary ? c.primary : null),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: t.textTheme.titleLarge?.copyWith(color: primary ? c.onPrimary : null)),
              ),
            ]),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            const PageTitle(S.homeTitle),
            big(Icons.inventory_2_outlined, S.navChecklist, () => context.go('/checklist')),
            big(Icons.health_and_safety_outlined, S.navWiki, () => context.go('/noodgevallen')),
            big(Icons.assignment_outlined, S.navPlan, () => context.go('/mijn-plan')),
            big(Icons.call, S.dashCall112, () => openDialer(context, '112'), primary: true),
            Text(S.disclaimer, style: t.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
