import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../data/repositories/plan_repository.dart';
import '../domain/plan_models.dart';
import '../domain/plan_share.dart';
import '../plan_providers.dart';
import 'plan_widgets.dart';

enum TalkTargetKind { agreement, placeAddress, location, careDevices }

/// Plek in het plan waar het antwoord op een gesprekskaart wordt opgeslagen.
class TalkTarget {
  const TalkTarget(this.kind, this.key);
  final TalkTargetKind kind;
  final String key;

  String label() => switch (kind) {
        TalkTargetKind.agreement => agreementLabel(key),
        TalkTargetKind.placeAddress => placeLabel(key),
        TalkTargetKind.location => locationLabel(key),
        TalkTargetKind.careDevices => S.planCareDevices,
      };

  String read(Plan p) => switch (kind) {
        TalkTargetKind.agreement => p.agreement(key),
        TalkTargetKind.placeAddress => p.place(key)?.address ?? '',
        TalkTargetKind.location => p.locationText(key),
        TalkTargetKind.careDevices => p.devices,
      };

  Future<void> write(PlanRepository r, String v) => switch (kind) {
        TalkTargetKind.agreement => r.setAgreement(key, v),
        TalkTargetKind.placeAddress => r.setPlace(key, address: v),
        TalkTargetKind.location => r.setLocation(key, v),
        TalkTargetKind.careDevices => r.setCare(devices: v),
      };
}

class TalkCard {
  const TalkCard(this.question, this.target);
  final String question;
  final TalkTarget target;
}

/// Vragen uit het noodplan en "praat erover" van denkvooruit.nl.
const talkCards = <TalkCard>[
  TalkCard(S.planTalkQ1, TalkTarget(TalkTargetKind.agreement, PlanKeys.kids)),
  TalkCard(S.planTalkQ2, TalkTarget(TalkTargetKind.placeAddress, PlanKeys.placeNeighbourhood)),
  TalkCard(S.planTalkQ3, TalkTarget(TalkTargetKind.agreement, PlanKeys.checkin)),
  TalkCard(S.planTalkQ4, TalkTarget(TalkTargetKind.agreement, PlanKeys.vulnerable)),
  TalkCard(S.planTalkQ5, TalkTarget(TalkTargetKind.location, PlanKeys.escapeRoutes)),
  TalkCard(S.planTalkQ6, TalkTarget(TalkTargetKind.careDevices, '')),
  TalkCard(S.planTalkQ7, TalkTarget(TalkTargetKind.agreement, PlanKeys.infoSource)),
  TalkCard(S.planTalkQ8, TalkTarget(TalkTargetKind.agreement, PlanKeys.otherAgreements)),
  TalkCard(S.planTalkQ9, TalkTarget(TalkTargetKind.agreement, PlanKeys.neighbourDeals)),
];

/// Gesprekskaarten voor aan tafel: één vraag per scherm, groot lettertype.
class PlanTalkScreen extends ConsumerStatefulWidget {
  const PlanTalkScreen({super.key});

  @override
  ConsumerState<PlanTalkScreen> createState() => _PlanTalkScreenState();
}

class _PlanTalkScreenState extends ConsumerState<PlanTalkScreen> {
  int _i = -1; // -1 = intro, talkCards.length = klaar

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final plan = ref.watch(planProvider).value ?? const Plan();
    final n = talkCards.length;

    Widget body;
    if (_i < 0) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.forum_outlined, size: 48, color: t.colorScheme.primary),
          const SizedBox(height: 16),
          Text(S.planTalkTitle, style: t.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(S.planTalkIntro, style: t.textTheme.bodyLarge),
          const Spacer(),
          FilledButton(onPressed: () => setState(() => _i = 0), child: const Text(S.planTalkStart)),
        ]),
      );
    } else if (_i >= n) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.check_circle_outline, size: 48, color: t.colorScheme.primary),
          const SizedBox(height: 16),
          Text(S.planTalkDone, style: t.textTheme.headlineMedium),
          const Spacer(),
          FilledButton(onPressed: () => context.pop(), child: const Text(S.planFinishDone)),
        ]),
      );
    } else {
      final card = talkCards[_i];
      body = Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: LinearProgressIndicator(
            value: (_i + 1) / n,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(S.planTalkCardOf(_i + 1, n),
                  style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.primary)),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(card.question,
                    style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3)),
              ),
              const SizedBox(height: 24),
              AutoSaveField(
                key: ValueKey('talk$_i'),
                initial: card.target.read(plan),
                label: S.planTalkAnswerHint,
                maxLines: 4,
                onSave: (v) => card.target.write(ref.read(planRepositoryProvider), v),
              ),
              const SizedBox(height: 8),
              Text(S.planTalkSavedTo(card.target.label()),
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text(S.planTalkTitle)),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: body),
          if (_i >= 0 && _i < n)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _i = _i - 1),
                    child: const Text(S.planPrev, style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => _i = _i + 1),
                    child: const Text(S.planNextStep, style: TextStyle(fontSize: 18)),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}
