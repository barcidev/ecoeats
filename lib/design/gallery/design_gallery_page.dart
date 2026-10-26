import 'package:auto_route/auto_route.dart';
import 'package:ecoeats/design/painters/logo_mark.dart';
import 'package:ecoeats/design/painters/plate_illustration.dart';
import 'package:ecoeats/design/theme.dart';
import 'package:ecoeats/design/tokens/palette.dart';
import 'package:ecoeats/design/tokens/spacing.dart';
import 'package:ecoeats/design/tokens/typography.dart';
import 'package:ecoeats/design/widgets/dish_image.dart';
import 'package:ecoeats/design/widgets/eco_button.dart';
import 'package:ecoeats/design/widgets/eco_text_field.dart';
import 'package:ecoeats/design/widgets/plate_spinner.dart';
import 'package:ecoeats/design/widgets/rating_stars.dart';
import 'package:ecoeats/design/widgets/segmented_pills.dart';
import 'package:ecoeats/design/widgets/skeleton.dart';
import 'package:ecoeats/design/widgets/state_view.dart';
import 'package:material_ui/material_ui.dart';

/// Every design component on one page, in light or dark, for visual QA.
/// Debug builds only: the router does not register it in release.
@RoutePage()
class DesignGalleryPage extends StatefulWidget {
  const new({super.key});

  @override
  State<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends State<DesignGalleryPage> {
  Brightness? _brightness;
  var _pill = 'Todos';

  @override
  Widget build(BuildContext context) {
    final brightness = _brightness ?? Theme.of(context).brightness;
    return Theme(
      data: ecoTheme(brightness),
      child: Builder(
        builder: (context) {
          final palette = context.palette;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Design gallery', style: EcoType.titleSmall),
              actions: [
                Switch(
                  value: brightness == .dark,
                  onChanged: (dark) =>
                      setState(() => _brightness = dark ? .dark : .light),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(Space.gutter),
              children: [
                const _Section('Type'),
                Text(
                  'Comida colombiana,\nsin afán.',
                  style: EcoType.displayWonk.copyWith(color: palette.ink),
                ),
                Text(
                  'Headline',
                  style: EcoType.headline.copyWith(color: palette.ink),
                ),
                Text(
                  'Body 16/24, Instrument Sans.',
                  style: EcoType.body.copyWith(color: palette.ink),
                ),
                Text(
                  r'$ 28.000',
                  style: EcoType.numeric.copyWith(color: palette.ink),
                ),
                const _Section('Buttons'),
                EcoButton(label: 'Entrar', onPressed: () {}),
                const SizedBox(height: Space.sm),
                EcoButton(
                  label: 'Crear cuenta',
                  variant: .secondary,
                  onPressed: () {},
                ),
                const SizedBox(height: Space.sm),
                const EcoButton(label: 'Cargando', loading: true),
                const SizedBox(height: Space.sm),
                const EcoButton(label: 'Deshabilitado'),
                const _Section('Selection'),
                SegmentedPills<String>(
                  padding: EdgeInsets.zero,
                  values: const [
                    'Todos',
                    'Destacados',
                    'Altos en proteína',
                    'Ligeros',
                  ],
                  selected: _pill,
                  labelOf: (value) => value,
                  onChanged: (value) => setState(() => _pill = value),
                ),
                const SizedBox(height: Space.sm),
                const RatingStars(rating: 4.7, size: 18),
                const _Section('Fields'),
                const EcoTextField(label: 'Correo', hint: 'tu@correo.com'),
                const SizedBox(height: Space.md),
                const EcoTextField(
                  label: 'Contraseña',
                  obscureText: true,
                  error: 'Mínimo 6 caracteres.',
                ),
                const _Section('Media'),
                const SizedBox(
                  height: 220,
                  child: DishImage(
                    url: null,
                    name: 'Bandeja Paisa',
                    borderRadius: BorderRadius.all(.circular(Radii.lg)),
                  ),
                ),
                const _Section('Loading'),
                const Row(
                  spacing: Space.md,
                  children: [
                    PlateSpinner(),
                    PlateSpinner(progress: 0.6),
                    LogoMark(size: 48),
                  ],
                ),
                const SizedBox(height: Space.md),
                const Skeleton(height: 120, radius: Radii.lg),
                const SizedBox(height: Space.xs),
                const Skeleton(width: 180, height: 16),
                const _Section('States'),
                const PlateIllustration(),
                SizedBox(
                  height: 360,
                  child: StateView(
                    kind: .rateLimited,
                    title: 'Vas muy rápido.',
                    message: 'Espera un momento y vuelve a intentarlo.',
                    actionLabel: 'Reintentar',
                    onAction: () {},
                    cooldown: const Duration(seconds: 42),
                    cooldownLabel: _countdown,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _countdown(Duration left) {
  final seconds = left.inSeconds.toString().padLeft(2, '0');
  return 'Intenta en 0:$seconds';
}

class _Section extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm),
      child: Text(
        title.toUpperCase(),
        style: EcoType.overline.copyWith(color: context.palette.muted),
      ),
    );
  }
}
