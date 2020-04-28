import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:path/path.dart' as path;

import '../../service/domain/item_id.dart';
import '../../service/domain/scan_result.dart';
import '../persistence_exception.dart';
import '../result_parser.dart';
import 'csv_parser.dart';

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
    return Future.forEach(sourceFiles, (f) {
      final data = f.content as List<int>;
      return apply(Stream.value(data));
    });
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
    return await Future.forEach(sourceFiles, (f) => apply(f.openRead()));
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

/// Dictionary to lookup licenses per [ItemId].
class _LicenseDictionary {
  final _dict = <ItemId, Set<String>>{};

  void addLicenses(ItemId id, Iterable<String> values) {
    final licenses = _dict[id] ?? <String>{};
    licenses.addAll(values);
    _dict[id] = licenses;
  }

  Set<String> operator [](ItemId id) => _dict[id];
}

/// Extracts license info per component from the Black Duck components CSV file.
class _BlackDuckComponentsCsvParser extends CsvParser {
  /// Note: Keys are Black Duck *components*.
  final _LicenseDictionary _dictionary;
  final SpdxMapper mapper;

  var _componentNameIndex = -1;
  var _componentVersionIndex = -1;
  var _licensesIndex = -1;

  _BlackDuckComponentsCsvParser(this._dictionary, this.mapper);

  @override
  void headerRow(List<String> columns) {
    _componentNameIndex = columns.indexOf('Component name');
    _componentVersionIndex = columns.indexOf('Component version name');
    _licensesIndex = columns.indexOf('License names');
  }

  @override
  void dataRow(List<String> columns) {
    final component = columns[_componentNameIndex];
    final version = columns[_componentVersionIndex];
    final id = ItemId(component, version);
    final license = columns[_licensesIndex];
    _dictionary.addLicenses(id, mapper[license]);
  }
}

/// Extracts dependencies from a Black Duck source CSV.
class _BlackDuckSourceCsvParser extends CsvParser {
  final ScanResult result;
  final _LicenseDictionary licenseDictionary;
  final assumed = <ItemId>{};

  var _versionIndex = -1;
  var _originIndex = -1;
  var _nameIndex = -1;
  var _componentNameIndex = -1;
  var _componentVersionIndex = -1;

  _BlackDuckSourceCsvParser(this.result, this.licenseDictionary);

  @override
  void headerRow(List<String> columns) {
    _versionIndex = columns.indexOf('Component origin version name');
    _originIndex = columns.indexOf('Origin name');
    _nameIndex = columns.indexOf('Origin name id');
    _componentNameIndex = columns.indexOf('Component name');
    _componentVersionIndex = columns.indexOf('Component version name');
  }

  @override
  void dataRow(List<String> columns) {
    final type = columns[_originIndex];
    switch (type) {
      case 'unknown':
        break;
      case 'maven':
      case 'github':
        result.addItem(_itemIdFromColumns(columns, ':'));
        break;
      case 'npmjs':
        result.addItem(_itemIdFromColumns(columns, '/'));
        break;
      case 'long_tail':
        result.addItem(_itemIdFromColumns(columns, '#'));
        break;
      default:
        final id = _itemIdFromColumns(columns, '/');
        if (!assumed.contains(id)) {
          print('Warning: Assumed $id for Black Duck type "$type"');
          assumed.add(id);
        }
        result.addItem(id);
    }
  }

  ItemId _itemIdFromColumns(List<String> columns, String pattern) {
    final name = _stripLastPart(columns[_nameIndex], pattern);
    final version = columns[_versionIndex];
    final itemId = ItemId(name, version);

    final componentName = columns[_componentNameIndex];
    final componentVersion = columns[_componentVersionIndex];
    final component = ItemId(componentName, componentVersion);
    itemId.addLicenses(licenseDictionary[component] ?? {});

    return itemId;
  }

  String _stripLastPart(String name, Pattern pattern) {
    final index = name.lastIndexOf(pattern);
    if (index < 0) {
      print('Warning: Could not strip version from Black Duck dependency $name '
          'at last "$pattern"');
      return name;
    }
    return name.substring(0, index);
  }
}
