import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'features/expiry/reminder_items.dart';
import 'features/pro/pro_providers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/strings.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'domain/expiry.dart';
import 'features/checklist/checklist_screen.dart';
import 'features/dashboard/dashboard_providers.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/dashboard_subscreens.dart';
import 'features/more/my_plan_screen.dart';
import 'features/noodhacks/hack_detail_screen.dart';
import 'features/noodhacks/hacks_have_screen.dart';
import 'features/noodhacks/hacks_out_screen.dart';
import 'features/noodhacks/hacks_overview_screen.dart';
import 'features/more/more_screen.dart';
import 'features/info/info_screen.dart';
import 'features/items/item_form_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/kluis/data/vault_controller.dart';
import 'features/kluis/ui/vault_add_screen.dart';
import 'features/kluis/ui/vault_doc_screen.dart';
import 'features/kluis/ui/vault_gate.dart';
import 'features/kluis/ui/vault_home_screen.dart';
import 'features/kluis/ui/vault_settings_screen.dart';
import 'features/noodplan/domain/plan_models.dart';
import 'features/noodplan/domain/plan_reminder.dart';
import 'features/noodplan/plan_providers.dart';
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
      if (loc == '/' || loc == '/onboarding') return '/start';
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
        path: '/kluis',
        builder: (_, _) => const VaultGate(child: VaultHomeScreen()),
        routes: [
          GoRoute(
            path: 'toevoegen',
            builder: (_, st) => VaultGate(
              child: VaultAddScreen(docId: st.uri.queryParameters['doc']),
            ),
          ),
          GoRoute(
            path: 'doc/:id',
            builder: (_, st) => VaultGate(
              child: VaultDocScreen(docId: st.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: 'instellingen',
            builder: (_, _) => const VaultGate(child: VaultSettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/plan',
        builder: (_, _) => const PlanOverviewScreen(),
        routes: [
          GoRoute(
            path: 'wizard',
            builder: (_, st) => PlanWizardScreen(
              section: PlanSection.values
                  .asNameMap()[st.uri.queryParameters['s']],
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
      GoRoute(
        path: '/hacks',
        builder: (_, _) => const HacksOverviewScreen(),
        routes: [
          GoRoute(path: 'pakket-op', builder: (_, _) => const HacksOutScreen()),
          GoRoute(path: 'in-huis', builder: (_, _) => const HacksHaveScreen()),
          GoRoute(
            path: ':id',
            builder: (_, st) => HackDetailScreen(id: st.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'stappen',
                builder: (_, st) =>
                    HackStepsScreen(id: st.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/info', builder: (_, _) => const InfoScreen()),
      GoRoute(
        path: '/instellingen',
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'verborgen',
            builder: (_, _) => const HiddenItemsScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/start',
                builder: (_, _) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'suggesties',
                    builder: (_, _) => const SuggestionsScreen(),
                  ),
                  GoRoute(
                    path: 'nl-alert',
                    builder: (_, _) => const NlAlertScreen(),
                  ),
                  GoRoute(
                    path: 'onderhoud',
                    builder: (_, _) => const MaintenanceScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/checklist',
                builder: (_, st) => ChecklistScreen(
                  initialTab: st.uri.queryParameters['tab'] == 'vervangen'
                      ? 1
                      : 0,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/noodgevallen',
                builder: (_, _) => const WikiOverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mijn-plan',
                builder: (_, _) => const MyPlanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/meer', builder: (_, _) => const MoreScreen()),
            ],
          ),
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
      // Labels in de navigatiebalk schalen niet mee: anders breekt "Noodgevallen" midden in het woord.
      // De rest van de app schaalt wel volledig mee.
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.0,
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: S.navHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: S.navChecklist,
            ),
            NavigationDestination(
              icon: Icon(Icons.health_and_safety_outlined),
              selectedIcon: Icon(Icons.health_and_safety),
              label: S.navWiki,
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: S.navPlan,
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: S.navMore,
            ),
          ],
        ),
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

  @override
  void initState() {
    super.initState();
    // De store-luisteraar moet vanaf het begin actief zijn (uitgestelde betalingen).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pro = ref.read(proControllerProvider.notifier);
      // Stille controle alleen op Android; op iOS is herstellen altijd een eigen keuze (Apple-richtlijn).
      if (defaultTargetPlatform == TargetPlatform.android) pro.restore(silent: true);
    });
  }

  /// Plant herinneringen opnieuw bij elke relevante wijziging (en dus ook
  /// bij elke app-start); ongewijzigde situatie wordt overgeslagen.
  void _reschedule() {
    final all = ref.read(allItemsProvider).value;
    final s = ref.read(settingsProvider).value;
    if (all == null || s == null) return;
    // Vervangherinneringen: alleen met Pro en alleen voor items waarvoor de gebruiker ze aanzette.
    final items = itemsToRemind(all, ref.read(reminderItemsProvider), pro: ref.read(proUnlockedProvider));
    final plan = ref.read(planProvider).value;
    final planAt = s.planReminder && plan != null
        ? planReminderTime(plan, DateTime.now())
        : null;
    final vaultTimes =
        ref.read(vaultReminderTimesProvider).value ?? const <DateTime>[];
    final maintTimes = ref.read(maintenanceReminderTimesProvider);
    final sig = StringBuffer(
      '${s.leadDays}|${s.semiAnnual}|$planAt|${vaultTimes.map((t) => t.millisecondsSinceEpoch).join(',')}|m${maintTimes.map((t) => t.millisecondsSinceEpoch).join(',')}',
    );
    for (final i in items) {
      if (!i.hidden) sig.write('|${i.id}:${i.name}:${dueDate(i)}');
    }
    if (sig.toString() == _lastSignature) return;
    _lastSignature = sig.toString();
    ref
        .read(notificationServiceProvider)
        .reschedule(
          items: items,
          leadDays: s.leadDays,
          semiAnnual: s.semiAnnual,
          planReminderAt: planAt,
          vaultReminders: vaultTimes,
          maintenanceReminders: maintTimes,
        )
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(allItemsProvider, (_, _) => _reschedule());
    ref.listen(settingsProvider, (_, _) => _reschedule());
    ref.listen(planProvider, (_, _) => _reschedule());
    ref.listen(vaultReminderTimesProvider, (_, _) => _reschedule());
    ref.listen(proUnlockedProvider, (_, _) => _reschedule());
    ref.listen(maintenanceReminderTimesProvider, (_, _) => _reschedule());
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
