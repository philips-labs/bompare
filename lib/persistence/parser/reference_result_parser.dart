/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../service/domain/item_id.dart';
import '../../service/domain/scan_result.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';

/// Decoder for files in "reference" file format.
/// This format consists of a list of JSON objects containing (String) 'name',
/// (String) 'version', and (array of String) 'licenses' fields.
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
          .map((obj) => ItemId(obj[field_name], obj[field_version]))
          .forEach((id) => result.addItem(id));

      return Future.value(result);
    } on Exception catch (e) {
      return Future.error(PersistenceException(file, 'Unexpected format: $e'));
    }
  }
}
