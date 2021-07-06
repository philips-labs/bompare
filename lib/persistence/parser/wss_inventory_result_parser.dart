/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as path;

import '../../service/domain/bom_item.dart';
import '../../service/domain/scan_result.dart';
import '../../service/domain/spdx_mapper.dart';
import '../../service/purl.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';

/// Decoder for files in WhiteSource "inventory" file format.
class WhiteSourceInventoryResultParser implements ResultParser {
  static const field_name = 'name';
  static const field_version = 'version';
  static const field_group_id = 'groupId';
  static const field_artifact_id = 'artifactId';
  static const field_type = 'type';

  final SpdxMapper mapper;
  final assumed = <BomItem>{};

  WhiteSourceInventoryResultParser(this.mapper);

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
    } on Exception catch (e) {
      return Future.error(PersistenceException(file, 'Unexpected format: $e'));
    }
  }

  BomItem _decodeItem(dynamic obj) {
    final item = _decodeItemId(obj);
    _decodeLicenses(item, obj);
    return item;
  }

  BomItem _decodeItemId(dynamic obj) {
    final origin = obj[field_type] as String? ?? '?';
    final type = _purlTypes[origin] ?? 'generic';
    final version = obj[field_version] as String? ?? '';
    final name = obj[field_name] as String?;
    final group = obj[field_group_id] as String?;
    final artifact = obj[field_artifact_id] as String?;

    switch (origin) {
      case 'Java':
        final identifier =
            (group?.isNotEmpty ?? false ? '$group/' : '') + (artifact ?? '?');
        return BomItem(Purl.of(type: type, name: identifier, version: version));
      case 'javascript/Node.js':
      case 'JavaScript':
      case 'Alpine':
        return BomItem(
            Purl.of(type: type, name: group ?? '?', version: version));
      case 'Debian':
        final n = (group?.isNotEmpty ?? false)
            ? group!
            : name?.substring(0, name.indexOf(version) - 1) ?? '?';
        return BomItem(Purl.of(type: type, name: n, version: version));
      case 'ActionScript':
      case 'Source Library':
      case 'Unknown Library':
        return BomItem(Purl.of(
            type: type, name: artifact ?? name ?? '?', version: version));
      case 'RPM':
        final first = name?.substring(0, name.lastIndexOf('-')) ?? '';
        final pos = first.lastIndexOf('-');
        final v = first.substring(pos + 1);
        return BomItem(Purl.of(
            type: type,
            name: first.substring(0, pos),
            version: v.substring(math.max(v.indexOf(':') + 1, 0))));
      default:
        final item =
            BomItem(Purl.of(type: type, name: group ?? '?', version: version));
        if (!assumed.contains(item)) {
          print(
              'Warning: Assumed $item for WhiteSource type "$origin" -> "$group", "$version');
          assumed.add(item);
        }
        return item;
    }
  }

  void _decodeLicenses(BomItem item, dynamic obj) {
    final licenses = obj['licenses'] as Iterable? ?? [];
    licenses.forEach((lic) {
      final name = lic['name'] ?? '';
      item.addLicenses(mapper[name]);
    });
  }
}

const _purlTypes = {
  'JavaScript': 'npm',
  'javascript/Node.js': 'npm',
  'Java': 'maven',
  'Alpine': 'alpine',
  'Debian': 'deb',
  'ActionScript': 'generic',
  'Source Library': 'generic',
  'Unknown Library': 'generic',
  'RPM': 'rpm',
  '(not defined)': 'generic',
};
