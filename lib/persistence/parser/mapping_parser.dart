import 'dart:convert';
import 'dart:io';

import 'package:bompare/persistence/parser/csv_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';

/// Parser for SPDX mapping CSV file.
/// Expects a comma-separated CSV file without header, providing a source
/// license description string with the corresponding target SPDX code.
class MappingParser {
  Future<Map<String, String>> parse(File file) async {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'Mapping file not found');
    }

    final mapping = <String, String>{};
    final stream =
        file.openRead().transform(utf8.decoder).transform(LineSplitter());
    await _MappingCsvParser(mapping).parse(stream);
    return mapping;
  }
}

class _MappingCsvParser extends CsvParser {
  final Map<String, String> mapping;

  _MappingCsvParser(this.mapping) : super(hasHeader: false);

  @override
  void dataRow(List<String> columns) {
    final license = (columns.length > 1) ? columns[1] : columns[0];
    mapping[columns[0].toLowerCase()] = license;
  }

  @override
  void headerRow(List<String> columns) {
    throw AssertionError('No headers supported in this format');
  }
}
