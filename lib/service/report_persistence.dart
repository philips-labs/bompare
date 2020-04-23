import 'dart:io';

import 'domain/item_id.dart';
import 'domain/scan_result.dart';

abstract class ReportPersistence {
  /// Writes bill-of-material comparison as [ids] to the indicated [file] for [scans].
  Future<void> writeBomComparison(
      File file, Iterable<ItemId> ids, Iterable<ScanResult> scans);

  /// Writes licenses comparison as [ids] to the indicated [file] for [scans].
  Future<void> writeLicenseComparison(
      File file, Iterable<ItemId> ids, Iterable<ScanResult> scans);
}
