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

/// Decoder for files in JK1 file format.
/// See https://github.com/jk1/Gradle-License-Report
class Jk1ResultParser implements ResultParser {
  static const field_module_name = 'moduleName';
  static const field_module_version = 'moduleVersion';
  static const field_module_license = 'moduleLicense';

  /// License mapping from name to identifier.
  final SpdxMapper mapper;

  Jk1ResultParser(this.mapper);

  @override
  Future<ScanResult> parse(File file) {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'JK1 (JSON) file not found');
    }

    try {
      final result = ScanResult(path.basenameWithoutExtension(file.path));
      final str = file.readAsStringSync();

      (jsonDecode(str)['dependencies'] as Iterable).map((obj) {
        final package = (obj[field_module_name] as String).replaceAll(':', '/');
        final version = obj[field_module_version];
        var license = obj[field_module_license];
        return ItemId(package, version)..addLicenses(mapper[license]);
      }).forEach((id) => result.addItem(id));

      return Future.value(result);
    } on Exception catch (e) {
      return Future.error(PersistenceException(file, 'Unexpected format: $e'));
    }
  }
}
