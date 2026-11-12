import 'package:flutter/material.dart';

/// Ontwerpsysteem "Rustig helder":
///  - kleur: diep blauw als anker, saliegroen voor "in huis / goed", warm zand
///    als zacht accent; alarmrood alleen voor echt verlopen;
///  - vorm: grote afgeronde vlakken (20 dp), geen schaduwen, subtiele lijnen;
///  - typografie: één lettertype (Roboto, meegeleverd), grote duidelijke koppen;
///  - ritme: 4/8 dp, royale witruimte, grote tikdoelen (min. 48 dp).
class AppColors {
  AppColors._();

  // Licht
  static const lightBg = Color(0xFFF4F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF0B5C8F);
  static const lightPrimaryContainer = Color(0xFFD9EDF9);
  static const lightGreen = Color(0xFF2B7566); // "in huis" (4.9:1 op wit)
  static const lightGreenContainer = Color(0xFFDDF1EB);
  static const lightSand = Color(0xFFFCEBD3);
  static const lightOnSand = Color(0xFF6B3A06);
  static const lightLine = Color(0xFFDDE4EB);
  static const lightText = Color(0xFF0F1B26);
  static const lightTextMuted = Color(0xFF51606E);

  // Donker
  static const darkBg = Color(0xFF0B121B);
  static const darkSurface = Color(0xFF141D29);
  static const darkPrimary = Color(0xFF8FCBF2);
  static const darkPrimaryContainer = Color(0xFF123F5B);
  static const darkGreen = Color(0xFF7FD1BE);
  static const darkGreenContainer = Color(0xFF173B34);
  static const darkSand = Color(0xFF45301A);
  static const darkOnSand = Color(0xFFF6D9B0);
  static const darkLine = Color(0xFF263344);
  static const darkText = Color(0xFFEAF0F6);
  static const darkTextMuted = Color(0xFFA6B3C0);
}

/// Ruimtes en radii (4/8-ritme).
class Gap {
  Gap._();
  static const xs = 4.0, s = 8.0, m = 16.0, l = 24.0, xl = 32.0, xxl = 48.0;
  static const page = EdgeInsets.fromLTRB(16, 8, 16, 32);
}

class Radii {
  Radii._();
  static const card = 20.0, control = 16.0, pill = 999.0;
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? AppColors.darkBg : AppColors.lightBg;
  final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
  final line = dark ? AppColors.darkLine : AppColors.lightLine;
  final text = dark ? AppColors.darkText : AppColors.lightText;
  final muted = dark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  final primary = dark ? AppColors.darkPrimary : AppColors.lightPrimary;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: dark ? const Color(0xFF06293F) : Colors.white,
    primaryContainer: dark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
    onPrimaryContainer: dark ? const Color(0xFFD3ECFB) : const Color(0xFF06344F),
    secondary: dark ? AppColors.darkGreen : AppColors.lightGreen,
    onSecondary: dark ? const Color(0xFF0A2A24) : Colors.white,
    secondaryContainer: dark ? AppColors.darkGreenContainer : AppColors.lightGreenContainer,
    onSecondaryContainer: dark ? const Color(0xFFCDEFE6) : const Color(0xFF0C3A31),
    tertiary: dark ? AppColors.darkOnSand : AppColors.lightOnSand,
    onTertiary: dark ? const Color(0xFF3A2610) : Colors.white,
    tertiaryContainer: dark ? AppColors.darkSand : AppColors.lightSand,
    onTertiaryContainer: dark ? AppColors.darkOnSand : AppColors.lightOnSand,
    error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
    onError: dark ? const Color(0xFF690005) : Colors.white,
    errorContainer: dark ? const Color(0xFF5C1A15) : const Color(0xFFF9DEDC),
    onErrorContainer: dark ? const Color(0xFFFFDAD6) : const Color(0xFF410E0B),
    surface: bg,
    onSurface: text,
    onSurfaceVariant: muted,
    outline: muted,
    outlineVariant: line,
    surfaceContainerLowest: surface,
    surfaceContainerLow: surface,
    surfaceContainer: surface,
    surfaceContainerHigh: dark ? const Color(0xFF1B2636) : const Color(0xFFEBF0F5),
    surfaceContainerHighest: dark ? const Color(0xFF223042) : const Color(0xFFE3EAF1),
    inverseSurface: dark ? const Color(0xFFEAF0F6) : const Color(0xFF1D2935),
    onInverseSurface: dark ? const Color(0xFF0F1B26) : const Color(0xFFF1F5F9),
    inversePrimary: dark ? AppColors.lightPrimary : AppColors.darkPrimary,
    scrim: Colors.black,
  );

  final base = ThemeData(brightness: brightness, fontFamily: 'Roboto', useMaterial3: true);
  final t = base.textTheme.apply(bodyColor: text, displayColor: text);
  final textTheme = t.copyWith(
    headlineLarge: t.headlineLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.5),
    headlineMedium: t.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3),
    headlineSmall: t.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25),
    titleLarge: t.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
    titleMedium: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
    titleSmall: t.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
    bodyLarge: t.bodyLarge?.copyWith(fontSize: 17, height: 1.5),
    bodyMedium: t.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
    bodySmall: t.bodySmall?.copyWith(fontSize: 13, height: 1.45, color: muted),
    labelLarge: t.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
  );

  RoundedRectangleBorder shape(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    textTheme: textTheme,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      toolbarHeight: 64,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: line),
      ),
    ),
    dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: primary,
      titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: muted),
      minVerticalPadding: 10,
      shape: shape(Radii.control),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      hintStyle: TextStyle(color: muted),
      labelStyle: TextStyle(color: muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        shape: shape(Radii.control),
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 56),
        shape: shape(Radii.control),
        side: BorderSide(color: line, width: 1.5),
        foregroundColor: primary,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape(Radii.control),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      highlightElevation: 3,
      extendedTextStyle: textTheme.labelLarge,
      shape: shape(Radii.control + 4),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: line),
      labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      showCheckmark: true,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: BorderSide(color: line),
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        textStyle: textTheme.labelLarge,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      side: BorderSide(color: muted, width: 2),
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? scheme.secondary : Colors.transparent),
      checkColor: WidgetStatePropertyAll(scheme.onSecondary),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: const VisualDensity(horizontal: 2, vertical: 2),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStatePropertyAll(line),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.secondary,
      linearTrackColor: scheme.surfaceContainerHigh,
      circularTrackColor: scheme.surfaceContainerHigh,
      linearMinHeight: 10,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 13,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? text : muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: 26,
            color: s.contains(WidgetState.selected) ? scheme.onPrimaryContainer : muted,
          )),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: shape(28),
      titleTextStyle: textTheme.headlineSmall,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shape(Radii.control),
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 15),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
  );
}
