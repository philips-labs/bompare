import '../business_exception.dart';
import 'spdx_licenses.dart' as spdx;

/// Dictionary to map license titles to SPDX identifiers.
class SpdxMapper {
  static final _andOrSeparator = RegExp(r'\s((or)|(and))\s');
  static final _enclosingBraces = RegExp(r'(^\()|(\)$)');

  final _mapping = <String, String>{};

  SpdxMapper() {
    spdx.dictionary.forEach((title, identifier) {
      _mapping[title.toLowerCase()] = identifier;
      _mapping[identifier.toLowerCase()] = identifier;
    });
  }

  /// Maps the [title] to one or more license identifiers.
  Set<String> operator [](String title) {
    if (title == null) return {};

    final unbraced = title.replaceAll(_enclosingBraces, '');

    return _findOrNull(unbraced) ?? {'"$title"'};
  }

  Set<String> _findOrNull(String title, {bool allowLiteral = true}) {
    final key = title.toLowerCase();
    if (_mapping.containsKey(key)) {
      return {_mapping[key]};
    }

    var offset = 0;
    var match = _andOrSeparator.firstMatch(key);
    while (match != null) {
      final prefix = key.substring(0, offset + match.start);
      final remainder = key.substring(offset + match.end);
      final right = _findOrNull(remainder, allowLiteral: false);
      if (_mapping.containsKey(prefix) || (allowLiteral && right != null)) {
        final result = right ?? {'"$remainder"'};
        result.add(_mapping[prefix] ?? '"$prefix"');
        return result;
      }
      offset += match.end;
      match = _andOrSeparator.firstMatch(key.substring(offset));
    }
    return null;
  }

  /// Adds a new mapping from [title] to an existing SPDX identifier.
  void operator []=(String title, String identifier) {
    final key = title.toLowerCase();
    if (_mapping.containsKey(key)) {
      throw BusinessException(
          'Title "$title" is already mapped to ${_mapping[key]}');
    }
    if (!_mapping.containsValue(identifier)) {
      throw BusinessException('"$identifier" is not a valid SPDX identifier');
    }
    _mapping[key.toLowerCase()] = identifier;
  }
}
