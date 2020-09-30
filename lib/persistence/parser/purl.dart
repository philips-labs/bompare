/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';

/// Decodes name and version from a Package URL (purl) description.
/// See https://github.com/package-url/purl-spec
/// A purl consists of: scheme:type/namespace/name@version?qualifiers#subpath
class Purl {
  final String _spec;

  Purl(String specification) : _spec = specification {
    if (!specification.startsWith('pkg:')) {
      throw FormatException('PURL must have scheme "pkg"');
    }
  }

  /// Returns package manager type (or empty string).
  String get type {
    final path = _path()[0];
    if (path.isEmpty) {
      throw FormatException('Missing type part in "$_spec');
    }
    return Uri.decodeComponent(path);
  }

  /// Returns name with optional namespace (or empty string).
  String get name {
    var path = _path();
    if (path.length < 2) {
      throw FormatException('Missing name part in "$_spec"');
    }
    return path.sublist(1).map(Uri.decodeComponent).join('/');
  }

  /// Returns version or empty string.
  String get version => Uri.decodeComponent(_version());

  List<String> _path() {
    final startPos = _spec.indexOf(':') + 1;
    final endPos = _firstPosOrLength(['@', '?', '#']);
    return _spec.substring(startPos, endPos).split('/');
  }

  String _version() {
    final startPos = _spec.indexOf('@');
    if (startPos < 0) return '';

    final endPos = _firstPosOrLength(['?', '#']);
    return _spec.substring(startPos + 1, endPos);
  }

  int _firstPosOrLength(List<String> chars) => chars
      .map((ch) => _spec.indexOf(ch))
      .where((value) => value >= 0)
      .fold(_spec.length, min);
}
