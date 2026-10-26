import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Loads the date symbols of every language before the first [Formatters.date].
Future<void> initFormatters() => initializeDateFormatting();

/// Numbers and dates written the way each language reads them. It takes a
/// language code instead of the app locale so `core` stays free of the
/// generated translations.
class Formatters {
  const new(this.languageCode);

  final String languageCode;

  bool get _english => languageCode == 'en';

  String get _numberLocale => _english ? 'en_US' : 'es_CO';

  /// es: «$ 28.000» · en: «COP 28,000». Prices are whole pesos.
  String price(num value) {
    final amount = NumberFormat('#,##0', _numberLocale).format(value.round());
    return _english ? 'COP $amount' : '\$ $amount';
  }

  /// es: «4,9» · en: «4.9».
  String rating(num value) => NumberFormat('0.0', _numberLocale).format(value);

  /// es: «SÁBADO 24 DE OCTUBRE» · en: «SATURDAY, OCTOBER 24».
  String date(DateTime value) {
    final pattern = _english
        ? DateFormat('EEEE, MMMM d', 'en')
        : DateFormat("EEEE d 'de' MMMM", 'es');
    return pattern.format(value).toUpperCase();
  }
}
