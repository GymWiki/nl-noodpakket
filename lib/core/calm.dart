import 'package:flutter/material.dart';

import 'theme.dart';
import 'theme/category_palette.dart';
import 'ui.dart';

/// Rustige bouwstenen. Regels (zie DRUKTE_AUDIT.md):
///  - 16 dp schermmarge, 24 dp tussen secties, 8 tot 12 dp binnen een groep;
///  - gelijksoortige items staan in één vlak met dunne scheidingslijnen, geen kaart per item;
///  - maximaal drie lettergroottes per scherm: titel, lopende tekst, bijschrift;
///  - kaarten alleen voor iets met een eigen taak (Paraatheid, een actieve waarschuwing).
class Space {
  Space._();
  static const screen = 16.0, section = 24.0, group = 12.0, tight = 8.0;

  /// Breedte van de inhoud op brede schermen (tablets), zodat regels leesbaar blijven.
  static const maxContent = 640.0;
}

/// Scherm met vaste marges en één kolom (max. [Space.maxContent] breed, gecentreerd).
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.children,
    this.floatingActionButton,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(Space.screen, Gap.s, Space.screen, Gap.xl),
  });

  final List<Widget> children;
  final Widget? floatingActionButton;

  /// Bijvoorbeeld een [PrimaryActionBar].
  final Widget? bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottom,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Space.maxContent),
              child: ListView(padding: padding, children: children),
            ),
          ),
        ),
      );
}

/// Kop + inhoud met vaste ruimte erboven (24 dp) en onder de kop (8 dp).
class CalmSection extends StatelessWidget {
  const CalmSection({super.key, this.title, required this.child, this.trailing, this.first = false});
  final String? title;
  final Widget child;
  final Widget? trailing;

  /// Eerste sectie van een scherm: geen extra ruimte erboven.
  final bool first;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null)
          SectionHeader(title!,
              trailing: trailing,
              padding: EdgeInsets.only(top: first ? 0 : Space.section, bottom: Space.tight))
        else
          SizedBox(height: first ? 0 : Space.section),
        child,
      ]);
}

/// Eén tonaal vlak met rijen en dunne scheidingslijnen (in plaats van een kaart per rij).
class CalmListGroup extends StatelessWidget {
  const CalmListGroup({super.key, required this.children, this.color});
  final List<Widget> children;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Material(
      color: color ?? c.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: Space.screen, endIndent: Space.screen, color: c.outlineVariant),
          children[i],
        ],
      ]),
    );
  }
}

/// Rij in een [CalmListGroup]: pictogram, titel, bijschrift en pijltje. Minimaal 56 dp hoog.
class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.tint,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.subtitleColor,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final CategoryTint? tint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.screen, vertical: Space.group),
        child: Row(children: [
          if (icon != null) ...[
            IconBadge(icon!, size: 40, tint: tint),
            const SizedBox(width: Space.group),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
              if (subtitle != null)
                Text(subtitle!,
                    style: t.textTheme.bodyMedium?.copyWith(color: subtitleColor ?? c.onSurfaceVariant)),
            ]),
          ),
          trailing ?? (onTap == null ? const SizedBox.shrink() : Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant)),
        ]),
      ),
    );
    final tappable = onTap == null ? row : InkWell(onTap: onTap, child: row);
    if (semanticLabel == null) return tappable;
    return Semantics(label: semanticLabel, button: onTap != null, excludeSemantics: true, child: tappable);
  }
}

/// Inklapbare sectie ("Toon meer"). Nooit voor veiligheidsinformatie.
class ExpandableSection extends StatelessWidget {
  const ExpandableSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: t.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(Radii.card),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: t.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          title: Text(title, style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
          subtitle: subtitle == null ? null : Text(subtitle!),
          tilePadding: const EdgeInsets.symmetric(horizontal: Space.screen),
          childrenPadding: const EdgeInsets.fromLTRB(Space.screen, 0, Space.screen, Space.group),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Balk onderaan met één primaire actie (en eventueel één rustige tweede).
class PrimaryActionBar extends StatelessWidget {
  const PrimaryActionBar({super.key, required this.label, required this.onPressed, this.secondary});
  final String label;
  final VoidCallback? onPressed;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.screen, Space.tight, Space.screen, Space.group),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FilledButton(onPressed: onPressed, child: Text(label)),
            ?secondary,
          ]),
        ),
      );
}
