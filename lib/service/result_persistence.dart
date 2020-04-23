import 'dart:io';

import 'bom_service.dart';
import 'domain/scan_result.dart';

abstract class ResultPersistence {
  /// Returns the key-value mapping stored in [file].
  Future<void> loadMapping(File file);

  /// Returns the [type] scanning result for the [file].
  Future<ScanResult> load(ScannerType type, File file);
}
