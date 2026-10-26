const _open = 0x28; // (
const _close = 0x29; // )
const _comma = 0x2C; // ,

/// Splits the API's ingredient list on its commas, except those inside
/// parentheses: «hogao (tomate, cebolla)» is one ingredient, not two.
List<String> parseIngredients(String raw) {
  final items = <String>[];
  final current = StringBuffer();
  var depth = 0;

  void flush() {
    var item = current.toString().trim();
    if (item.endsWith('.')) item = item.substring(0, item.length - 1).trim();
    if (item.isNotEmpty) items.add(item);
    current.clear();
  }

  for (final unit in raw.codeUnits) {
    if (unit == _comma && depth == 0) {
      flush();
      continue;
    }
    if (unit == _open) depth++;
    if (unit == _close && depth > 0) depth--;
    current.writeCharCode(unit);
  }
  flush();
  return items;
}
