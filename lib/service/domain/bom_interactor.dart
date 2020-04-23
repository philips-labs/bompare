import 'dart:core';
import 'dart:io';

import '../bom_service.dart';
import '../report_persistence.dart';
import '../result_persistence.dart';
import 'item_id.dart';
import 'scan_result.dart';

/// Use case implementations for a bill-of-material.
class BomInteractor implements BomService {
  final ResultPersistence results;
  final ReportPersistence reports;

  final _scans = <ScanResult>[];

  BomInteractor(this.results, this.reports);

  @override
  Future<void> loadSpdxMapping(File file) {
    return results.loadMapping(file);
  }

  @override
  Future<void> loadResult(ScannerType type, File file) async {
    _scans.add(await results.load(type, file));
  }

  @override
  Future<List<BomResult>> compareBom(
      {File bomFile, bool diffOnly = false}) async {
    if (_scans.isEmpty) return <BomResult>[];

    final all = <ItemId>{};
    final common = _buildBom(_scans[0].items, all);

    if (bomFile != null) {
      final ids = diffOnly ? all.difference(common) : all;
      await reports.writeBomComparison(bomFile, ids, _scans);
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
      _scans
          .map((r) => BomResult(
                r.name,
                r.items.length,
                common: common.length,
                additional: r.items.difference(common).length,
                missing: all.difference(r.items).length,
              ))
          .toList();

  @override
  Future<LicenseResult> compareLicenses(
      {File licensesFile, bool diffOnly = false}) async {
    if (_scans.isEmpty) return LicenseResult(0, 0);

    final bom = _commonBom();
    final common = _commonLicenses(bom);

    if (licensesFile != null) {
      final ids = diffOnly ? bom.difference(common) : bom;
      await reports.writeLicenseComparison(licensesFile, ids, _scans);
    }

    return LicenseResult(bom.length, common.length);
  }

  Set<ItemId> _commonBom() {
    var bom = _scans[0].items;
    _scans.forEach((s) {
      bom = bom.intersection(s.items);
    });
    return bom;
  }

  Set<ItemId> _commonLicenses(Set<ItemId> bom) =>
      bom.where(_scannedLicensesMatch).toSet();

  bool _scannedLicensesMatch(c) => !_scans.any((s) {
        final scan = s.items.lookup(c);
        final match = scan.licenses.containsAll(c.licenses) &&
            c.licenses.containsAll(scan.licenses);
        return !match;
      });
}
