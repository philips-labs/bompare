/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'bom_item.dart';

/// Tool-independent summary of BOM scan results.
class ScanResult {
  /// Name of the scanning source.
  final String name;

  /// Returns the bill-of-material.
  final items = <BomItem>{};

  ScanResult(this.name);

  /// Combines the [other] result with this one.
  void merge(ScanResult other) {
    other.items.forEach((item) {
      items.add(item);
      this[item]?.addLicenses(item.licenses);
    });
  }

  /// Registers a bill-of-material item.
  void addItem(BomItem item) {
    items.add(item);
  }

  /// Returns actual item of the scan for the provided [item], or null if
  /// the scan does not include the item.
  BomItem? operator [](BomItem item) => items.lookup(item);
}
