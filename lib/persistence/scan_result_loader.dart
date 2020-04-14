import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/result_persistence.dart';

class ScanResultLoader implements ResultPersistence {
  final Map<ScannerType, ResultParser> parsers;

  ScanResultLoader(this.parsers);

  @override
  ScanResult load(ScannerType type, File file) {
    final parser = parsers[type];
    if (parser == null) {
      throw PersistenceException(file, 'No parser registered for ${type}');
    }

    return parser.parse(file);
  }
}
