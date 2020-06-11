import 'dart:io';

import 'package:bompare/persistence/parser/license_checker_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$LicenseCheckerResultParser', () {
    final resourcePath = path.join('test', 'resources');
    final resultFile = File(path.join(resourcePath, 'license_checker.csv'));
    final lorumFile = File(path.join(resourcePath, 'testfile.txt'));

    final ResultParser parser = LicenseCheckerResultParser(SpdxMapper());

    test('parses from file', () async {
      final result = await parser.parse(resultFile);

      expect(result.items, contains(ItemId('package', 'v1')));
      expect(result.items, contains(ItemId('@package', 'v2')));
    });

    test('maps SPDX license identifiers', () async {
      final result = await parser.parse(resultFile);

      expect(result[ItemId('package', 'v1')].licenses,
          containsAll({'MIT', '"Unknown"'}));
    });

    test('throws when file does not exist', () {
      expect(
          () => parser.parse(File('unknown_file')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('not found'))));
    });

    test('throws for malformed file', () {
      expect(
          () => parser.parse(lorumFile),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('Unexpected format'))));
    });
  });
}
