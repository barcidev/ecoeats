import 'dart:ui' as ui;

import 'package:ecoeats/core/format/formatters.dart';
import 'package:ecoeats/core/session/session_controller.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/features/dishes/presentation/home/home_greeting.dart';
import 'package:ecoeats/features/profile/presentation/profile_sheet.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _searchBarHeight = 64.0;

/// Home's masthead: date, greeting and headline at full size, folding into a
/// blurred bar that keeps the avatar and the search while the menu scrolls.
class HomeHeader extends ConsumerWidget {
  const new({
    required this.search,
    required this.onSearchChanged,
    required this.onSearchCleared,
    super.key,
  });

  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final now = ref.watch(clockProvider)();
    final session = ref.watch(sessionControllerProvider).value;
    final language = t.$meta.locale.languageCode;
    // The greeting may wrap to two lines; the header grows with the text size.
    final masthead = MediaQuery.textScalerOf(context).scale(104);

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: kToolbarHeight + masthead + _searchBarHeight,
      flexibleSpace: _Masthead(
        date: Formatters(language).date(now),
        greeting: greetingFor(t, now, session?.firstNames),
        headline: headlineFor(t, now),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: Space.gutter),
          child: _Avatar(
            initial: (session?.firstNames ?? session?.email ?? '?')
                .trim()
                .characters
                .first
                .toUpperCase(),
            label: t.dishes.header.profile,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_searchBarHeight),
        child: _SearchField(
          controller: search,
          hint: t.dishes.header.search,
          clearLabel: t.dishes.header.clearSearch,
          onChanged: onSearchChanged,
          onCleared: onSearchCleared,
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const new({
    required this.date,
    required this.greeting,
    required this.headline,
  });

  final String date;
  final String greeting;
  final String headline;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final collapsed = (settings?.minExtent ?? 0) + 0.0;
    final expanded = (settings?.maxExtent ?? 1) + 0.0;
    final current = (settings?.currentExtent ?? expanded) + 0.0;
    // 0 while the masthead is open, 1 once it is folded into the bar.
    final folded = expanded == collapsed
        ? 1.0
        : ((expanded - current) / (expanded - collapsed)).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 20 * folded,
              sigmaY: 20 * folded,
            ),
            child: ColoredBox(
              color: palette.paper.withValues(alpha: 1 - 0.22 * folded),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: Space.hairline,
            color: palette.line.withValues(alpha: folded),
          ),
        ),
        Positioned(
          top: top,
          left: Space.gutter,
          right: Space.gutter + 48,
          height: kToolbarHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (folded < 1)
                Opacity(
                  opacity: 1 - folded,
                  child: Text(
                    date,
                    style: EcoType.overline.copyWith(color: palette.muted),
                  ),
                ),
              if (folded > 0)
                Opacity(
                  opacity: folded,
                  child: Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: EcoType.titleSmall.copyWith(color: palette.ink),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: top + kToolbarHeight,
          left: Space.gutter,
          right: Space.gutter,
          bottom: _searchBarHeight,
          child: Opacity(
            opacity: (1 - folded * 1.6).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -Space.md * folded),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      greeting,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: EcoType.headline.copyWith(color: palette.ink),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: EcoType.body.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const new({required this.initial, required this.label});

  final String initial;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Pressable(
      semanticLabel: label,
      onPressed: () => ProfileSheet.show(context),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: palette.raised,
          shape: CircleBorder(side: BorderSide(color: palette.line)),
        ),
        child: Text(
          initial,
          style: EcoType.title.copyWith(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: palette.ink,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const new({
    required this.controller,
    required this.hint,
    required this.clearLabel,
    required this.onChanged,
    required this.onCleared,
  });

  final TextEditingController controller;
  final String hint;
  final String clearLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.xs,
        Space.gutter,
        Space.xs,
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.only(left: Space.md, right: Space.xxs),
        decoration: ShapeDecoration(
          color: palette.raised,
          shape: StadiumBorder(side: BorderSide(color: palette.line)),
        ),
        child: Row(
          children: [
            Icon(EcoIcons.magnifyingGlass, size: 20, color: palette.muted),
            const SizedBox(width: Space.sm),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: EcoType.body.copyWith(color: palette.ink),
                cursorColor: palette.achiote,
                decoration: InputDecoration.collapsed(
                  hintText: hint,
                  hintStyle: EcoType.body.copyWith(color: palette.muted),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) => AnimatedOpacity(
                opacity: value.text.isEmpty ? 0 : 1,
                duration: Motion.quick,
                child: IgnorePointer(
                  ignoring: value.text.isEmpty,
                  child: Pressable(
                    semanticLabel: clearLabel,
                    onPressed: onCleared,
                    child: Padding(
                      padding: const EdgeInsets.all(Space.sm),
                      child: Icon(EcoIcons.x, size: 18, color: palette.muted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
