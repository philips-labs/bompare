/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'item_id.dart';

/// Tool-independent summary of BOM scan results.
class ScanResult {
  /// Name of the scanning source.
  final String name;

  /// Returns the bill-of-material.
  final items = <ItemId>{};

  ScanResult(this.name);

  /// Combines the [other] result with this one.
  void merge(ScanResult other) {
    other.items.forEach((itemId) {
      items.add(itemId);
      this[itemId].addLicenses(itemId.licenses);
    });
  }

  /// Registers a bill-of-material item.
  void addItem(ItemId id) {
    items.add(id);
  }

  /// Returns actual item of the scan for the provided [itemId], or null if
  /// the scan does not include the item.
  ItemId operator [](ItemId itemId) => items.lookup(itemId);
}
