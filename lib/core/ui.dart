import 'package:flutter/material.dart';

import 'theme.dart';
import 'theme/category_palette.dart';

/// Rustig vlak: witte (of donkere) kaart met subtiele rand, optioneel tikbaar.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(Gap.m),
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final card = Material(
      color: color ?? c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: borderColor ?? c.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
    if (semanticLabel == null) return card;
    return Semantics(label: semanticLabel, button: onTap != null, excludeSemantics: true, child: card);
  }
}

/// Ronde pictogram-badge in een zachte tint.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 44, this.background, this.foreground, this.tint});
  final IconData icon;
  final double size;
  final Color? background, foreground;

  /// Categoriekleur voor het bolletje; kleur is alleen een extra aanwijzing,
  /// het icoon en de tekst ernaast blijven de betekenis dragen.
  final CategoryTint? tint;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final tone = tint?.tone(Theme.of(context).brightness);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? tone?.bubble ?? c.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.5, color: foreground ?? tone?.icon ?? c.onPrimaryContainer),
      ),
    );
  }
}

/// Voortgangsring met inhoud in het midden.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 96, this.stroke = 10, this.child});
  final double value;
  final double size, stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value.clamp(0.0, 1.0)),
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => CircularProgressIndicator(
              value: v,
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              backgroundColor: c.surfaceContainerHigh,
              color: c.secondary,
            ),
          ),
        ),
        ?child,
      ]),
    );
  }
}

/// Kop van een sectie met optioneel iets aan de rechterkant.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.leading, this.trailing, this.padding = const EdgeInsets.only(top: Gap.l, bottom: Gap.s)});
  final String title;
  final Widget? leading, trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(child: Semantics(header: true, child: Text(title, style: t.textTheme.titleMedium))),
        ?trailing,
      ]),
    );
  }
}

/// Pagina-titel in grote letters (in plaats van een zware app-balk).
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Gap.s, bottom: Gap.m),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text(title, style: t.textTheme.headlineLarge)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

/// Dunne accentlijn boven een titel in detailschermen (decoratief, niet voorgelezen).
class TintAccentLine extends StatelessWidget {
  const TintAccentLine(this.tint, {super.key});
  final CategoryTint tint;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: tint.tone(Theme.of(context).brightness).accent,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        ),
      );
}
