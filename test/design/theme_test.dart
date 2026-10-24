import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final (brightness, palette) in [
    (Brightness.light, EcoPalette.mantel),
    (Brightness.dark, EcoPalette.fogon),
  ]) {
    group('${brightness.name} theme', () {
      final theme = ecoTheme(brightness);

      test('carries its palette', () {
        expect(theme.brightness, brightness);
        expect(theme.extension<EcoPalette>(), palette);
        expect(theme.colorScheme.primary, palette.achiote);
        expect(theme.colorScheme.surface, palette.paper);
        expect(theme.colorScheme.onSurface, palette.ink);
      });

      test('has no ripples', () {
        expect(theme.splashFactory, NoSplash.splashFactory);
      });

      test('paints on paper with hairline dividers', () {
        expect(theme.scaffoldBackgroundColor, palette.paper);
        expect(theme.dividerTheme.color, palette.line);
        expect(theme.dividerTheme.thickness, 1);
      });

      test('uses Fraunces for headings and Instrument Sans for text', () {
        final text = theme.textTheme;
        expect(text.displayLarge!.fontFamily, EcoFonts.display);
        expect(text.headlineMedium!.fontFamily, EcoFonts.display);
        expect(text.bodyLarge!.fontFamily, EcoFonts.text);
        expect(text.bodyLarge!.fontSize, 16);
        expect(text.bodyLarge!.color, palette.ink);
        expect(text.labelSmall!.letterSpacing, 1.4);
      });
    });
  }

  testWidgets('context.palette follows the active theme', (tester) async {
    late EcoPalette seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: ecoTheme(Brightness.light),
        darkTheme: ecoTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            seen = context.palette;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, EcoPalette.fogon);
  });
}
