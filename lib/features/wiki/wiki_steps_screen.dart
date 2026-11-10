import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/dialer.dart';
import '../../core/l10n/strings.dart';
import 'wiki_models.dart';
import 'wiki_providers.dart';

/// Eén stap per scherm in grote letters, of als lijst; scherm blijft aan.
class WikiStepsScreen extends ConsumerStatefulWidget {
  const WikiStepsScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<WikiStepsScreen> createState() => _WikiStepsScreenState();
}

class _WikiStepsScreenState extends ConsumerState<WikiStepsScreen> {
  WikiProgress _p = const WikiProgress();
  bool _loaded = false;
  bool _listMode = false;

  @override
  void initState() {
    super.initState();
    _safeWakelock(true);
    ref.read(wikiPrefsProvider).loadProgress(widget.id).then((p) {
      if (!mounted) return;
      setState(() {
        _p = p;
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _safeWakelock(false);
    super.dispose();
  }

  // Wakelock kan ontbreken (bijv. in tests); de modus werkt ook zonder.
  Future<void> _safeWakelock(bool on) async {
    try {
      await (on ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (_) {}
  }

  void _set(WikiProgress p) {
    setState(() => _p = p);
    ref.read(wikiPrefsProvider).saveProgress(widget.id, p);
  }

  @override
  Widget build(BuildContext context) {
    final wiki = ref.watch(wikiProvider);
    return wiki.when(
      loading: () => Scaffold(
          appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
          appBar: AppBar(), body: const Center(child: Text(S.wikiLoadError))),
      data: (d) {
        final e = d.byId(widget.id);
        if (e == null || !_loaded) {
          return Scaffold(
              appBar: AppBar(),
              body: Center(
                  child: _loaded
                      ? const Text(S.wikiNotFound)
                      : const CircularProgressIndicator()));
        }
        return _build(context, e);
      },
    );
  }

  Widget _build(BuildContext context, WikiEmergency e) {
    final steps = e.alleStappen;
    final n = steps.length;
    final i = _p.current.clamp(0, n - 1);
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(e.titel),
        actions: [
          IconButton(
            tooltip: _listMode ? S.wikiViewSteps : S.wikiViewList,
            icon: Icon(_listMode ? Icons.looks_one_outlined : Icons.format_list_numbered),
            onPressed: () => setState(() => _listMode = !_listMode),
          ),
          IconButton(
            tooltip: S.wikiCall112,
            icon: const Icon(Icons.call),
            onPressed: () => openDialer(context, '112'),
          ),
        ],
      ),
      body: SafeArea(
        child: _listMode ? _list(context, e, steps) : _single(context, e, steps, i, t),
      ),
    );
  }

  Widget _single(BuildContext context, WikiEmergency e, List<String> steps, int i, ThemeData t) {
    final n = steps.length;
    final isAfter = i >= e.stappenNu.length;
    final last = i == n - 1;
    final done = _p.done.contains(i);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Semantics(
          label: S.wikiStepOf(i + 1, n),
          value: '${((i + 1) * 100 / n).round()}%',
          child: LinearProgressIndicator(
            value: (i + 1) / n,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${S.wikiStepOf(i + 1, n)} · ${isAfter ? S.wikiAfter : S.wikiNow}',
            style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.primary),
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            liveRegion: true,
            label: '${S.wikiStepOf(i + 1, n)}: ${steps[i]}',
            excludeSemantics: true,
            child: Text(
              steps[i],
              style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ),
      ),
      CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(S.wikiDone, style: TextStyle(fontSize: 18)),
        value: done,
        onChanged: (v) => _set(_p.copyWith(
            done: v == true ? {..._p.done, i} : ({..._p.done}..remove(i)))),
      ),
      if (last && _p.done.length >= n)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(S.wikiAllDone, style: t.textTheme.bodyLarge),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: i > 0 ? () => _set(_p.copyWith(current: i - 1)) : null,
              child: const Text(S.wikiPrev, style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: last
                  ? () => Navigator.of(context).maybePop()
                  : () => _set(_p.copyWith(current: i + 1)),
              child: Text(last ? S.wikiFinish : S.wikiNext,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ]),
      ),
      TextButton(
        onPressed: () async {
          await ref.read(wikiPrefsProvider).resetProgress(widget.id);
          setState(() => _p = const WikiProgress());
        },
        child: const Text(S.wikiRestart),
      ),
    ]);
  }

  Widget _list(BuildContext context, WikiEmergency e, List<String> steps) {
    final t = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i == 0 || i == e.stappenNu.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
              child: Semantics(
                header: true,
                child: Text(i == 0 ? S.wikiNow : S.wikiAfter,
                    style: t.textTheme.titleLarge),
              ),
            ),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: _p.done.contains(i),
            title: Text('${i + 1}. ${steps[i]}', style: const TextStyle(fontSize: 18)),
            onChanged: (v) => _set(_p.copyWith(
                done: v == true ? {..._p.done, i} : ({..._p.done}..remove(i)))),
          ),
        ],
        TextButton(
          onPressed: () async {
            await ref.read(wikiPrefsProvider).resetProgress(widget.id);
            setState(() => _p = const WikiProgress());
          },
          child: const Text(S.wikiRestart),
        ),
      ],
    );
  }
}
