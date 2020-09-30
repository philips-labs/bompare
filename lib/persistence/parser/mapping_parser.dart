/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';

import '../../service/domain/spdx_mapper.dart';
import '../parser/csv_parser.dart';
import '../persistence_exception.dart';

/// Parser for SPDX mapping CSV file.
/// Expects a comma-separated CSV file without header, providing a source
/// license description string with the corresponding target SPDX code.
class MappingParser {
  final SpdxMapper mapper;

  MappingParser(this.mapper);

  Future<void> parse(File file) async {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'Mapping file not found');
    }

    final stream =
        file.openRead().transform(utf8.decoder).transform(LineSplitter());
    await _MappingCsvParser(mapper).parse(stream);
  }
}

class _MappingCsvParser extends CsvParser {
  final SpdxMapper mapper;

  _MappingCsvParser(this.mapper) : super(hasHeader: false);

  @override
  void dataRow(List<String> columns) {
    final license = (columns.length > 1) ? columns[1] : columns[0];
    mapper[columns[0].trim()] = license.trim();
  }

  @override
  void headerRow(List<String> columns) {
    // No headers in this file
  }
}
