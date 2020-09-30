/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';

import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:path/path.dart' as path;

import '../../service/domain/item_id.dart';
import '../../service/domain/scan_result.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';
import 'purl.dart';

/// Parser for SPDX tag-value files.
/// See https://spdx.github.io/spdx-spec
/// Assumes "concluded license" as the (SPDX) license.
class SpdxResultParser implements ResultParser {
  final SpdxMapper mapper;
  SpdxResultParser(this.mapper);

  @override
  Future<ScanResult> parse(File file) async {
    if (!file.existsSync()) {
      throw PersistenceException(file, 'SPDX tag-value file not found');
    }

    try {
      final parser =
          _LineParser(path.basenameWithoutExtension(file.path), mapper);
      await for (var line in file
          .openRead()
          .transform(utf8.decoder)
          .transform(LineSplitter())) {
        parser.parse(line);
      }
      return parser.result;
    } on FormatException catch (e) {
      throw PersistenceException(file, e.toString());
    }
  }
}

/// Parser implementation collecting the scan result.
class _LineParser {
  final SpdxMapper mapper;
  final ScanResult _result;

  String _packageName;
  String _license;
  ItemId _itemId;
  var _isInTextValue = false;

  _LineParser(String name, this.mapper) : _result = ScanResult(name);

  ScanResult get result {
    _addCurrentItem();
    return _result;
  }

  void parse(String line) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('##')) {
      return;
    }

    if (_isInTextValue) {
      _isInTextValue = !line.endsWith('</text>');
      return;
    }

    _parseTagLine(line);
  }

  void _parseTagLine(String line) {
    final pos = line.indexOf(':');
    if (pos < 0) {
      throw FormatException('Not a valid SPDX tag-value line: "$line"');
    }

    final tag = line.substring(0, pos);
    final value = line.substring(pos + 1).trim();

    _parseTagValue(tag, value);
  }

  void _parseTagValue(String tag, String value) {
    _isInTextValue = value.startsWith('<text>');
    if (_isInTextValue) return;

    switch (tag) {
      case 'PackageName':
        _addCurrentItem();
        _packageName = value;
        break;
      case 'ExternalRef':
        _processExternalRef(value);
        break;
      case 'PackageLicenseConcluded':
        if (value != 'NOASSERTION') {
          _license = value;
        }
        break;
    }
  }

  void _processExternalRef(String value) {
    final parts = value.split(' ');
    if (parts.length != 3 ||
        parts[0] != 'PACKAGE-MANAGER' ||
        parts[1] != 'purl') return;

    var purl = Purl(parts[2]);
    _itemId = ItemId(purl.name, purl.version);
  }

  void _addCurrentItem() {
    if (_packageName == null) return;

    if (_itemId == null) {
      throw FormatException(
          'Missing external PACKAGE-MANAGER purl reference in package "$_packageName"');
    }

    if (_license != null) {
      _itemId.addLicenses(mapper[_license]);
      _license = null;
    }

    _result.addItem(_itemId);
    _itemId = null;
    _packageName = null;
  }
}
