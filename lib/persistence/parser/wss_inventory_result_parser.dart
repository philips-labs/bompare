import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../service/domain/item_id.dart';
import '../../service/domain/scan_result.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';

/// Decoder for files in WhiteSource "inventory" file format.
class WhiteSourceInventoryResultParser implements ResultParser {
  static const field_name = 'name';
  static const field_version = 'version';
  static const field_group_id = 'groupId';
  static const field_type = 'type';

  final assumed = <ItemId>{};

  @override
  Future<ScanResult> parse(File file) {
    if (!file.existsSync()) {
      throw PersistenceException(
          file, 'WhiteSource inventory (JSON) file not found');
    }

    try {
      final result = ScanResult(path.basenameWithoutExtension(file.path));
      final str = file.readAsStringSync();

      final map = jsonDecode(str) as Map<String, dynamic>;
      (map['libraries'] as Iterable)
          .map(_decodeItem)
          .forEach((itemId) => result.addItem(itemId));

      return Future.value(result);
    } on FormatException catch (e) {
      return Future.error(PersistenceException(file, 'Unexpected format: $e'));
    }
  }

  ItemId _decodeItem(dynamic obj) {
    final itemId = _decodeItemId(obj);

    _decodeLicenses(itemId, obj);
    return itemId;
  }

  ItemId _decodeItemId(dynamic obj) {
    final type = obj[field_type];

    switch (type) {
      case 'Java':
        final version = obj[field_version] ?? '';
        final name = obj[field_name] as String;
        final package = _packageFromName(name, version);
        return ItemId(package, version);
      case 'javascript/Node.js':
      case 'JavaScript':
        return ItemId(obj[field_group_id], obj[field_version]);
      case 'ActionScript':
      case 'Source Library':
      case 'Unknown Library':
        return ItemId(obj[field_name], obj[field_version]);
      default:
        final id = ItemId(obj[field_group_id], obj[field_version]);
        if (!assumed.contains(id)) {
          stderr.writeln('Warning: Assumed $id for WhiteSource type "$type"');
          assumed.add(id);
        }
        return id;
    }
  }

  String _packageFromName(String name, String version) =>
      (version.isEmpty || !name.contains(version))
          ? name
          : name.substring(0, name.indexOf('$version') - 1);

  void _decodeLicenses(ItemId itemId, dynamic obj) {
    final licenses = obj['licenses'] as Iterable ?? [];
    licenses.forEach((lic) {
      final license = lic['name'];
      itemId.addLicense(license);
    });
  }
}
