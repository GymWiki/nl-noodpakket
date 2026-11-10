import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
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
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }
    final repo = ref.read(settingsRepositoryProvider);
    final s = await repo.load();
    await repo.save(s.copyWith(household: _household, onboarded: true));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget page(IconData icon, String title, String body, [Widget? extra]) =>
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 56, color: t.colorScheme.primary),
              const SizedBox(height: 16),
              Semantics(
                  header: true,
                  child: Text(title, style: t.textTheme.headlineMedium)),
              const SizedBox(height: 12),
              Text(body, style: t.textTheme.bodyLarge),
              if (extra != null) ...[const SizedBox(height: 16), extra],
            ],
          ),
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
                  Text(S.disclaimer,
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                ),
                page(
                  Icons.home_outlined,
                  S.obTitle2,
                  S.obBody2,
                  HouseholdForm(
                    value: _household,
                    onChanged: (h) => setState(() => _household = h),
                  ),
                ),
                page(Icons.lock_outline, S.obTitle3, S.obBody3),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(children: [
              if (_page > 0)
                TextButton(
                  onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut),
                  child: const Text(S.back),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _next,
                child: Text(_page < 2 ? S.next : S.start),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
