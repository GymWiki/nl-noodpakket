import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/theme/category_palette.dart';
import '../../core/ui.dart';
import '../noodhacks/hacks_providers.dart';
import 'paywall_config.dart';
import 'pro_providers.dart';

/// Hoe de sheet gesloten is. [action] = de gebruiker koos de directe actie na de aankoop.
enum PaywallResult { dismissed, action }

/// Opent de rustige paywall als bottom sheet. Alleen aanroepen na een bewuste actie van de gebruiker.
/// Zacht schuiven; zonder animatie als de gebruiker "beweging verminderen" aan heeft.
Future<PaywallResult> showPaywall(
  BuildContext context, {
  PaywallRequest request = const PaywallRequest.general(),
}) async {
  final reduce = MediaQuery.of(context).disableAnimations;
  final r = await showModalBottomSheet<PaywallResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    sheetAnimationStyle: reduce
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 260),
            reverseDuration: Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          ),
    builder: (_) => PaywallSheet(request: request),
  );
  return r ?? PaywallResult.dismissed;
}

/// Tekst bij een uitkomst van de winkel. Annuleren is stil: geen melding.
String? proMessageText(ProMessage m) => switch (m) {
      ProMessage.thanks => S.proMsgThanks,
      ProMessage.restored => S.proMsgRestored,
      ProMessage.nothingToRestore => S.proMsgNothing,
      ProMessage.cancelled => null,
      ProMessage.pending => S.proMsgPending,
      ProMessage.unavailable => S.proMsgUnavailable,
      ProMessage.error => S.proMsgError,
      ProMessage.none => null,
    };

class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key, this.request = const PaywallRequest.general()});
  final PaywallRequest request;

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  /// Na een geslaagde aankoop of herstelactie tonen we de bevestiging in hetzelfde blad.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && !ref.read(proUnlockedProvider)) ref.read(proControllerProvider.notifier).loadPrice();
    });
  }

  PaywallData _data() {
    final r = widget.request;
    final hacks = ref.watch(hacksProvider).value;
    final base = hackPaywallData(hacks, r.hackId);
    switch (r.context) {
      case PaywallContext.reminders:
        final items = ref.watch(allItemsProvider).value;
        final lead = ref.watch(settingsProvider.select((s) => s.value?.leadDays)) ?? 30;
        return reminderPaywallData(items, r.itemId, DateTime.now(), lead, trialHackCount: base.trialHackCount);
      case PaywallContext.vault:
        return PaywallData(trialHackCount: base.trialHackCount, vaultCount: r.vaultCount ?? 0);
      case PaywallContext.hacks:
      case PaywallContext.general:
        return base;
    }
  }

  void _close([PaywallResult r = PaywallResult.dismissed]) => Navigator.of(context).pop(r);

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(proControllerProvider);
    final pro = ref.watch(proUnlockedProvider);
    final cfg = ref.watch(paywallConfigProvider);
    final content = buildPaywallContent(widget.request.context, _data(), cfg);

    ref.listen(proUnlockedProvider, (prev, now) {
      if (now && prev == false && mounted) setState(() => _done = true);
    });

    final done = _done || pro;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.section),
        child: done ? _Done(request: widget.request, state: st, onClose: _close) : _Offer(content: content, state: st, onClose: _close),
      ),
    );
  }
}

/// Kop met titel en een duidelijke sluitknop rechtsboven (minstens 48 dp).
class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle, required this.onClose});
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(header: true, child: Text(title, style: t.textTheme.headlineSmall)),
          ),
        ),
        IconButton(
          key: const Key('paywall-close'),
          tooltip: S.paywallClose,
          icon: const Icon(Icons.close_rounded),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48), tapTargetSize: MaterialTapTargetSize.padded),
          onPressed: onClose,
        ),
      ]),
      if (subtitle != null) ...[
        const SizedBox(height: Space.tight),
        Text(subtitle!, style: t.textTheme.bodyLarge),
      ],
    ]);
  }
}

(IconData, CategoryTint?) _rowStyle(PaywallRowData r) => switch (r.kind) {
      PaywallRowKind.generalHacks || PaywallRowKind.hackCount => (Icons.tips_and_updates_outlined, menuTint(MenuItemKind.hacks)),
      PaywallRowKind.hackSearch => (Icons.search_rounded, menuTint(MenuItemKind.hacksHave)),
      PaywallRowKind.hackCategory => (
          hackCategoryIconById(r.categoryId ?? ''),
          r.categoryId == null ? CategoryTint.grey : hackTint(r.categoryId!),
        ),
      PaywallRowKind.hackSafetyFree => (Icons.verified_user_outlined, CategoryTint.teal),
      PaywallRowKind.generalReminders || PaywallRowKind.reminderExample => (Icons.notifications_none_rounded, menuTint(MenuItemKind.expiring)),
      PaywallRowKind.reminderChoice => (Icons.tune_rounded, CategoryTint.blue),
      PaywallRowKind.reminderOnDevice => (Icons.phone_android_rounded, CategoryTint.grey),
      PaywallRowKind.generalVault || PaywallRowKind.vaultUsage => (Icons.folder_open_outlined, menuTint(MenuItemKind.vault)),
      PaywallRowKind.vaultKeep => (Icons.lock_outline_rounded, CategoryTint.teal),
      PaywallRowKind.vaultUnlimited => (Icons.all_inclusive_rounded, CategoryTint.blue),
    };

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.data);
  final PaywallRowData data;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (icon, tint) = _rowStyle(data);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.group),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconBadge(icon, size: 40, tint: tint),
          const SizedBox(width: Space.group),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.text, style: t.textTheme.bodyLarge),
                for (final d in data.details)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $d', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Lange knoppen van gelijke grootte: de koopknop en "Niet nu" zijn even groot en even zichtbaar.
