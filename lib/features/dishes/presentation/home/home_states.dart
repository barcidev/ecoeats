import 'package:ecoeats/core/network/app_failure.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/widgets/skeleton.dart';
import 'package:ecoeats/design/widgets/state_view.dart';
import 'package:ecoeats/i18n/failure_text.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:material_ui/material_ui.dart';

/// «0:42»: what is left of a cooldown, the way a kitchen timer shows it.
String formatCountdown(Duration remaining) {
  final seconds = remaining.inSeconds.clamp(0, 359999);
  final minutes = seconds ~/ 60;
  return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Home while the menu first loads, drawn with the shapes of what is coming:
/// the featured card, its dots, the banner, the pills and the first rows.
class HomeSkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.only(top: Space.lg),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Skeleton(width: 96, height: 12),
          ),
          const SizedBox(height: Space.md),
          Center(
            child: Skeleton(
              width: width * 0.78 - Space.md,
              height: width * 0.78 * 5 / 4,
              radius: Radii.lg,
            ),
          ),
          const SizedBox(height: Space.md),
          const Center(child: Skeleton(width: 56, height: 6)),
          const SizedBox(height: Space.xl),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Skeleton(height: 112, radius: Radii.lg),
          ),
          const SizedBox(height: Space.xl),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Row(
              spacing: Space.xs,
              children: [
                Skeleton(width: 72, height: 36, radius: 18),
                Skeleton(width: 108, height: 36, radius: 18),
                Skeleton(width: 132, height: 36, radius: 18),
              ],
            ),
          ),
          for (var row = 0; row < 3; row++)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Space.gutter,
                Space.lg,
                Space.gutter,
                0,
              ),
              child: Row(
                children: [
                  Skeleton(width: 72, height: 72),
                  SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Skeleton(width: 160, height: 16),
                        SizedBox(height: Space.xs),
                        Skeleton(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The menu could not load at all: say why in the app's words and offer a
/// retry, after the wait a 429 asks for.
class HomeFailure extends StatelessWidget {
  const new({required this.failure, required this.onRetry, super.key});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final copy = failureCopy(failure, t);
    return StateView(
      kind: switch (failure) {
        OfflineFailure() || TimeoutFailure() => .offline,
        RateLimitedFailure() => .rateLimited,
        _ => .error,
      },
      title: copy.title,
      message: copy.message,
      footnote: copy.reference,
      actionLabel: t.common.actions.retry,
      onAction: onRetry,
      cooldown: switch (failure) {
        RateLimitedFailure(:final retryAfter) => retryAfter,
        _ => null,
      },
      cooldownLabel: (remaining) =>
          t.common.retryIn(time: formatCountdown(remaining)),
    );
  }
}

/// Nothing matches what was asked: the query, or the category, and the way
/// back to the whole menu.
class EmptyMenu extends StatelessWidget {
  const new({
    required this.query,
    required this.onClearSearch,
    required this.onShowAll,
    super.key,
  });

  /// The search that found nothing; empty when a category is the cause.
  final String query;
  final VoidCallback onClearSearch;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final t = context.t.dishes;
    final searching = query.trim().isNotEmpty;
    return StateView(
      kind: .empty,
      title: searching ? t.empty.search(query: query.trim()) : t.empty.category,
      message: searching ? t.empty.searchHint : null,
      actionLabel: searching ? t.header.clearSearch : t.empty.showAll,
      onAction: searching ? onClearSearch : onShowAll,
    );
  }
}
