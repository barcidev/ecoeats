import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/core/network/error_mapper.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/state_view.dart';
import 'package:ecoeats/features/discover/application/discover_hint.dart';
import 'package:ecoeats/features/discover/presentation/discover_chrome.dart';
import 'package:ecoeats/features/discover/presentation/discover_slide.dart';
import 'package:ecoeats/features/dishes/application/catalog_views.dart';
import 'package:ecoeats/features/dishes/application/dishes_provider.dart';
import 'package:ecoeats/features/dishes/domain/dish.dart';
import 'package:ecoeats/i18n/failure_text.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:ecoeats/router/app_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The menu one dish at a time, full screen, swiping up. It walks what
/// Home's filter, search and order leave visible.
@RoutePage()
class DiscoverPage extends ConsumerStatefulWidget {
  const new({this.revealOrigin, super.key});

  /// Where the circular reveal starts; the route reads it from the page
  /// arguments.
  final Offset? revealOrigin;

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _pager = PageController();

  /// The visible list as it was when Discover first had it: a refresh in the
  /// background never reorders the pages under the finger.
  List<Dish>? _dishes;

  /// The page the pager last came to rest on.
  var _settled = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  bool _onScrollEnd(ScrollEndNotification notification) {
    final page = _pager.page?.round() ?? _settled;
    if (page != _settled) {
      setState(() => _settled = page);
      unawaited(HapticFeedback.lightImpact());
      unawaited(ref.read(discoverHintProvider.notifier).dismiss());
    }
    return false;
  }

  void _open(Dish dish) => unawaited(
    context.router.push(
      DishDetailRoute(id: dish.id, initial: dish, heroSource: .discover),
    ),
  );

  void _close() => unawaited(context.router.maybePop());

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final visible = ref.watch(visibleDishesProvider);
    final dishes = _dishes ??= visible.value;
    final showHint = ref.watch(discoverHintProvider).value ?? false;
    final padding = MediaQuery.paddingOf(context);

    final Widget content;
    if (dishes == null) {
      final error = visible.error;
      if (error == null) {
        content = Center(
          child: PlateSpinner(size: 32, color: EcoPalette.fogon.ink),
        );
      } else {
        final copy = failureCopy(toFailure(error), t);
        content = StateView(
          kind: .error,
          title: copy.title,
          message: copy.message,
          footnote: copy.reference,
          actionLabel: t.common.actions.retry,
          onAction: () => ref.invalidate(dishesProvider),
        );
      }
    } else if (dishes.isEmpty) {
      content = StateView(
        kind: .empty,
        title: t.discover.empty.title,
        message: t.discover.empty.message,
        actionLabel: t.common.actions.back,
        onAction: _close,
      );
    } else {
      content = NotificationListener<ScrollEndNotification>(
        onNotification: _onScrollEnd,
        child: PageView.builder(
          controller: _pager,
          scrollDirection: .vertical,
          // Builds the next page offstage, so its photo is already loading.
          allowImplicitScrolling: true,
          itemCount: dishes.length,
          itemBuilder: (context, index) => DiscoverSlide(
            key: ValueKey(dishes[index].id),
            dish: dishes[index],
            index: index,
            pager: _pager,
            active: index == _settled,
            onOpen: () => _open(dishes[index]),
          ),
        ),
      );
    }

    final walking = dishes != null && dishes.isNotEmpty;
    // Discover is a dark room whatever the app's theme: photos read best
    // there, and its chrome is light.
    return Theme(
      data: ecoTheme(.dark),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: EcoPalette.fogon.paper,
          body: Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (walking) ...[
                Positioned(
                  top: padding.top + Space.md,
                  left: Space.gutter,
                  child: DiscoverCounter(pager: _pager, count: dishes.length),
                ),
                Positioned(
                  right: Space.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: DiscoverRail(pager: _pager, count: dishes.length),
                  ),
                ),
              ],
              Positioned(
                top: padding.top + Space.xxs,
                right: Space.xs,
                child: DiscoverClose(onPressed: _close),
              ),
              if (walking && showHint && dishes.length > 1)
                Positioned(
                  left: Space.gutter,
                  right: Space.gutter,
                  bottom: padding.bottom + Space.xl,
                  child: Center(
                    child: DiscoverHintBubble(
                      onDismiss: () => unawaited(
                        ref.read(discoverHintProvider.notifier).dismiss(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
