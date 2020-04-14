import 'dart:io';

import 'bom_service.dart';
import 'domain/scan_result.dart';

abstract class ResultPersistence {
  /// Returns the [type] scanning result for the [file].
  ScanResult load(ScannerType type, File file);
}
