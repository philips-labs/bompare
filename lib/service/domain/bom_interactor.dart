import 'dart:core';
import 'dart:io';

import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/report_persistence.dart';
import 'package:bompare/service/result_persistence.dart';

import '../bom_service.dart';
import 'item_id.dart';

/// Use case implementations for a bill-of-material.
class BomInteractor implements BomService {
  final ResultPersistence results;
  final ReportPersistence reports;

  final _scans = <ScanResult>[];

  BomInteractor(this.results, this.reports);

  @override
  Future<void> loadResult(ScannerType type, File file) async {
    _scans.add(await results.load(type, file));
  }

  @override
  Future<List<BomResult>> compareResults(
      {File bomFile, bool diffOnly = false}) async {
    if (_scans.isEmpty) return <BomResult>[];

    final all = <ItemId>{};
    final common = _buildBom(_scans[0].items, all);

    if (bomFile != null) {
      await reports.writeBomComparison(
          bomFile, diffOnly ? all.difference(common) : all, _scans);
    }

    return _bomResultPerScanResult(all, common);
  }

  Set<ItemId> _buildBom(Set<ItemId> common, Set<ItemId> all) {
    _scans.forEach((r) {
      common = common.intersection(r.items);
      all.addAll(r.items);
    });
    return common;
  }

  List<BomResult> _bomResultPerScanResult(
          Set<ItemId> all, Set<ItemId> common) =>
      _scans.map((r) {
        final missing = all.difference(r.items).length;
        final additional = r.items.difference(common).length;
        return BomResult(
            r.name, r.items.length, common.length, additional, missing);
      }).toList();
}
