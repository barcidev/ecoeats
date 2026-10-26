import 'package:ecoeats/features/dishes/domain/ingredients.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('commas inside parentheses stay with their ingredient', () {
    expect(
      parseIngredients(
        'Frijoles rojos, arroz blanco, hogao (tomate, cebolla), aguacate',
      ),
      ['Frijoles rojos', 'arroz blanco', 'hogao (tomate, cebolla)', 'aguacate'],
    );
  });

  test('nested parentheses count as one level each', () {
    expect(parseIngredients('salsa (ají (dulce, picante), limón), sal'), [
      'salsa (ají (dulce, picante), limón)',
      'sal',
    ]);
  });

  test('spaces, empty items and a final period go away', () {
    expect(parseIngredients('  papa criolla ,, mazorca,  guascas. '), [
      'papa criolla',
      'mazorca',
      'guascas',
    ]);
    expect(parseIngredients(''), isEmpty);
    expect(parseIngredients(' , '), isEmpty);
  });

  test('an unclosed parenthesis keeps the rest in one ingredient', () {
    expect(parseIngredients('queso (costeño, suero'), [
      'queso (costeño, suero',
    ]);
  });
}
