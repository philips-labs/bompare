import 'dart:io';

import 'package:bompare/persistence/report/csv_result_writer.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/report_persistence.dart';

class ReportWriter implements ReportPersistence {
  @override
  Future<void> writeBomComparison(
          File file, Iterable<ItemId> ids, List<ScanResult> scans) =>
      CsvResultWriter(file, scans).writeBomComparison(ids);
}
