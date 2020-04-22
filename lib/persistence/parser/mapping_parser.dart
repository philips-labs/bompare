import 'dart:convert';
import 'dart:io';

import 'package:bompare/persistence/parser/csv_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';

/// Parser for SPDX mapping CSV file.
/// Expects a comma-separated CSV file without header, providing a source
/// license description string with the corresponding target SPDX code.
class MappingParser {
  final mapping = <String, String>{};

  Future<Map<String, String>> parse(File file) async {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'Mapping file not found');
    }

    try {
      final stream =
          file.openRead().transform(utf8.decoder).transform(LineSplitter());
      await _MappingCsvParser(mapping).parse(stream);
      return mapping;
    } on RangeError {
      throw PersistenceException(
          file, 'Expected at least two columns, separated by a comma');
    }
  }
}

class _MappingCsvParser extends CsvParser {
  final Map<String, String> mapping;

  _MappingCsvParser(this.mapping) : super(hasHeader: false);

  @override
  void dataRow(List<String> columns) {
    mapping[columns[0]] = columns[1];
  }

  @override
  void headerRow(List<String> columns) {
    throw AssertionError('No headers supported in this format');
  }
}
