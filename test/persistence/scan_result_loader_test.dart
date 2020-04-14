import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/persistence/scan_result_loader.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/result_persistence.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class ResultParserMock extends Mock implements ResultParser {}

void main() {
  group('$ScanResultLoader', () {
    final file = File('some_file.json');

    ResultPersistence persistence;
    ResultParser parser;

    setUp(() {
      parser = ResultParserMock();
      persistence = ScanResultLoader({ScannerType.white_source: parser});
    });

    test('throws for loading from unregistered scanner', () {
      expect(
          () => persistence.load(ScannerType.reference, file),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('parser'))));
    });

    test('parses scan result', () {
      persistence.load(ScannerType.white_source, file);

      verify(parser.parse(file));
    });
  });
}
