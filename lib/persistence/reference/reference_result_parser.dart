import 'dart:convert';
import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:path/path.dart' as path;

/// Decoder for files in "reference" file format.
/// This format consists of a list of JSON objects containing (String) 'name',
/// (String) 'version', and (array of String) 'licenses' fields.
class ReferenceResultParser implements ResultParser {
  static const field_name = 'name';

  @override
  ScanResult parse(File file) {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'Reference file not found');
    }

    try {
      final result = ScanResult(path.basenameWithoutExtension(file.path));
      final str = file.readAsStringSync();

      (jsonDecode(str) as Iterable)
          .map((obj) => ItemId(obj[field_name], obj['version']))
          .forEach((id) => result.addItem(id));

      return result;
    } on FormatException {
      throw PersistenceException(file, 'Unexpected format');
    }
  }
}
