import 'dart:convert';
import 'dart:io';

import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:path/path.dart' as path;

import '../persistence_exception.dart';
import '../result_parser.dart';

class BlackDuckResultParser implements ResultParser {
  @override
  Future<ScanResult> parse(File file) async {
    final directory = Directory(file.path);

    if (!file.existsSync() && !directory.existsSync()) {
      throw PersistenceException(
          file, 'BlackDuck ZIP file or directory not found');
    }

    final result = ScanResult(path.basenameWithoutExtension(file.path));

    await Future.forEach(
        directory
            .listSync()
            .whereType<File>()
            .where((f) => path.basename(f.path).startsWith('source_')),
        (f) => _parseSourceFile(f, result));
    return result;
  }

  Future<void> _parseSourceFile(File file, ScanResult result) async {
    final lineStream =
        file.openRead().transform(utf8.decoder).transform(LineSplitter());

    return BlackDuckCsvParser(result).parse(lineStream);
  }
}

class BlackDuckCsvParser {
  final ScanResult result;

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
        stderr.writeln('Warning: Assumed $id for WhiteSource type "$type"');
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
