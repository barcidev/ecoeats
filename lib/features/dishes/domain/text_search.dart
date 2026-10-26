const _folds = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', //
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', //
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', //
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', //
  'ñ': 'n', 'ç': 'c',
};

/// Lowercase, without accents, «ñ» or repeated spaces: people type «camaron»
/// for «camarón» and «jalapeno» for «jalapeño».
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    final unit = char.codeUnitAt(0);
    // Combining marks of decomposed text (e + ´) fold away too.
    if (unit >= 0x0300 && unit <= 0x036F) continue;
    buffer.write(_folds[char] ?? char);
  }
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Every word of [query] must appear in some field, in any order.
bool matchesSearch(String query, Iterable<String> fields) {
  final words = foldForSearch(query)
      .split(' ')
      .where((word) => word.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = foldForSearch(fields.join(' '));
  return words.every(haystack.contains);
}
