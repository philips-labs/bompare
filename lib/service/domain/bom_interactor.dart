/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:core';
import 'dart:io';

import 'package:glob/glob.dart';

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

  @override
  bool verbose = false;

  BomInteractor(this.results, this.reports);

  @override
  Future<void> loadSpdxMapping(File file) {
    return results.loadMapping(file);
  }

  @override
  Future<void> loadResult(ScannerType type, Glob glob) async {
    _scans.add(await results.load(type, glob));
  }

  @override
  Future<List<BomResult>> compareBom(
      {File bomFile, bool diffOnly = false}) async {
    if (_scans.isEmpty) return <BomResult>[];

    final all = <ItemId>{};
    final common = _buildBom(_scans[0].items, all);
    final ids = diffOnly ? all.difference(common) : all;

    if (bomFile != null) {
      await reports.writeBomComparison(bomFile, ids, _scans);
    }

    if (verbose) {
      _printBomResults(ids);
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

    final ids = diffOnly ? bom.difference(common) : bom;
    if (licensesFile != null) {
      await reports.writeLicenseComparison(licensesFile, ids, _scans);
    }

    if (verbose) {
      _printLicenseResults(ids);
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

  bool _scannedLicensesMatch(ItemId itemId) => !_scans.any((s) {
        final scan = s[itemId];
        final match = scan.licenses.containsAll(itemId.licenses) &&
            itemId.licenses.containsAll(scan.licenses);
        return !match;
      });

  void _printBomResults(Iterable<ItemId> ids) {
    _printTablePerItemId(
        ids, (scan, item) => (scan[item] != null) ? 'Yes' : 'No');
  }

  void _printLicenseResults(Iterable<ItemId> ids) {
    _printTablePerItemId(ids, (scan, item) => scan[item].licenses.join(' OR '));
  }

  void _printTablePerItemId(Iterable<ItemId> items,
      String Function(ScanResult scan, ItemId item) columnValue) {
    const separator = ' | ';

    final scans = _scans.map((s) => s.name).join(separator);
    final headline = 'Package | Version | $scans';
    print(headline);
    print(headline.replaceAll(RegExp(r'[^|]'), '-'));

    items.toList()
      ..sort()
      ..forEach((item) {
        final columns = _scans.map((s) => columnValue(s, item)).join(separator);
        print('${item.package} | ${item.version} | $columns');
      });

    print('');
  }
}
