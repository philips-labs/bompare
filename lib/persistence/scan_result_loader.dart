import 'dart:io';

import 'package:bompare/persistence/parser/mapping_parser.dart';

import '../service/bom_service.dart';
import '../service/domain/scan_result.dart';
import '../service/result_persistence.dart';
import 'parser/spdx_licenses.dart' as spdx;
import 'persistence_exception.dart';
import 'result_parser.dart';

/// Persistence gateway to scanning results.
class ScanResultLoader implements ResultPersistence {
  final Map<ScannerType, ResultParser> parsers;
  final Map<String, String> spdxMapping;

  ScanResultLoader(this.parsers, this.spdxMapping) {
    spdx.dictionary.values.forEach((license) => spdxMapping[license] = license);
  }

  @override
  Future<void> loadMapping(File file) async {
    spdxMapping.addAll(await MappingParser().parse(file));
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