ButtonStyle _bigFilled(BuildContext c) =>
    FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), textStyle: Theme.of(c).textTheme.titleMedium);
ButtonStyle _bigText(BuildContext c) =>
    TextButton.styleFrom(minimumSize: const Size.fromHeight(56), textStyle: Theme.of(c).textTheme.titleMedium);

class _Offer extends ConsumerWidget {
  const _Offer({required this.content, required this.state, required this.onClose});
  final PaywallContent content;
  final ProState state;
  final void Function([PaywallResult]) onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final ctl = ref.read(proControllerProvider.notifier);
    final store = ref.watch(storeNameProvider);
    final apple = ref.watch(storeIsAppleProvider);

    final ready = state.priceStatus == PriceStatus.ready && state.price != null;
    final pending = state.message == ProMessage.pending;
    final canBuy = ready && !state.busy && !pending;
    final label = ready
        ? S.paywallUnlock(state.price!)
        : state.priceStatus == PriceStatus.loading
            ? S.paywallPriceLoading
            : S.paywallUnlockNoPrice;

    // Eén rustige melding: de uitkomst van de winkel, of dat de winkel niet bereikbaar is.
    final noticeText = proMessageText(state.message) ??
        (state.priceStatus == PriceStatus.unavailable ? S.proMsgUnavailable : null);
    final canRetry = state.message == ProMessage.error ||
        state.message == ProMessage.unavailable ||
        (state.message == ProMessage.none && state.priceStatus == PriceStatus.unavailable);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Header(title: content.title, subtitle: content.subtitle, onClose: () => onClose()),
      const SizedBox(height: Space.section),
      for (final r in content.rows) _FeatureRow(r),
      if (noticeText != null) ...[
        Semantics(
          liveRegion: true,
          child: Text(noticeText, style: t.textTheme.bodyLarge),
        ),
        if (canRetry)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('paywall-retry'),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: state.busy
                  ? null
                  : () => state.message == ProMessage.error ? ctl.buy() : ctl.loadPrice(),
              child: const Text(S.paywallRetry),
            ),
          ),
        const SizedBox(height: Space.group),
      ],
      if (state.busy && !pending)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.group),
          child: Text(S.paywallWaiting, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
        ),
      FilledButton(
        key: const Key('paywall-buy'),
        style: _bigFilled(context),
        onPressed: canBuy ? ctl.buy : null,
        child: Text(label, textAlign: TextAlign.center),
      ),
      const SizedBox(height: 8),
      Center(child: Text(S.paywallOneOff, style: t.textTheme.bodyMedium, textAlign: TextAlign.center)),
      const SizedBox(height: Space.group),
      TextButton(
        key: const Key('paywall-not-now'),
        style: _bigText(context),
        onPressed: () => onClose(),
        child: const Text(S.paywallNotNow),
      ),
      TextButton(
        key: const Key('paywall-restore'),
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: state.busy ? null : () => ctl.restore(),
        child: const Text(S.paywallRestore),
      ),
      const SizedBox(height: Space.tight),
      Text(S.paywallStoreNote(store), style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
      if (content.familySharing && apple) ...[
        const SizedBox(height: Space.tight),
        Text(S.paywallFamilySharing, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
      ],
      if (content.showFreeBlock) ...[
        const SizedBox(height: Space.section),
        Semantics(header: true, child: Text(S.paywallFreeTitle, style: t.textTheme.titleMedium)),
        const SizedBox(height: Space.tight),
        for (final f in content.freeItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.check_rounded, size: 20, color: c.secondary)),
              const SizedBox(width: 12),
              Expanded(child: Text(f, style: t.textTheme.bodyLarge)),
            ]),
          ),
      ],
      if (content.showSupportLine) ...[
        const SizedBox(height: Space.tight),
        Text(S.paywallSupport, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
      ],
    ]);
  }
}

/// Rustige bevestiging na aankoop of herstel. Eén directe actie; nooit een vraag om een review.
class _Done extends StatelessWidget {
  const _Done({required this.request, required this.state, required this.onClose});
  final PaywallRequest request;
  final ProState state;
  final void Function([PaywallResult]) onClose;

  String get _actionLabel => switch (request.context) {
        PaywallContext.hacks => request.hackId != null ? S.proDoneActionHack : S.proDoneActionHacks,
        PaywallContext.reminders => request.itemId != null ? S.proDoneActionReminders : S.proDoneActionBack,
        PaywallContext.vault => S.proDoneActionVault,
        PaywallContext.general => S.proDoneActionHacks,
      };

  @override
  Widget build(BuildContext context) {
    final restored = state.message == ProMessage.restored;
    const can = [S.paywallGeneralHacks, S.paywallGeneralReminders, S.paywallGeneralVault];
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Header(title: restored ? S.proDoneRestoredTitle : S.proDoneTitle, subtitle: S.proDoneSub, onClose: () => onClose()),
      const SizedBox(height: Space.group),
      for (final s in can)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.check_rounded, size: 20, color: t.colorScheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: Text(s, style: t.textTheme.bodyLarge)),
          ]),
        ),
      const SizedBox(height: Space.group),
      FilledButton(
        key: const Key('paywall-done-action'),
        style: _bigFilled(context),
        onPressed: () => onClose(PaywallResult.action),
        child: Text(_actionLabel, textAlign: TextAlign.center),
      ),
      TextButton(
        key: const Key('paywall-done-close'),
        style: _bigText(context),
        onPressed: () => onClose(),
        child: const Text(S.proDoneClose),
      ),
    ]);
  }
}
