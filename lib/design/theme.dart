import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

ThemeData ecoTheme(Brightness brightness) {
  final light = brightness == .light;
  final palette = light ? EcoPalette.mantel : EcoPalette.fogon;
  // Text on achiote and aguacate reads best in the lightest paper of each mode.
  final onAccent = light ? palette.raised : palette.paper;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: palette.achiote,
    onPrimary: onAccent,
    secondary: palette.aguacate,
    onSecondary: onAccent,
    tertiary: palette.maiz,
    onTertiary: light ? palette.ink : palette.paper,
    error: palette.achiote,
    onError: onAccent,
    surface: palette.paper,
    onSurface: palette.ink,
    onSurfaceVariant: palette.muted,
    surfaceContainerLowest: palette.paper,
    surfaceContainerLow: palette.raised,
    surfaceContainer: palette.raised,
    surfaceContainerHigh: palette.raised,
    surfaceContainerHighest: palette.raised,
    outline: palette.line,
    outlineVariant: palette.line,
    surfaceTint: Colors.transparent,
  );

  final textTheme = const TextTheme(
    displayLarge: EcoType.display,
    headlineMedium: EcoType.headline,
    headlineSmall: EcoType.title,
    titleLarge: EcoType.title,
    titleMedium: EcoType.titleSmall,
    bodyLarge: EcoType.body,
    bodyMedium: EcoType.bodySmall,
    labelLarge: EcoType.label,
    labelSmall: EcoType.overline,
  ).apply(bodyColor: palette.ink, displayColor: palette.ink);

  final overlay = light
      ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
      : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent);

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    textTheme: textTheme,
    fontFamily: EcoFonts.text,
    scaffoldBackgroundColor: palette.paper,
    canvasColor: palette.paper,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    dividerTheme: DividerThemeData(
      color: palette.line,
      thickness: Space.hairline,
      space: Space.hairline,
    ),
    iconTheme: IconThemeData(color: palette.ink, size: 22),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.achiote,
      selectionColor: palette.achiote.withValues(alpha: 0.24),
      selectionHandleColor: palette.achiote,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.paper,
      foregroundColor: palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: overlay,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.raised,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: palette.line,
      shape: const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: .circular(Radii.lg)),
      ),
    ),
    extensions: [palette],
  );
}
