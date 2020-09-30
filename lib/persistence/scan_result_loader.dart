/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

import '../service/bom_service.dart';
import '../service/domain/scan_result.dart';
import '../service/domain/spdx_mapper.dart';
import '../service/result_persistence.dart';
import 'parser/mapping_parser.dart';
import 'persistence_exception.dart';
import 'result_parser.dart';

/// Persistence gateway to scanning results.
class ScanResultLoader implements ResultPersistence {
  final Map<ScannerType, ResultParser> parsers;
  final SpdxMapper spdxMapping;

  ScanResultLoader(this.parsers, this.spdxMapping);

  @override
  Future<void> loadMapping(File file) async {
    await MappingParser(spdxMapping).parse(file);
  }

  @override
  Future<ScanResult> load(ScannerType type, Glob glob) async {
    final parser = _resultParserFor(type, glob);
    final result = ScanResult(path.basenameWithoutExtension(glob.pattern));
    var found = false;

    await Future.forEach(glob.listSync(), (file) async {
      if (file is File) {
        result.merge(await parser.parse(file));
        found = true;
      }
    });

    if (!found) {
      throw PersistenceException(glob, 'Pattern did not match any file');
    }

    return result;
  }

  ResultParser _resultParserFor(ScannerType type, Glob glob) {
    final parser = parsers[type];
    if (parser == null) {
      throw PersistenceException(glob, 'No parser registered for ${type}');
    }
    return parser;
  }
}
