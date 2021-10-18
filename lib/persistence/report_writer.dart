/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:io';

import '../service/domain/bom_item.dart';
import '../service/domain/scan_result.dart';
import '../service/report_persistence.dart';
import 'report/csv_result_writer.dart';

class ReportWriter implements ReportPersistence {
  @override
  Future<void> writeBomComparison(
          File file, Iterable<BomItem> items, Iterable<ScanResult> scans) =>
      CsvResultWriter(file, scans).writeBomComparison(items);

  @override
  Future<void> writeLicenseComparison(
          File file, Iterable<BomItem> items, Iterable<ScanResult> scans) =>
      CsvResultWriter(file, scans).writeLicensesComparison(items);
}
