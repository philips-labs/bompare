/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';

import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:path/path.dart' as path;

import '../../service/domain/bom_item.dart';
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
      final parser = _LineParser();
      await for (var line in file
          .openRead()
          .transform(utf8.decoder)
          .transform(LineSplitter())) {
        parser.parse(line);
      }
      return _resultFor(
          path.basenameWithoutExtension(file.path), parser.packages);
    } on FormatException catch (e) {
      throw PersistenceException(file, e.toString());
    }
  }

  ScanResult _resultFor(String name, Iterable<_Package> packages) {
    final result = ScanResult(name);
    packages.forEach((pkg) {
      final item = BomItem(pkg.purl.name, pkg.purl.version)
        ..addLicenses(mapper[pkg.license]);
      result.addItem(item);
    });
    return result;
  }
}

/// Parser implementation collecting the scan result.
class _LineParser {
  final _packages = <_Package>[];
  final _customLicenses = <String, String>{};

  String? _packageName;
  String? _license;
  String? _licenseId;
  _Package? _currentPackage;
  var _isInTextValue = false;

  Iterable<_Package> get packages {
    _addCurrentPackage();
    _applyCustomLicenses();
    return _packages;
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
    if (_isInTextValue || !_hasValue(value)) return;

    switch (tag) {
      case 'PackageName':
        _addCurrentPackage();
        _packageName = value;
        break;
      case 'ExternalRef':
        _processExternalRef(value);
        break;
      case 'PackageLicenseConcluded':
        _license = value;
        break;
      case 'PackageLicenseDeclared':
        if (value != 'NOASSERTION' && _license == null) {
          _license = value;
        }
        break;
      case 'LicenseID':
        _licenseId = value;
        break;
      case 'LicenseName':
        if (_licenseId != null) {
          _customLicenses[_licenseId!] = value;
        }
        _licenseId = null;
    }
  }

  bool _hasValue(String value) =>
      value.trim().isNotEmpty && value != 'NOASSERTION';

  void _processExternalRef(String value) {
    final parts = value.split(' ');
    if (parts.length != 3 ||
        parts[0] != 'PACKAGE-MANAGER' ||
        parts[1] != 'purl') return;

    var purl = Purl(parts[2]);
    _currentPackage = _Package(purl);
  }

  void _addCurrentPackage() {
    if (_packageName == null) return;

    if (_currentPackage == null) {
      print(
          'Warning: Skipping package "$_packageName" because it defines no Package URL');
      return;
    }

    if (_license != null) {
      _currentPackage!.license = _license!;
      _license = null;
    }

    _packages.add(_currentPackage!);
    _currentPackage = null;
    _packageName = null;
  }

  void _applyCustomLicenses() {
    void mergeCustomLicenses(_Package pkg) {
      _customLicenses.forEach((id, name) {
        pkg.license = pkg.license.replaceAll(id, name);
      });
    }

    _packages.forEach((pkg) {
      late String before;
      do {
        before = pkg.license;
        mergeCustomLicenses(pkg);
      } while (pkg.license != before);
    });
  }
}

class _Package {
  final Purl purl;
  String license = '';

  _Package(this.purl);
}
