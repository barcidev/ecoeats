import 'package:ecoeats/core/format/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(initFormatters);

  group('es', () {
    const format = Formatters('es');

    test('prices are Colombian pesos with a dot for thousands', () {
      expect(format.price(28000), r'$ 28.000');
      expect(format.price(1250000), r'$ 1.250.000');
      expect(format.price(17999.6), r'$ 18.000');
    });

    test('ratings use a decimal comma', () {
      expect(format.rating(4.9), '4,9');
      expect(format.rating(5), '5,0');
    });

    test('the date reads as a capitalized overline', () {
      expect(format.date(DateTime(2026, 10, 24)), 'SÁBADO 24 DE OCTUBRE');
    });
  });

  group('en', () {
    const format = Formatters('en');

    test('prices name the currency', () {
      expect(format.price(28000), 'COP 28,000');
    });

    test('ratings use a decimal point', () {
      expect(format.rating(4.9), '4.9');
    });

    test('the date reads as a capitalized overline', () {
      expect(format.date(DateTime(2026, 10, 24)), 'SATURDAY, OCTOBER 24');
    });
  });

  test('an unknown language formats like Spanish', () {
    expect(const Formatters('pt').price(28000), r'$ 28.000');
  });
}
