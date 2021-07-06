/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../service/domain/bom_item.dart';
import '../../service/domain/scan_result.dart';
import '../../service/domain/spdx_mapper.dart';
import '../../service/purl.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';

/// Decoder for files in Tern JSON file format.
/// See https://github.com/tern-tools/tern
///
/// Since the Tern format does not provide a package type, [Purl.defaultType]
/// is assumed.
class TernResultParser implements ResultParser {
  static const field_name = 'name';
  static const field_version = 'version';
  static const field_license = 'pkg_license';

  /// License mapping from name to identifier.
  final SpdxMapper mapper;

  TernResultParser(this.mapper);

  @override
  Future<ScanResult> parse(File file) {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'Tern (JSON) file not found');
    }

    try {
      final result = ScanResult(path.basenameWithoutExtension(file.path));
      final str = file.readAsStringSync();

      final images = jsonDecode(str)['images'] as Iterable;
      images.forEach((image) {
        final layers = image['image']['layers'] as Iterable;
        layers.forEach((layer) {
          final packages = layer['packages'] as Iterable;
          packages.forEach((package) {
            final name = package[field_name] as String;
            final string = package[field_version] as String?;
            final version = string?.startsWith(name) ?? false
                ? string!.substring(name.length + 1)
                : string ?? '';
            final item = BomItem(Purl.of(name: name, version: version));
            final licenses = package[field_license] as String?;
            item.addLicenses(mapper[licenses]);
            result.addItem(item);
          });
        });
      });

      return Future.value(result);
    } on Exception catch (e) {
      return Future.error(PersistenceException(file, 'Unexpected format: $e'));
    }
  }
}
