import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/tokens/eco_icons.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/widgets/pressable.dart';
import 'package:material_ui/material_ui.dart';

/// Placeholder: an empty stage with a way back, until agent C's vertical
/// pager lands.
@RoutePage()
class DiscoverPage extends StatelessWidget {
  const new({this.revealOrigin, super.key});

  /// Where the circular reveal starts; the route reads it from the page
  /// arguments.
  final Offset? revealOrigin;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: PlateIllustration(
                size: 160,
                color: palette.paper.withValues(alpha: 0.5),
                accent: palette.maiz,
              ),
            ),
            Positioned(
              top: Space.xs,
              right: Space.xs,
              child: Pressable(
                semanticLabel: MaterialLocalizations.of(context)
                    .closeButtonLabel,
                onPressed: () => Navigator.of(context).maybePop(),
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Icon(EcoIcons.x, color: palette.paper),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
