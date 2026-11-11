// ignore_for_file: unnecessary_non_null_assertion
import '../expiry/reminder_items.dart';
import '../pro/pro_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../data/repositories/item_repository.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../kluis/ui/vault_link.dart';

const _newCategoryKey = '__new__';
const _intervals = [1, 3, 6, 12, 24];

/// Detail- en bewerkscherm voor standaard- en eigen items; `id == 'new'` maakt
/// een nieuw eigen item.
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, required this.itemId});
  final String itemId;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _unit = TextEditingController(text: 'stuks');
  final _why = TextEditingController();
  final _notes = TextEditingController();
  final _have = TextEditingController();
  final _override = TextEditingController();
  final _newCat = TextEditingController();

  bool _loaded = false;
  bool _inHouse = false;
  String _category = Cat.other;
  DateTime? _expiry, _lastChecked;
  int? _interval;

  bool get _isNew => widget.itemId == 'new';

  @override
  void dispose() {
    for (final c in [_name, _unit, _why, _notes, _have, _override, _newCat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populate(Item i) {
    _loaded = true;
    _name.text = i.name;
    _unit.text = i.unit;
    _why.text = i.isCustom ? i.why : '';
    _notes.text = i.notes;
    _have.text = i.quantityHave == null ? '' : fmtQty(i.quantityHave!);
    _override.text = i.quantityOverride == null ? '' : fmtQty(i.quantityOverride!);
    _inHouse = i.inHouse;
    _category = i.category;
    _expiry = i.expiryDate;
    _lastChecked = i.lastChecked;
    _interval = i.intervalMonths;
  }

  double? _num(String s) {
    final t = s.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
  }

  String? _numValidator(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final v = _num(s);
    return v == null || v < 0 ? S.invalidNumber : null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30),
      locale: const Locale('nl', 'NL'),
    );
    if (d != null) setState(() => _expiry = dateOnly(d));
  }

  Future<void> _save(bool custom, String id) async {
    if (!_formKey.currentState!.validate()) return;
    final category = _category == _newCategoryKey ? _newCat.text.trim() : _category;
    final interval = _interval;
    // Interval start bij de eerste keer instellen.
    final lastChecked = interval != null
        ? (_lastChecked ?? dateOnly(DateTime.now()))
        : _lastChecked;
    final edit = ItemEdit(
      inHouse: _inHouse,
      quantityHave: _num(_have.text),
      quantityOverride: _num(_override.text),
      expiryDate: _expiry,
      intervalMonths: interval,
      lastChecked: lastChecked,
      notes: _notes.text.trim(),
      name: _name.text.trim(),
      category: category.isEmpty ? Cat.other : category,
      unit: _unit.text.trim().isEmpty ? 'stuks' : _unit.text.trim(),
      why: _why.text.trim(),
    );
    final hasDue = _expiry != null || interval != null;
    await ref.read(itemRepositoryProvider).save(id, edit, custom: custom);
    if (hasDue) await _askPermissionOnce();
    if (mounted) context.pop();
  }

  /// Notificatietoestemming vragen op het moment dat een herinnering ontstaat.
  Future<void> _askPermissionOnce() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    if (settings.permissionAsked) return;
    await ref.read(notificationServiceProvider).requestPermission();
    await ref
        .read(settingsRepositoryProvider)
        .save(settings.copyWith(permissionAsked: true));
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(S.deleteItemTitle),
        content: const Text(S.deleteItemBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text(S.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text(S.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(itemRepositoryProvider).deleteCustom(id);
    if (mounted) context.pop();
  }

  Future<void> _hide(String id) async {
    final repo = ref.read(itemRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.setHidden(id, true);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: const Text(S.itemHidden),
        action: SnackBarAction(
            label: S.undo, onPressed: () => repo.setHidden(id, false)),
      ));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(allItemsProvider);
    Item? item;
    if (!_isNew) {
      item = all.value?.where((i) => i.id == widget.itemId).firstOrNull;
      if (all.hasValue && item == null) {
        return Scaffold(
            appBar: AppBar(), body: const Center(child: Text(S.itemNotFound)));
      }
      if (item == null) {
        return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()));
      }
      if (!_loaded) _populate(item);
    } else {
      _loaded = true;
    }

    final custom = _isNew || item!.isCustom;
    final id = _isNew ? ref.read(itemRepositoryProvider).newCustomId() : item!.id;
    final customCats = {
      for (final i in all.value ?? const <Item>[])
        if (!Cat.standard.contains(i.category)) i.category,
    };
    final catOptions = [...Cat.standard, ...customCats];
    if (!catOptions.contains(_category) && _category != _newCategoryKey) {
      catOptions.add(_category);
    }
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? S.itemNew : (custom ? S.itemEdit : S.itemDetail)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (custom) ...[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: S.fieldName),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? S.requiredField : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: S.fieldCategory),
                items: [
                  for (final c in catOptions)
                    DropdownMenuItem(value: c, child: Text(categoryName(c))),
                  const DropdownMenuItem(
                      value: _newCategoryKey, child: Text(S.catCustom)),
                ],
                onChanged: (v) => setState(() => _category = v ?? Cat.other),
              ),
              if (_category == _newCategoryKey) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newCat,
                  decoration: const InputDecoration(labelText: S.catCustomName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? S.requiredField : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(labelText: S.fieldUnit),
              ),
            ] else ...[
              Text(item!.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(categoryName(item!.category),
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(S.fieldInHouse),
              value: _inHouse,
              onChanged: (v) => setState(() => _inHouse = v),
            ),
            if (!custom)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(S.fieldRecommended),
                subtitle: const Text(S.fieldRecommendedAuto),
                trailing: Text(
                  S.recommendedValue(fmtQty(item!.recommended), item!.unit),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _have,
                  decoration: const InputDecoration(labelText: S.fieldHave),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _numValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _override,
                  decoration: const InputDecoration(labelText: S.fieldOverride),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _numValidator,
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: '${S.fieldExpiry}: '
                  '${_expiry == null ? S.fieldExpiryNone : fmtDate(_expiry!)}',
              excludeSemantics: true,
              onTap: _pickDate,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(S.fieldExpiry),
                subtitle:
                    Text(_expiry == null ? S.fieldExpiryNone : fmtDate(_expiry!)),
                trailing: _expiry == null
                    ? const Icon(Icons.calendar_today_outlined)
                    : IconButton(
                        tooltip: S.clearDate,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _expiry = null),
                      ),
                onTap: _pickDate,
              ),
            ),
            if (!_isNew && _expiry != null)
              Builder(builder: (context) {
                final pro = ref.watch(proUnlockedProvider);
                final on = ref.watch(reminderItemsProvider).contains(widget.itemId);
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(S.remindSwitch),
                  subtitle: Text(on && !pro
                      ? S.remindProOnly
                      : pro
                          ? S.remindSwitchSub
                          : S.remindProOnlySub),
                  value: on,
                  onChanged: (v) => toggleItemReminder(context, ref, widget.itemId, v),
                );
              }),
            DropdownButtonFormField<int?>(
              initialValue: _interval,
              decoration: const InputDecoration(labelText: S.fieldInterval),
              items: [
                const DropdownMenuItem(value: null, child: Text(S.intervalNone)),
                for (final m in {..._intervals, ?_interval})
                  DropdownMenuItem(value: m, child: Text(S.intervalMonths(m))),
              ],
              onChanged: (v) => setState(() => _interval = v),
            ),
            if (!custom && item!.shelfAdvice != null) ...[
              const SizedBox(height: 8),
              Text('${S.shelfAdviceTitle}: ${item!.shelfAdvice}',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              if (item!.suggestedIntervalMonths != null &&
                  _interval != item!.suggestedIntervalMonths)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _interval = item!.suggestedIntervalMonths),
                    child: const Text(S.useAdvice),
                  ),
                ),
            ],
            if (_interval != null && _lastChecked != null) ...[
              const SizedBox(height: 8),
              Text(S.lastChecked(fmtDate(_lastChecked!))),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.check),
                  onPressed: () => setState(
                      () => _lastChecked = dateOnly(DateTime.now())),
                  label: const Text(S.markChecked),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: S.fieldNotes),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            if (!_isNew && const {'id_copies', 'usb'}.contains(id)) ...[
              const SizedBox(height: 16),
              const VaultLinkTile(title: S.vaultOpen),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push('/kluis/instellingen'),
                  icon: const Icon(Icons.ios_share),
                  label: const Text(S.vaultMakeBackup),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (custom)
              TextFormField(
                controller: _why,
                decoration: const InputDecoration(
                    labelText: S.fieldWhy, hintText: S.fieldWhyHint),
                maxLines: 3,
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.whyTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(item!.why),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _save(custom, id),
              child: const Text(S.save),
            ),
            const SizedBox(height: 12),
            if (!_isNew && !custom)
              OutlinedButton(
                  onPressed: () => _hide(id), child: const Text(S.hideItem)),
            if (!_isNew && custom)
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                onPressed: () => _delete(id),
                child: const Text(S.deleteItem),
              ),
          ],
        ),
      ),
    );
  }
}
