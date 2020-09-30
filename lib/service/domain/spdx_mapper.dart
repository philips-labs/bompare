/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

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

    spdx.deprecated.forEach((key, value) => this[key] = value);
  }

  /// Maps the [title] to one or more license identifiers.
  Set<String> operator [](String title) {
    if (title == null) return {};

    final unbraced = title.replaceAll(_enclosingBraces, '');

    return _find(unbraced);
  }

  /// Returns the decomposed and decoded set of licenses in [title].
  /// Splits on OR and AND, and tries to match the biggest possible fragment.
  /// If [anyMatch] is true it also returns if any match is found. (This is
  /// used for controlling recursion into split blocks.)
  Set<String> _find(String title, {bool anyMatch = false}) {
    final key = title.toLowerCase();
    if (_mapping.containsKey(key)) return {_mapping[key]};

    final matches = _andOrSeparator.allMatches(key);
    // Iterate from end to avoid accidental prefix-matches
    for (final match in matches.toList().reversed) {
      final leftKey = key.substring(0, match.start);
      final leftResult = _find(leftKey, anyMatch: true);

      final rightKey = key.substring(match.end);
      final rightResult = _find(rightKey, anyMatch: true);

      if (rightResult.isNotEmpty) {
        if (anyMatch) return leftResult.union(rightResult);

        final leftTitle = title.substring(0, match.start);
        final rightTitle = title.substring(match.end);
        return _find(leftTitle).union(_find(rightTitle));
      } else if (_mapping.containsKey(leftKey)) {
        // Left result is a last resort to avoid prefix-match
        return leftResult.union({'"${title.substring(match.end)}"'});
      }
    }
    return {if (!anyMatch) '"$title"'};
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
