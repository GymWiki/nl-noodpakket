import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import '../../domain/models.dart';
import '../settings/household_form.dart';

/// Maximaal 3 schermen: uitleg, huishouden, privacy.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  Household _household = const Household();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 2) {
      await _controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
      return;
    }
    final repo = ref.read(settingsRepositoryProvider);
    final s = await repo.load();
    await repo.save(s.copyWith(household: _household, onboarded: true));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;

    Widget page(IconData icon, String title, String body, {Widget? extra, Color? tint}) =>
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconBadge(icon, size: 88, background: tint ?? c.primaryContainer),
            const SizedBox(height: 28),
            Semantics(header: true, child: Text(title, style: t.textTheme.headlineLarge)),
            const SizedBox(height: 14),
            Text(body, style: t.textTheme.bodyLarge),
            if (extra != null) ...[const SizedBox(height: 20), extra],
          ]),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                page(
                  Icons.backpack_outlined,
                  S.obTitle1,
                  S.obBody1,
                  extra: SoftCard(
                    color: c.tertiaryContainer,
                    borderColor: Colors.transparent,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline_rounded, color: c.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(S.disclaimer,
                            style: t.textTheme.bodyMedium?.copyWith(color: c.onTertiaryContainer)),
                      ),
                    ]),
                  ),
                ),
                page(
                  Icons.home_outlined,
                  S.obTitle2,
                  S.obBody2,
                  tint: c.secondaryContainer,
                  extra: SoftCard(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: HouseholdForm(
                      value: _household,
                      onChanged: (h) => setState(() => _household = h),
                    ),
                  ),
                ),
                page(Icons.lock_outline_rounded, S.obTitle3, S.obBody3, tint: c.tertiaryContainer),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(children: [
              Semantics(
                label: S.planStepOf(_page + 1, 3),
                excludeSemantics: true,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: i == _page ? 28 : 8,
                      decoration: BoxDecoration(
                        color: i == _page ? c.primary : c.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                if (_page > 0)
                  TextButton(
                    onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic),
                    child: const Text(S.back),
                  ),
                if (_page > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(_page < 2 ? S.next : S.start),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
