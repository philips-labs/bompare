/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import '../purl.dart';

/// Bill-of-material item identifier.
class BomItem implements Comparable<BomItem> {
  final Purl purl;
  final licenses = <String>{};

  BomItem(this.purl);

  void addLicenses(Iterable<String> values) {
    licenses.addAll(values.where((lic) => lic.isNotEmpty));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BomItem &&
          runtimeType == other.runtimeType &&
          purl == other.purl;

  @override
  int get hashCode => purl.hashCode;

  @override
  int compareTo(BomItem other) {
    return purl.compareTo(other.purl);
  }

  @override
  String toString() {
    return purl.toString();
  }
}
