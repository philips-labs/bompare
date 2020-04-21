import 'dart:io';

import '../service/domain/item_id.dart';
import '../service/domain/scan_result.dart';
import '../service/report_persistence.dart';
import 'report/csv_result_writer.dart';

class ReportWriter implements ReportPersistence {
  @override
  Future<void> writeBomComparison(
          File file, Iterable<ItemId> ids, List<ScanResult> scans) =>
      CsvResultWriter(file, scans).writeBomComparison(ids);
}
