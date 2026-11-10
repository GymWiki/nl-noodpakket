import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/strings.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'domain/expiry.dart';
import 'features/checklist/checklist_screen.dart';
import 'features/expiry/expiry_screen.dart';
import 'features/info/info_screen.dart';
import 'features/items/item_form_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/noodplan/domain/plan_models.dart';
import 'features/noodplan/ui/plan_overview_screen.dart';
import 'features/noodplan/ui/plan_share_screen.dart';
import 'features/noodplan/ui/plan_talk_screen.dart';
import 'features/noodplan/ui/plan_wizard_screen.dart';
import 'features/wiki/wiki_detail_screen.dart';
import 'features/wiki/wiki_overview_screen.dart';
import 'features/wiki/wiki_steps_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final s = ref.read(settingsProvider).value;
      final loc = state.matchedLocation;
      if (s == null) return loc == '/' ? null : '/';
      if (!s.onboarded) return loc == '/onboarding' ? null : '/onboarding';
      if (loc == '/' || loc == '/onboarding') return '/checklist';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/item/:id',
        builder: (_, st) => ItemFormScreen(itemId: st.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plan',
        builder: (_, _) => const PlanOverviewScreen(),
        routes: [
          GoRoute(
            path: 'wizard',
            builder: (_, st) => PlanWizardScreen(
              section: PlanSection.values.asNameMap()[st.uri.queryParameters['s']],
            ),
          ),
          GoRoute(path: 'delen', builder: (_, _) => const PlanShareScreen()),
          GoRoute(path: 'gesprek', builder: (_, _) => const PlanTalkScreen()),
        ],
      ),
      GoRoute(
        path: '/wiki/:id',
        builder: (_, st) => WikiDetailScreen(id: st.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'stappen',
            builder: (_, st) => WikiStepsScreen(id: st.pathParameters['id']!),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/checklist', builder: (_, _) => const ChecklistScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/noodgevallen', builder: (_, _) => const WikiOverviewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/vervangen', builder: (_, _) => const ExpiryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/info', builder: (_, _) => const InfoScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/instellingen',
              builder: (_, _) => const SettingsScreen(),
              routes: [
                GoRoute(
                    path: 'verborgen',
                    builder: (_, _) => const HiddenItemsScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: S.navChecklist),
          NavigationDestination(
              icon: Icon(Icons.emergency_outlined),
              selectedIcon: Icon(Icons.emergency),
              label: S.navWiki),
          NavigationDestination(
              icon: Icon(Icons.event_repeat_outlined),
              selectedIcon: Icon(Icons.event_repeat),
              label: S.navReplace),
          NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: S.navInfo),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: S.navSettings),
        ],
      ),
    );
  }
}

class NoodpakketApp extends ConsumerStatefulWidget {
  const NoodpakketApp({super.key});

  @override
  ConsumerState<NoodpakketApp> createState() => _NoodpakketAppState();
}

class _NoodpakketAppState extends ConsumerState<NoodpakketApp> {
  String? _lastSignature;

  /// Plant herinneringen opnieuw bij elke relevante wijziging (en dus ook
  /// bij elke app-start); ongewijzigde situatie wordt overgeslagen.
  void _reschedule() {
    final items = ref.read(allItemsProvider).value;
    final s = ref.read(settingsProvider).value;
    if (items == null || s == null) return;
    final sig = StringBuffer('${s.leadDays}|${s.semiAnnual}');
    for (final i in items) {
      if (!i.hidden) sig.write('|${i.id}:${i.name}:${dueDate(i)}');
    }
    if (sig.toString() == _lastSignature) return;
    _lastSignature = sig.toString();
    ref
        .read(notificationServiceProvider)
        .reschedule(items: items, leadDays: s.leadDays, semiAnnual: s.semiAnnual)
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(allItemsProvider, (_, _) => _reschedule());
    ref.listen(settingsProvider, (_, _) => _reschedule());
    final mode =
        ref.watch(settingsProvider.select((s) => s.value?.themeMode)) ??
            ThemeMode.system;

    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [Locale('nl', 'NL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
