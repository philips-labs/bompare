/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

/// Bill-of-material item identifier.
class BomItem implements Comparable<BomItem> {
  final String package;
  final String version;
  final licenses = <String>{};

  BomItem(this.package, version) : version = version ?? '';

  void addLicenses(Iterable<String> values) {
    licenses.addAll(values.where((lic) => lic.isNotEmpty));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BomItem &&
          runtimeType == other.runtimeType &&
          package == other.package &&
          version == other.version;

  @override
  int get hashCode => package.hashCode ^ version.hashCode;

  @override
  int compareTo(BomItem other) {
    final diff = package.compareTo(other.package);
    if (diff != 0) return diff;

    return version.compareTo(other.version);
  }

  @override
  String toString() {
    return '$package-$version';
  }
}
