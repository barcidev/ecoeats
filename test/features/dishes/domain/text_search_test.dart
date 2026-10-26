import 'package:ecoeats/features/dishes/domain/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('foldForSearch', () {
    test('drops accents, ñ, case and extra spaces', () {
      expect(foldForSearch('  Ajiaco   Santafereño '), 'ajiaco santafereno');
      expect(foldForSearch('ÁÉÍÓÚÜ áéíóúü Ññ'), 'aeiouu aeiouu nn');
    });
  });

  group('matchesSearch', () {
    const fields = ['Arroz con camarones', 'Arroz, camarones, coco, jalapeño'];

    test('an empty query matches everything', () {
      expect(matchesSearch('', fields), isTrue);
      expect(matchesSearch('   ', fields), isTrue);
    });

    test('ignores accents and ñ both ways', () {
      expect(matchesSearch('camaron', fields), isTrue);
      expect(matchesSearch('JALAPENO', fields), isTrue);
      expect(matchesSearch('jalapeño', ['Salsa de jalapeno']), isTrue);
    });

    test('every word must match, in any order and any field', () {
      expect(matchesSearch('coco arroz', fields), isTrue);
      expect(matchesSearch('coco pollo', fields), isFalse);
    });
  });
}
