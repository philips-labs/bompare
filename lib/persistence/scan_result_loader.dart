import 'dart:io';

import 'package:bompare/persistence/parser/mapping_parser.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';

import '../service/bom_service.dart';
import '../service/domain/scan_result.dart';
import '../service/result_persistence.dart';
import 'persistence_exception.dart';
import 'result_parser.dart';

/// Persistence gateway to scanning results.
class ScanResultLoader implements ResultPersistence {
  final Map<ScannerType, ResultParser> parsers;
  final SpdxMapper spdxMapping;

  ScanResultLoader(this.parsers, this.spdxMapping);

  @override
  Future<void> loadMapping(File file) async {
    await MappingParser(spdxMapping).parse(file);
  }

  @override
  Future<ScanResult> load(ScannerType type, File file) {
    final parser = parsers[type];
    if (parser == null) {
      throw PersistenceException(file, 'No parser registered for ${type}');
    }

    return parser.parse(file);
  }
}
