/*
 * Copyright (c) 2020-2020, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../../service/domain/bom_item.dart';
import '../../service/domain/scan_result.dart';
import '../../service/domain/spdx_mapper.dart';
import '../../service/purl.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';
import 'csv_parser.dart';

/// Decoder for Black Duck export files.
class BlackDuckResultParser implements ResultParser {
  static const source_file_prefix = 'source_';
  static const components_file_prefix = 'components_';

  final SpdxMapper mapper;

  BlackDuckResultParser(this.mapper);

  @override
  Future<ScanResult> parse(File file) async {
    if (file.existsSync()) {
      return _processZipFile(file);
    }

    final directory = Directory(file.path);
    if (directory.existsSync()) {
      return _processDirectory(directory);
    }

    throw PersistenceException(
        file, 'BlackDuck ZIP file or directory not found');
  }

  Future<ScanResult> _processZipFile(File file) async {
    final result = ScanResult(path.basenameWithoutExtension(file.path));
    final buffer = file.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(buffer);
    final licenses = _LicenseDictionary();

    await _applyToArchive(archive, components_file_prefix,
        (Stream<List<int>> stream) => _parseLicenseStream(stream, licenses));
    await _applyToArchive(
        archive,
        source_file_prefix,
        (Stream<List<int>> stream) =>
            _parseSourceStream(stream, result, licenses));

    return result;
  }

  Future<void> _applyToArchive(Archive archive, String prefix,
      void Function(Stream<List<int>> stream) apply) async {
    final sourceFiles = archive
        .where((f) => f.isFile)
        .where((f) => path.basename(f.name).startsWith(prefix));
    return Future.forEach<ArchiveFile>(
        sourceFiles, (f) => apply(Stream.value(f.content as List<int>)));
  }

  Future<ScanResult> _processDirectory(Directory directory) async {
    final result = ScanResult(path.basename(directory.path));
    final licenses = _LicenseDictionary();

    await _applyToDirectory(directory, components_file_prefix,
        (Stream<List<int>> stream) => _parseLicenseStream(stream, licenses));
    await _applyToDirectory(
        directory,
        source_file_prefix,
        (Stream<List<int>> stream) =>
            _parseSourceStream(stream, result, licenses));

    return result;
  }

  Future<void> _applyToDirectory(Directory directory, String prefix,
      void Function(Stream<List<int>> stream) apply) async {
    final sourceFiles = directory
        .listSync()
        .whereType<File>()
        .where((f) => path.basename(f.path).startsWith(prefix));
    return await Future.forEach<File>(sourceFiles, (f) => apply(f.openRead()));
  }

  Future<void> _parseLicenseStream(
          Stream<List<int>> stream, _LicenseDictionary dictionary) =>
      _BlackDuckComponentsCsvParser(dictionary, mapper)
          .parse(_toLineStream(stream));

  Future<void> _parseSourceStream(Stream<List<int>> stream, ScanResult result,
          _LicenseDictionary licenses) =>
      _BlackDuckSourceCsvParser(result, licenses).parse(_toLineStream(stream));

  Stream<String> _toLineStream(Stream<List<int>> stream) =>
      stream.transform(utf8.decoder).transform(LineSplitter());
}

/// Dictionary to lookup licenses per [BomItem].
class _LicenseDictionary {
  /// Version id -> Licenses
  final _dict = <String, Set<String>>{};

  void addLicenses(String versionId, Iterable<String> values) {
    final licenses = _dict[versionId] ?? {};
    licenses.addAll(values);
    _dict[versionId] = licenses;
  }

  Set<String>? operator [](String versionId) => _dict[versionId];
}

/// Extracts license info per component from the Black Duck components CSV file.
class _BlackDuckComponentsCsvParser extends CsvParser {
  /// Note: Keys are Black Duck *components*.
  final _LicenseDictionary _dictionary;
  final SpdxMapper mapper;

  late final int _licensesIndex;
  late final int _componentVersionIdIndex;

  _BlackDuckComponentsCsvParser(this._dictionary, this.mapper);

  @override
  void headerRow(List<String> columns) {
    _licensesIndex = columnIndexOf('License names', columns);
    _componentVersionIdIndex = columnIndexOf('Version id', columns);
  }

  @override
  void dataRow(List<String> columns) {
    final license = columns[_licensesIndex];
    final versionId = columns[_componentVersionIdIndex];
    _dictionary.addLicenses(versionId, mapper[license]);
  }
}

/// Extracts dependencies from a Black Duck source CSV.
class _BlackDuckSourceCsvParser extends CsvParser {
  final ScanResult result;
  final _LicenseDictionary licenseDictionary;
  final assumed = <BomItem>{};

  late final int _versionIndex;
  late final int _originIndex;
  late final int _nameIndex;
  late final int _componentNameIndex;
  late final int _componentVersionIndex;
  late final int _componentVersionIdIndex;

  _BlackDuckSourceCsvParser(this.result, this.licenseDictionary);

  @override
  void headerRow(List<String> columns) {
    _versionIndex = columnIndexOf('Component origin version name', columns);
    _originIndex = columnIndexOf('Origin name', columns);
    _nameIndex = columnIndexOf('Origin name id', columns);
    _componentNameIndex = columnIndexOf('Component name', columns);
    _componentVersionIndex = columnIndexOf('Component version name', columns);
    _componentVersionIdIndex = columnIndexOf('Version id', columns);
  }

  @override
  void dataRow(List<String> columns) {
    final origin = columns[_originIndex];
    final nameColumn = columns[_nameIndex];
    final versionColumn = columns[_versionIndex];
    final versionId = columns[_componentVersionIdIndex];
    final type = _purlType[origin] ?? origin;

    late BomItem item;
    switch (origin) {
      case '': // Signature scan result
        final component = columns[_componentNameIndex];
        final componentVersion = columns[_componentVersionIndex];
        item = BomItem(Purl.of(
            type: 'generic', name: component, version: componentVersion));
        break;
      case 'maven':
      case 'github':
        final name2 = _stripFromLast(nameColumn, ':').replaceAll(':', '/');
        item =
            BomItem(Purl.of(type: type, name: name2, version: versionColumn));
        break;
      case 'npmjs':
      case 'nuget':
        final name2 = _stripFromLast(nameColumn, '/');
        item =
            BomItem(Purl.of(type: type, name: name2, version: versionColumn));
        break;
      case 'alpine':
        final name = _stripSeparatedPostFix(nameColumn, versionColumn);
        final version = _stripFromLast(versionColumn, '/');
        item = BomItem(Purl.of(type: type, name: name, version: version));
        break;
      case 'centos':
        final name = _stripFrom(nameColumn, '/');
        final temp = versionColumn.substring(versionColumn.indexOf(':') + 1);
        final version = _stripFrom(temp, '-');
        item = BomItem(Purl.of(type: type, name: name, version: version));
        break;
      case 'debian':
        final version = _stripFrom(versionColumn, '/');
        final name = _stripSeparatedPostFix(nameColumn, version);
        item = BomItem(Purl.of(type: type, name: name, version: version));
        break;
      case 'long_tail':
        final name = _stripFromLast(nameColumn, '#');
        item = BomItem(Purl.of(type: type, name: name, version: versionColumn));
        break;
      default:
        final name = _stripFromLast(nameColumn, '/');
        item = BomItem(Purl.of(type: type, name: name, version: versionColumn));
        if (!assumed.contains(item)) {
          print(
              'Warning: Assumed ${item.purl} for Black Duck type "$origin" -> "$nameColumn"');
          assumed.add(item);
        }
    }
    item.addLicenses(licenseDictionary[versionId] ?? {});
    result.addItem(item);
  }

  String _stripFrom(String string, Pattern pattern) {
    final index = string.indexOf(pattern);
    return (index < 0) ? string : string.substring(0, index);
  }

  String _stripFromLast(String string, Pattern pattern) {
    final index = string.lastIndexOf(pattern);
    return (index < 0) ? string : string.substring(0, index);
  }

  String _stripSeparatedPostFix(String string, String postfix) {
    final index = string.lastIndexOf(postfix);
    return (index < 0) ? string : string.substring(0, index - 1);
  }
}

const _purlType = {
  'arch_linux': 'arch',
  'centos': 'rpm',
  'fedora': 'rpm',
  'redhat': 'rpm',
  'opensuse': 'rpm',
  'crates': 'cargo',
  'dart': 'pub',
  'debian': 'deb',
  'ubuntu': 'deb',
  'long_tail': 'generic',
  'npmjs': 'npm',
  'rubygems': 'gem',
};
