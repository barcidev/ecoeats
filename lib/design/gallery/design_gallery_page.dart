import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/design/gallery/gallery_sections.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/segmented_pills.dart';
import 'package:ecoeats/i18n/gen/strings.g.dart';
import 'package:material_ui/material_ui.dart';

/// Every design component on one page, in light or dark and in Spanish or
/// English, for visual QA. Debug builds only: the router does not register
/// it in release.
@RoutePage()
class DesignGalleryPage extends StatefulWidget {
  const new({super.key});

  @override
  State<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends State<DesignGalleryPage> {
  /// Local to the gallery: the customer's stored appearance stays as it is.
  Brightness? _brightness;

  /// The language the app had: the gallery hands it back when it closes.
  final AppLocale _entryLocale = LocaleSettings.currentLocale;

  @override
  void dispose() {
    if (LocaleSettings.currentLocale != _entryLocale) {
      unawaited(LocaleSettings.setLocale(_entryLocale));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _brightness ?? Theme.of(context).brightness;
    return Theme(
      data: ecoTheme(brightness),
      child: Builder(
        builder: (context) {
          final t = context.t;
          final palette = context.palette;
          return Scaffold(
            backgroundColor: palette.paper,
            appBar: AppBar(
              backgroundColor: palette.paper,
              title: Text(
                'Design gallery',
                style: EcoType.titleSmall.copyWith(color: palette.ink),
              ),
            ),
            body: CustomScrollView(
              slivers: [
                PinnedHeaderSliver(
                  child: ColoredBox(
                    color: palette.paper,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Column(
                        spacing: Space.xs,
                        children: [
                          SegmentedPills<AppLocale>(
                            values: AppLocale.values,
                            selected: LocaleSettings.currentLocale,
                            labelOf: (locale) => switch (locale) {
                              .es => t.profile.language.spanish,
                              .en => t.profile.language.english,
                            },
                            onChanged: (locale) =>
                                unawaited(LocaleSettings.setLocale(locale)),
                          ),
                          SegmentedPills<Brightness>(
                            values: Brightness.values.reversed.toList(),
                            selected: brightness,
                            labelOf: (choice) => switch (choice) {
                              .light => t.profile.appearance.light,
                              .dark => t.profile.appearance.dark,
                            },
                            onChanged: (choice) =>
                                setState(() => _brightness = choice),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                  sliver: SliverToBoxAdapter(child: GallerySections()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
