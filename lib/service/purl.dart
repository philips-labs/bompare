/*
 * Copyright (c) 2020-2021, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';

/// Decodes name and version from a Package URL (purl) description.
/// See https://github.com/package-url/purl-spec
/// A purl consists of: scheme:type/namespace/name@version?qualifiers#subpath
class Purl implements Comparable<Purl> {
  /// Assumed type when no type is provided as parameter to [Purl.of].
  static String defaultType = 'generic';

  final String _spec;

  /// Creates instance from a valid Package URL.
  Purl(String specification) : _spec = specification {
    if (!specification.startsWith('pkg:')) {
      throw FormatException('PURL must have scheme "pkg"');
    }
  }

  /// Creates instance from parts.
  /// If no [type] is provided, the current value of [defaultType] is assumed.
  /// The [namespace] can alternatively provided in the [name] using '/' as a separator.
  factory Purl.of({
    String? type,
    String? namespace,
    required String name,
    required String version,
  }) {
    type ??= defaultType;
    final pos = name.indexOf('/');
    if (pos >= 0) {
      namespace = name.substring(0, pos);
      name = name.substring(pos + 1);
    }
    final spec =
        'pkg:$type/${namespace != null ? '${Uri.encodeComponent(namespace)}/' : ''}'
        '${Uri.encodeComponent(name)}@${Uri.encodeComponent(version)}';
    return Purl(spec);
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Purl && runtimeType == other.runtimeType && _spec == other._spec;

  @override
  int get hashCode => _spec.hashCode;

  @override
  int compareTo(Purl other) {
    final cmpName = name.compareTo(other.name);
    if (cmpName != 0) return cmpName;
    final cmpVersion = version.compareTo(other.version);
    if (cmpVersion != 0) return cmpVersion;
    return type.compareTo(other.type);
  }

  @override
  String toString() {
    return _spec;
  }
}
