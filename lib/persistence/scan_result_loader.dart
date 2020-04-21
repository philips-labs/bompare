import 'dart:io';

import '../service/bom_service.dart';
import '../service/domain/scan_result.dart';
import '../service/result_persistence.dart';
import 'persistence_exception.dart';
import 'result_parser.dart';

class ScanResultLoader implements ResultPersistence {
  final Map<ScannerType, ResultParser> parsers;

  ScanResultLoader(this.parsers);

  @override
  Future<ScanResult> load(ScannerType type, File file) {
    final parser = parsers[type];
    if (parser == null) {
      throw PersistenceException(file, 'No parser registered for ${type}');
    }

    return parser.parse(file);
  }
}
