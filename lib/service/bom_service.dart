import 'dart:core';
import 'dart:io';

import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/result_persistence.dart';

import 'domain/item_id.dart';

/// Use case implementations for a bill-of-material.
class BomService {
  final ResultPersistence persistence;

  final _results = <ScanResult>[];

  BomService(this.persistence);

  /// Loads a scanner result of [type] from [file].
  void loadResult(ScannerType type, File file) {
    _results.add(persistence.load(type, file));
  }

  /// Returns bill-of-material summary, and optionally writes the content
  /// to [bomFile].
  List<BomResult> compareResults({File bomFile}) {
    if (_results.isEmpty) return <BomResult>[];

    final all = <ItemId>{};
    final common = _buildBom(_results[0].items, all);

    return _bomResultPerScanResult(all, common);
  }

  Set<ItemId> _buildBom(Set<ItemId> common, Set<ItemId> all) {
    _results.forEach((r) {
      common = common.intersection(r.items);
      all.addAll(r.items);
    });
    return common;
  }

  List<BomResult> _bomResultPerScanResult(
          Set<ItemId> all, Set<ItemId> common) =>
      _results.map((r) {
        final missing = all.difference(r.items).length;
        final additional = r.items.difference(common).length;
        return BomResult(r.name, common.length, additional, missing);
      }).toList();
}

enum ScannerType { reference, black_duck, white_source }

class BomResult {
  String name;
  int common;
  int additional;
  int missing;

  BomResult(this.name, this.common, this.additional, this.missing);
}
