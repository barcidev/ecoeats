import 'package:ecoeats/design/gallery/design_gallery_page.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app() => TranslationProvider(
  child: Builder(
    builder: (context) => MaterialApp(
      theme: ecoTheme(.light),
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DesignGalleryPage(),
                ),
              ),
              child: const Text('gallery'),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The gallery keeps spinners and shimmer going, so it never settles.
Future<void> _wait(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openGallery(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.tap(find.text('gallery'));
  await _wait(tester);
}

/// The gallery's own vertical list, not one of the pill rows inside it.
final Finder _sections = find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

Color _background(WidgetTester tester) => tester
    .widget<Scaffold>(
      find.descendant(
        of: find.byType(DesignGalleryPage),
        matching: find.byType(Scaffold),
      ),
    )
    .backgroundColor!;

void main() {
  setUp(() async {
    // English is a deferred library: load both before any switch.
    await AppLocale.en.build();
    await LocaleSettings.setLocale(AppLocale.es);
  });

  testWidgets('it shows every section', (tester) async {
    await _openGallery(tester);
    final list = _sections;
    for (final section in [
      'TYPE',
      'BUTTONS',
      'FIELDS',
      'SELECTION',
      'FEEDBACK',
      'MEDIA',
      'LOADING',
      'DRAWINGS',
      'STATES',
      'MOTION',
      'PAPER',
    ]) {
      await tester.scrollUntilVisible(
        find.text(section),
        300,
        scrollable: list,
      );
      expect(find.text(section), findsOneWidget, reason: section);
    }
  });

  testWidgets('it switches language and theme on the spot', (tester) async {
    await _openGallery(tester);
    expect(find.text('Comida colombiana, sin afán.'), findsOneWidget);
    expect(_background(tester), EcoPalette.mantel.paper);

    await tester.tap(find.text('English'));
    await _wait(tester);
    expect(find.text('Colombian food, unhurried.'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await _wait(tester);
    expect(_background(tester), EcoPalette.fogon.paper);
  });

  for (final locale in AppLocale.values) {
    for (final dark in [false, true]) {
      testWidgets('it renders in ${locale.name}, ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await _openGallery(tester);
        if (dark) {
          await tester.tap(
            find.text(locale == AppLocale.es ? 'Oscuro' : 'Dark'),
          );
          await _wait(tester);
        }
        final list = _sections;
        await tester.scrollUntilVisible(
          find.text('PAPER'),
          400,
          scrollable: list,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('it puts the language back when it closes', (tester) async {
    await _openGallery(tester);
    await tester.tap(find.text('English'));
    await _wait(tester);
    expect(LocaleSettings.currentLocale, AppLocale.en);

    Navigator.of(tester.element(find.byType(DesignGalleryPage))).pop();
    await _wait(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await _wait(tester);
    expect(LocaleSettings.currentLocale, AppLocale.es);
  });
}
