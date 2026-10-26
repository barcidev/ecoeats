import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/motion.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:flutter/widgets.dart';

// Discover is always on a photo: its chrome takes the night palette.
const EcoPalette _onPhoto = EcoPalette.fogon;

/// The page the pager is nearest to, from 0.
int _nearest(PageController pager) =>
    pager.hasClients && pager.position.haveDimensions
    ? (pager.page ?? 0).round()
    : pager.initialPage;

/// «04 / 12», in figures that do not dance as they change.
class DiscoverCounter extends StatelessWidget {
  const new({required this.pager, required this.count, super.key});

  final PageController pager;
  final int count;

  static String _two(int value) => '$value'.padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pager,
      builder: (context, _) => Semantics(
        liveRegion: true,
        child: Text(
          context.t.discover.counter(
            current: _two(_nearest(pager) + 1),
            total: _two(count),
          ),
          style: EcoType.numeric.copyWith(
            color: _onPhoto.ink,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

/// A thin rail on the right edge that fills as the walk goes on, following
/// the finger rather than the settled page.
class DiscoverRail extends StatelessWidget {
  const new({required this.pager, required this.count, super.key});

  final PageController pager;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 2,
        height: MediaQuery.sizeOf(context).height * 0.3,
        child: AnimatedBuilder(
          animation: pager,
          builder: (context, _) {
            final page = pager.hasClients && pager.position.haveDimensions
                ? pager.page ?? 0
                : 0.0;
            final filled = ((page + 1) / count).clamp(0.0, 1.0);
            return DecoratedBox(
              decoration: ShapeDecoration(
                color: _onPhoto.ink.withValues(alpha: 0.24),
                shape: const StadiumBorder(),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  heightFactor: filled,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: _onPhoto.ink,
                      shape: const StadiumBorder(),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DiscoverClose extends StatelessWidget {
  const new({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: context.t.common.actions.close,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Icon(EcoIcons.x, color: _onPhoto.ink),
      ),
    );
  }
}

/// The first-time hint: a quiet pill with an arrow that nods upward a few
/// times. A tap hides it; a swipe that starts on it turns the page.
class DiscoverHintBubble extends StatefulWidget {
  const new({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  State<DiscoverHintBubble> createState() => _DiscoverHintBubbleState();
}

class _DiscoverHintBubbleState extends State<DiscoverHintBubble>
    with SingleTickerProviderStateMixin {
  late final _nod = AnimationController(
    vsync: this,
    duration: Motion.signature,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _nod.stop();
    } else if (!_nod.isAnimating && !_nod.isCompleted) {
      // Three nods are enough to be noticed; then it rests.
      _nod.repeat(reverse: true, count: 6);
    }
  }

  @override
  void dispose() {
    _nod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.discover;
    // Translucent all the way down: a tap dismisses the hint, but a swipe
    // that starts on it still reaches the pager below, which a Pressable
    // (opaque, a sibling on top) would swallow.
    return Semantics(
      button: true,
      label: '${t.hint} ${t.hintDismiss}',
      excludeSemantics: true,
      onTap: widget.onDismiss,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onDismiss,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: _onPhoto.paper.withValues(alpha: 0.6),
              shape: StadiumBorder(
                side: BorderSide(color: _onPhoto.ink.withValues(alpha: 0.2)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              child: Row(
                mainAxisSize: .min,
                spacing: Space.xs,
                children: [
                  AnimatedBuilder(
                    animation: _nod,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        0,
                        -Curves.easeInOut.transform(_nod.value) * Space.xs,
                      ),
                      child: child,
                    ),
                    child: Icon(
                      EcoIcons.arrowUp,
                      size: 18,
                      color: _onPhoto.maiz,
                    ),
                  ),
                  // Larger text and other languages wrap instead of spilling.
                  Flexible(
                    child: Text(
                      t.hint,
                      style: EcoType.bodySmall.copyWith(color: _onPhoto.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
