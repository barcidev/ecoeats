// Screenshots for visual QA, set in the app's real fonts. Run on purpose:
//
//   fvm flutter test tool/qa/screens_test.dart
//
// It writes PNGs to build/qa/: the design gallery and Discover (with Home and
// a dish's detail around it) in light and dark, Spanish and English. Tests
// have no network, so photos show their designed placeholder.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ecoeats/design/gallery/design_gallery_page.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/widgets/grain_overlay.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/helpers/app_harness.dart';
import '../../test/helpers/dish_fixtures.dart';

final _out = Directory('build/qa');

/// Where a dependency lives on disk, read from the resolved package config.
String _packageRoot(String name) {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final package = (config['packages']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .firstWhere((package) => package['name'] == name);
  final root = Uri.parse(package['rootUri']! as String);
  final path = Directory.fromUri(
    root.isAbsolute ? root : Uri.directory('.dart_tool/').resolveUri(root),
  ).path;
  return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  final phosphor = '${_packageRoot('phosphor_flutter')}/lib/fonts';
  await load('Fraunces', [
    'assets/fonts/Fraunces.ttf',
    'assets/fonts/Fraunces-Italic.ttf',
  ]);
  await load('InstrumentSans', ['assets/fonts/InstrumentSans.ttf']);
  await load('packages/phosphor_flutter/PhosphorLight', [
    '$phosphor/Phosphor-Light.ttf',
  ]);
  await load('packages/phosphor_flutter/PhosphorFill', [
    '$phosphor/Phosphor-Fill.ttf',
  ]);
}

/// Saves the whole screen, the way golden files capture it.
Future<void> _shot(WidgetTester tester, String name) async {
  var boundary = tester.renderObject(find.byType(MaterialApp).first);
  while (!boundary.isRepaintBoundary) {
    boundary = boundary.parent!;
  }
  final layer = boundary.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final image = await layer.toImage(boundary.paintBounds);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    _out.createSync(recursive: true);
    File('${_out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Lets springs, fades and reveals run; spinners and shimmer never stop.
Future<void> _wait(WidgetTester tester, [int frames = 12]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    // The paper grain decodes its tile for real; inside a test's fake time it
    // never would.
    // ignore: invalid_use_of_visible_for_testing_member
    await grainTile();
  });

  for (final locale in AppLocale.values) {
    for (final brightness in Brightness.values) {
      final combo = '${locale.languageCode}-${brightness.name}';

      testWidgets('gallery $combo', (tester) async {
        tester.view.physicalSize = const Size(1179, 2556);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

        await tester.pumpWidget(
          TranslationProvider(
            child: Builder(
              builder: (context) => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ecoTheme(brightness),
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: const DesignGalleryPage(),
              ),
            ),
          ),
        );
        await _wait(tester, 20);

        final list = find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first;
        for (var frame = 1; ; frame++) {
          await _shot(tester, 'gallery-$combo-$frame');
          final position = tester.state<ScrollableState>(list).position;
          if (position.pixels >= position.maxScrollExtent) break;
          position.jumpTo(
            (position.pixels + position.viewportDimension * 0.85).clamp(
              0,
              position.maxScrollExtent,
            ),
          );
          await _wait(tester, 6);
        }
      });
    }

    // Discover is always dark; Home and the detail follow the theme, light
    // here, the device's default in tests.
    final language = locale.languageCode;

    testWidgets('discover $language', (tester) async {
      // A test run on purpose, outside test/: the analyzer cannot tell.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      // Without a URL a photo is its placeholder at once; with one, the
      // image cache would look for a disk that tests do not have.
      final container = await bootApp(
        tester,
        locale: locale,
        dishes: [
          for (final dish in sampleDishes)
            dish.copyWith(image: '', thumbnail: ''),
        ],
      );
      await _shot(tester, 'home-$language');

      final router = container.read(appRouterProvider);
      unawaited(
        router.push(DiscoverRoute(revealOrigin: const Offset(200, 600))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await _shot(tester, 'discover-$language-0-reveal');
      await _wait(tester, 30);
      await _shot(tester, 'discover-$language-1-first');

      final drag = await tester.startGesture(const Offset(200, 500));
      await drag.moveBy(const Offset(0, -280));
      await tester.pump();
      await _shot(tester, 'discover-$language-2-drag');
      // A flick past the page, the way a thumb sends it on.
      await drag.moveBy(const Offset(0, -40));
      await drag.up();
      await tester.fling(find.byType(PageView), const Offset(0, -300), 1500);
      await _wait(tester, 20);
      await _shot(tester, 'discover-$language-3-second');

      await tester.tap(
        find.bySemanticsLabel(RegExp(r'^(Ver plato|See dish)$')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await _shot(tester, 'discover-$language-4-flight');
      await _wait(tester, 20);
      await _shot(tester, 'detail-$language');
    });
  }
}
