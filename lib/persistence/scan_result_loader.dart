import 'dart:io';

import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/result_persistence.dart';

class ScanResultLoader implements ResultPersistence {
  final Map<ScannerType, ResultPersistence> parsers;

  ScanResultLoader(this.parsers);

  @override
  ScanResult load(ScannerType type, File file) {
    // TODO: implement load
    return null;
  }
}
