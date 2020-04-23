import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/persistence/scan_result_loader.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/result_persistence.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class ResultParserMock extends Mock implements ResultParser {}

void main() {
  group('$ScanResultLoader', () {
    final testDirectory = path.join('test', 'resources');
    final mappingFile = File(path.join(testDirectory, 'mapping.csv'));
    final file = File('some_file.json');

    Map<String, String> spdxMapping;
    ResultPersistence persistence;
    ResultParser parser;

    setUp(() {
      parser = ResultParserMock();
      spdxMapping = <String, String>{};
      persistence =
          ScanResultLoader({ScannerType.white_source: parser}, spdxMapping);
    });

    group('SPDX mapping', () {
      test('primes SPDX mapping with 1:1 identifiers', () {
        expect(spdxMapping, isNotEmpty);
        final key = spdxMapping.keys.first;
        expect(key, equals(spdxMapping[key]));
      });

      test('adds SPDX mapping', () async {
        await persistence.loadMapping(mappingFile);

        expect(spdxMapping.length, greaterThan(5));
        expect(spdxMapping, containsPair('key', 'value'));
      });
    });

    group('scan result loading', () {
      test('throws for loading from unregistered scanner', () {
        expect(
            () => persistence.load(ScannerType.reference, file),
            throwsA(predicate<PersistenceException>(
                (e) => e.toString().contains('parser'))));
      });

      test('loads scan result', () {
        persistence.load(ScannerType.white_source, file);

        verify(parser.parse(file));
      });
    });
  });
}
