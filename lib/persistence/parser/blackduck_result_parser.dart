import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:path/path.dart' as path;

import '../persistence_exception.dart';
import '../result_parser.dart';

class BlackDuckResultParser implements ResultParser {
  static const source_file_prefix = 'source_';

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

    await _applyToArchive(archive, source_file_prefix,
        (Stream<List<int>> stream) => _parseSourceStream(stream, result));

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

    await _applyToDirectory(directory, source_file_prefix,
        (Stream<List<int>> stream) => _parseSourceStream(stream, result));

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

  Future<void> _parseSourceStream(Stream<List<int>> stream, ScanResult result) {
    final lineStream = stream.transform(utf8.decoder).transform(LineSplitter());

    return BlackDuckCsvParser(result).parse(lineStream);
  }
}

class BlackDuckCsvParser {
  final ScanResult result;
  final assumed = <ItemId>{};

  var _versionIndex = -1;
  var _originIndex = -1;
  var _nameIndex = -1;

  BlackDuckCsvParser(this.result);

  Future<void> parse(Stream<String> lineStream) async {
    var foundHeaders = false;

    await for (final line in lineStream) {
      final columns = line.split(',');

      if (!foundHeaders) {
        _setColumnIndexes(columns);
        foundHeaders = true;
      } else {
        _processRow(columns);
      }
    }
  }

  void _setColumnIndexes(List<String> columns) {
    _versionIndex = columns.indexOf('Component origin version name');
    _originIndex = columns.indexOf('Origin name');
    _nameIndex = columns.indexOf('Origin name id');
  }

  void _processRow(List<String> columns) {
    final type = columns[_originIndex];
    switch (type) {
      case 'maven':
        result.addItem(_itemIdFromColumns(columns, ':'));
        break;
      case 'npmjs':
        result.addItem(_itemIdFromColumns(columns, '/'));
        break;
      default:
        final id = _itemIdFromColumns(columns, '/');
        if (!assumed.contains(id)) {
          stderr.writeln('Warning: Assumed $id for WhiteSource type "$type"');
          assumed.add(id);
        }
        result.addItem(id);
    }
  }

  ItemId _itemIdFromColumns(List<String> columns, String pattern) {
    final package = _stripLastPart(columns[_nameIndex], pattern);
    final version = columns[_versionIndex];
    return ItemId(package, version);
  }

  String _stripLastPart(String name, Pattern pattern) =>
      name.substring(0, name.lastIndexOf(pattern));
}
