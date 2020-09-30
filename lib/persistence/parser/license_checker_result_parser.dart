/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../service/domain/item_id.dart';
import '../../service/domain/scan_result.dart';
import '../../service/domain/spdx_mapper.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';
import 'csv_parser.dart';

/// Decoder for files in "NPM license-checker" file format.
/// This format consists of a CSV file with a header line.
class LicenseCheckerResultParser implements ResultParser {
  /// License mapping from name to identifier.
  final SpdxMapper mapper;

  LicenseCheckerResultParser(this.mapper);

  @override
  Future<ScanResult> parse(File file) async {
    if (!file.existsSync()) {
      throw PersistenceException(
          file, 'NPM license-checker (CSV) file not found');
    }

    try {
      final result = ScanResult(path.basenameWithoutExtension(file.path));

      final stream =
          file.openRead().transform(utf8.decoder).transform(LineSplitter());
      await _LicenseFileParser(result, mapper).parse(stream);

      return Future.value(result);
    } on Exception catch (e) {
      return Future.error(PersistenceException(file, 'Unexpected format: $e'));
    }
  }
}

class _LicenseFileParser extends CsvParser {
  final ScanResult result;
  final SpdxMapper mapper;

  int _module_column;
  int _license_column;

  _LicenseFileParser(this.result, this.mapper);

  @override
  void dataRow(List<String> columns) {
    final module = columns[_module_column];
    final pos = module.lastIndexOf('@');
    final version = module.substring(pos + 1);
    final name = module.substring(0, pos);
    final licenses = mapper[columns[_license_column]];
    final item = ItemId(name, version)..addLicenses(licenses);
    result.addItem(item);
  }

  @override
  void headerRow(List<String> columns) {
    _module_column = columnIndexOf('module name', columns);
    _license_column = columnIndexOf('license', columns);
  }
}
