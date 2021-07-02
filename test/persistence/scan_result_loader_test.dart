import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/persistence/scan_result_loader.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/business_exception.dart';
import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:bompare/service/result_persistence.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class ResultParserMock extends Mock implements ResultParser {}

void main() {
  group('$ScanResultLoader', () {
    final testDirectory = path.join('test', 'resources');
    final mappingFile = File(path.join(testDirectory, 'mapping.csv'));
    final wssGlob = Glob(path.join(testDirectory, 'wss_inventory.json'));

    late SpdxMapper spdxMapping;
    late ResultPersistence persistence;
    late ResultParser parser;

    setUp(() {
      parser = ResultParserMock();
      spdxMapping = SpdxMapper();
      persistence =
          ScanResultLoader({ScannerType.white_source: parser}, spdxMapping);

      registerFallbackValue(File(''));
    });

    group('SPDX mapping', () {
      test('adds SPDX mapping', () async {
        await persistence.loadMapping(mappingFile);

        expect(spdxMapping['key'], contains('Beerware'));
      });

      test('throws for invalid SPDX tags', () {
        final loremFile = File(path.join(testDirectory, 'testfile.txt'));

        expect(
            persistence.loadMapping(loremFile),
            throwsA(predicate<BusinessException>(
                (e) => e.toString().contains('SPDX'))));
      });
    });

    group('scan result loading', () {
      test('throws for loading from unregistered scanner', () {
        expect(
            () => persistence.load(ScannerType.reference, wssGlob),
            throwsA(predicate<PersistenceException>(
                (e) => e.toString().contains('parser'))));
      });

      test('loads scan result(s)', () async {
        final file = wssGlob.listSync().first;
        final itemId = BomItem('package', 'version');
        when(() => parser
                .parse(any(that: predicate<File>((f) => f.path == file.path))))
            .thenAnswer(
                (_) => Future.value(ScanResult('Loaded')..addItem(itemId)));

        final result =
            await persistence.load(ScannerType.white_source, wssGlob);

        expect(result.name, equals('wss_inventory'));
        expect(result[itemId], isNotNull);
      });

      test('throws when no files match the provided glob', () {
        expect(
            () => persistence.load(ScannerType.white_source, Glob('unknown')),
            throwsA(predicate<PersistenceException>(
                (e) => e.toString().contains('not match'))));
      });
    });
  });
}
