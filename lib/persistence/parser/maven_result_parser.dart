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

class MavenResultParser implements ResultParser {
  static final brackets = RegExp(r'\((.+?)\)');

  final SpdxMapper spdxMapper;

  MavenResultParser(this.spdxMapper);

  @override
  Future<ScanResult> parse(File file) async {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'Maven licence (.txt) file not found');
    }

    final stream =
        file.openRead().transform(utf8.decoder).transform(LineSplitter());
    final result = ScanResult(path.basenameWithoutExtension(file.path));

    await stream.forEach((line) => _parseLine(line, result));

    return result;
  }

  void _parseLine(String line, ScanResult result) {
    final matches = brackets.allMatches(line).toList();
    if (matches.isEmpty) return;

    final licenseTexts = <String>[];
    for (var i = 0; i < matches.length; i++) {
      final string = matches[i].group(1);

      if (i < matches.length - 1) {
        licenseTexts.add(string);
      } else {
        result.addItem(_itemFromPackage(string, licenseTexts));
      }
    }
  }

  ItemId _itemFromPackage(String text, Iterable<String> licenses) {
    final name = text.substring(0, text.indexOf(' - '));
    final pos = name.lastIndexOf(':');
    final package = name.substring(0, pos).replaceAll(':', '/');
    final version = name.substring(pos + 1);

    final itemId = ItemId(package, version);
    licenses.forEach((l) => itemId.addLicenses(spdxMapper[l]));
    return itemId;
  }
}
