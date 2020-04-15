import 'dart:convert';
import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:path/path.dart' as path;

/// Decoder for files in WhiteSource "inventory" file format.
class WhiteSourceInventoryResultParser implements ResultParser {
  static const field_name = 'name';
  static const field_version = 'version';
  static const field_group_id = 'groupId';
  static const field_type = 'type';

  @override
  ScanResult parse(File file) {
    if (!file.existsSync()) {
      throw PersistenceException(
          file, 'WhiteSource inventory (JSON) file not found');
    }

    try {
      final result = ScanResult(path.basenameWithoutExtension(file.path));
      final str = file.readAsStringSync();

      final map = jsonDecode(str) as Map<String, dynamic>;
      (map['libraries'] as Iterable)
          .map(_decodeItemId)
          .forEach((id) => result.addItem(id));

      return result;
    } on FormatException catch (e) {
      throw PersistenceException(file, 'Unexpected format: $e');
    }
  }

  ItemId _decodeItemId(dynamic obj) {
    final type = obj[field_type];

    switch (type) {
      case 'Java':
        final version = obj[field_version];
        final name = obj[field_name] as String;
        final package = name.substring(0, name.indexOf('-$version'));
        return ItemId(package, version);
      case 'javascript/Node.js':
      default:
        return ItemId(obj[field_group_id], obj[field_version]);
    }
  }
}
