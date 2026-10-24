import 'package:material_ui/material_ui.dart';

/// Colors taken from the Colombian kitchen: the tablecloth by day («Mantel»)
/// and the stove by night («Fogón»).
@immutable
class EcoPalette extends ThemeExtension<EcoPalette> {
  const new({
    required this.paper,
    required this.raised,
    required this.ink,
    required this.muted,
    required this.line,
    required this.achiote,
    required this.aguacate,
    required this.maiz,
    required this.panela,
  });

  static const mantel = EcoPalette(
    paper: Color(0xFFF4EEE4),
    raised: Color(0xFFFBF7F0),
    ink: Color(0xFF1E1B16),
    muted: Color(0xFF6B6257),
    line: Color(0xFFE2D8C9),
    achiote: Color(0xFFC2410C),
    aguacate: Color(0xFF4D6B2F),
    maiz: Color(0xFFE3A72F),
    panela: Color(0xFF8A5A2B),
  );

  static const fogon = EcoPalette(
    paper: Color(0xFF14110E),
    raised: Color(0xFF1E1A16),
    ink: Color(0xFFF3ECE1),
    muted: Color(0xFFA69C8F),
    line: Color(0xFF2E2822),
    achiote: Color(0xFFF06A2E),
    aguacate: Color(0xFF8FB15A),
    maiz: Color(0xFFF2C14E),
    panela: Color(0xFFB07A45),
  );

  final Color paper;
  final Color raised;
  final Color ink;
  final Color muted;
  final Color line;

  /// The call to action, and the only loud color on a screen.
  final Color achiote;
  final Color aguacate;
  final Color maiz;
  final Color panela;

  @override
  EcoPalette copyWith({
    Color? paper,
    Color? raised,
    Color? ink,
    Color? muted,
    Color? line,
    Color? achiote,
    Color? aguacate,
    Color? maiz,
    Color? panela,
  }) {
    return EcoPalette(
      paper: paper ?? this.paper,
      raised: raised ?? this.raised,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      achiote: achiote ?? this.achiote,
      aguacate: aguacate ?? this.aguacate,
      maiz: maiz ?? this.maiz,
      panela: panela ?? this.panela,
    );
  }

  @override
  EcoPalette lerp(EcoPalette? other, double t) {
    if (other == null) return this;
    return EcoPalette(
      paper: Color.lerp(paper, other.paper, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      achiote: Color.lerp(achiote, other.achiote, t)!,
      aguacate: Color.lerp(aguacate, other.aguacate, t)!,
      maiz: Color.lerp(maiz, other.maiz, t)!,
      panela: Color.lerp(panela, other.panela, t)!,
    );
  }
}

extension EcoPaletteContext on BuildContext {
  EcoPalette get palette =>
      Theme.of(this).extension<EcoPalette>() ?? EcoPalette.mantel;
}
