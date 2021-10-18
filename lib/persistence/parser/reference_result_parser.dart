/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';

import 'package:bompare/service/purl.dart';
import 'package:path/path.dart' as path;

import '../../service/domain/bom_item.dart';
import '../../service/domain/scan_result.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';

/// Decoder for files in "reference" file format.
///
/// This format consists of a list of JSON objects containing (String) 'name',
/// (String) 'version', and (array of String) 'licenses' fields.
///
/// The Package URL type of the [BomItem] assumes [Purl.defaultType].
class ReferenceResultParser implements ResultParser {
  static const field_name = 'name';
  static const field_version = 'version';

  @override
  Future<ScanResult> parse(File file) {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'Reference (JSON) file not found');
    }

    try {
      final result = ScanResult(path.basenameWithoutExtension(file.path));
      final str = file.readAsStringSync();

      (jsonDecode(str) as Iterable)
          // assuming this is only used for NPM packages
          .map((obj) => BomItem(
              Purl.of(name: obj[field_name], version: obj[field_version])))
          .forEach((id) => result.addItem(id));

      return Future.value(result);
    } on Exception catch (e) {
      return Future.error(PersistenceException(file, 'Unexpected format: $e'));
    }
  }
}
