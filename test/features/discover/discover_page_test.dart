import 'dart:async';

import 'package:ecoeats/design/widgets/dish_image.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/features/discover/presentation/discover_chrome.dart';
import 'package:ecoeats/features/discover/presentation/discover_page.dart';
import 'package:ecoeats/features/discover/presentation/discover_slide.dart';
import 'package:ecoeats/features/dishes/application/catalog_filter.dart';
import 'package:ecoeats/features/dishes/application/catalog_views.dart';
import 'package:ecoeats/features/dishes/domain/dish_filter.dart';
import 'package:ecoeats/features/dishes/presentation/detail/dish_detail_page.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_harness.dart';

const _hint = 'Desliza hacia arriba para ver el siguiente.';

/// Discover never settles while a photo drifts, so time moves by hand.
Future<void> _wait(WidgetTester tester, [int frames = 12]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ProviderContainer> _openDiscover(
  WidgetTester tester, {
  bool hintSeen = true,
  void Function(ProviderContainer container)? before,
}) async {
  SharedPreferences.setMockInitialValues({
    if (hintSeen) 'discover.hintSeen': true,
  });
  final container = await bootApp(tester);
  before?.call(container);
  await tester.pump();
  unawaited(container.read(appRouterProvider).push(DiscoverRoute()));
  await _wait(tester);
  return container;
}

List<String> _recordHaptics(WidgetTester tester) {
  final haptics = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return haptics;
}

Future<void> _swipeUp(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(0, -400), 1500);
  await _wait(tester);
}

Iterable<Transform> _transformsIn(WidgetTester tester, Finder scope) =>
    tester.widgetList<Transform>(
      find.descendant(of: scope, matching: find.byType(Transform)),
    );

void main() {
  testWidgets('it opens on the first visible dish with its counter', (
    tester,
  ) async {
    final container = await _openDiscover(tester);
    final first = container.read(visibleDishesProvider).value!.first;

    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(find.text('01 / 12'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^${RegExp.escape(first.name)}\\.')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Ver plato'), findsOneWidget);
    expect(find.bySemanticsLabel('Cerrar'), findsOneWidget);
  });

  testWidgets('it walks only what Home leaves visible', (tester) async {
    await _openDiscover(
      tester,
      before: (container) => container
          .read(catalogFilterProvider.notifier)
          .select(DishCategory.featured),
    );
    expect(find.text('01 / 04'), findsOneWidget);
  });

  testWidgets('a swipe up settles on the next dish with one tick', (
    tester,
  ) async {
    final haptics = _recordHaptics(tester);
    await _openDiscover(tester);
    await _swipeUp(tester);
    expect(find.text('02 / 12'), findsOneWidget);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('the next photo is already on its way', (tester) async {
    await _openDiscover(tester);
    expect(
      find.byType(DiscoverSlide, skipOffstage: false),
      findsAtLeastNWidgets(2),
    );
    expect(
      find.descendant(
        of: find.byType(DiscoverSlide, skipOffstage: false).at(1),
        matching: find.byType(DishImage, skipOffstage: false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the active photo pushes in and the words lead the drag', (
    tester,
  ) async {
    await _openDiscover(tester);
    await _wait(tester, 30);
    final active = find.byType(DiscoverSlide).first;
    expect(
      _transformsIn(
        tester,
        active,
      ).any((transform) => transform.transform.entry(0, 0) > 1.1),
      isTrue,
    );

    final drag = await tester.startGesture(tester.getCenter(active));
    await drag.moveBy(const Offset(0, -150));
    await tester.pump();
    // The words move farther than the page itself.
    final moved = _transformsIn(
      tester,
      active,
    ).where((transform) => transform.transform.getTranslation().y < -1);
    expect(moved, isNotEmpty);
    await drag.up();
    await _wait(tester);
  });

  testWidgets('the first time it hints to swipe, and never again', (
    tester,
  ) async {
    final container = await _openDiscover(tester, hintSeen: false);
    expect(find.text(_hint), findsOneWidget);

    await _swipeUp(tester);
    expect(find.text(_hint), findsNothing);

    unawaited(container.read(appRouterProvider).maybePop());
    await _wait(tester);
    unawaited(container.read(appRouterProvider).push(DiscoverRoute()));
    await _wait(tester);
    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(find.text(_hint), findsNothing);
  });

  testWidgets('the hint stays off «Ver plato», whose first tap opens it', (
    tester,
  ) async {
    await _openDiscover(tester, hintSeen: false);
    final hint = tester.getRect(find.byType(DiscoverHintBubble));
    final button = tester.getRect(
      find.ancestor(
        of: find.text('Ver plato'),
        matching: find.byType(Pressable),
      ),
    );
    expect(hint.overlaps(button), isFalse);

    await tester.tap(find.text('Ver plato'));
    await _wait(tester);
    expect(find.byType(DishDetailPage), findsOneWidget);
  });

  testWidgets('a swipe that starts on the hint still turns the page', (
    tester,
  ) async {
    await _openDiscover(tester, hintSeen: false);
    await tester.flingFrom(
      tester.getCenter(find.byType(DiscoverHintBubble)),
      const Offset(0, -400),
      1500,
    );
    await _wait(tester);
    expect(find.text('02 / 12'), findsOneWidget);
    expect(find.text(_hint), findsNothing);
  });

  testWidgets('tapping the hint hides it', (tester) async {
    await _openDiscover(tester, hintSeen: false);
    await tester.tap(find.text(_hint));
    await _wait(tester);
    expect(find.text(_hint), findsNothing);
  });

  testWidgets('«Ver plato» flies the dish into its detail', (tester) async {
    final container = await _openDiscover(tester);
    final first = container.read(visibleDishesProvider).value!.first;
    await tester.tap(find.bySemanticsLabel('Ver plato'));
    await _wait(tester);
    expect(find.byType(DishDetailPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DishDetailPage),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Hero && widget.tag == 'dish-${first.id}-discover',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('with nothing visible it says so and offers a way back', (
    tester,
  ) async {
    await _openDiscover(
      tester,
      before: (container) =>
          container.read(catalogFilterProvider.notifier).search('pizza'),
    );
    expect(find.text('Nada que descubrir por ahora.'), findsOneWidget);
    await tester.tap(find.text('Volver'));
    await _wait(tester);
    expect(find.byType(DiscoverPage), findsNothing);
  });

  testWidgets('with reduced motion it holds still and still works', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final haptics = _recordHaptics(tester);
    await _openDiscover(tester);
    await tester.pumpAndSettle();

    final active = find.byType(DiscoverSlide).first;
    bool still(Transform transform) =>
        transform.transform.entry(0, 0) == 1 &&
        transform.transform.getTranslation().y == 0;
    expect(_transformsIn(tester, active).every(still), isTrue);

    final drag = await tester.startGesture(tester.getCenter(active));
    await drag.moveBy(const Offset(0, -150));
    await tester.pump();
    expect(_transformsIn(tester, active).every(still), isTrue);
    await drag.up();
    await tester.pumpAndSettle();

    await _swipeUp(tester);
    await tester.pumpAndSettle();
    expect(find.text('02 / 12'), findsOneWidget);
    expect(haptics, contains('HapticFeedbackType.lightImpact'));

    await tester.tap(find.bySemanticsLabel('Ver plato'));
    await tester.pumpAndSettle();
    expect(find.byType(DishDetailPage), findsOneWidget);
  });
}
