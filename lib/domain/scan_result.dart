import 'item_id.dart';

/// Tool-independent summary of BOM scan results.
class ScanResult {
  /// Name of the scanning source.
  final String name;

  /// Returns the bill-of-material.
  final items = <ItemId>{};

  ScanResult(this.name);

  /// Registers a bill-of-material item.
  void addItem(ItemId id) {
    items.add(id);
  }
}
