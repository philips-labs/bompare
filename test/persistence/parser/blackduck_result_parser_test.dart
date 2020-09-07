import 'dart:io';

import 'package:bompare/persistence/parser/blackduck_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$BlackDuckResultParser', () {
    final resources = path.join('test', 'resources');
    final directory = File(path.join(resources, 'blackduck'));
    final zipFile = File(path.join(resources, 'blackduck.zip'));
    final ResultParser parser = BlackDuckResultParser(SpdxMapper());

    test('throws for missing file', () {
      expect(
          () => parser.parse(File('not_a_file')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('not found'))));
    });

    test('skips separators inside quoted texts', () async {
      final result = await parser.parse(directory);

      final itemId = result[ItemId('comma', 'v0')];
      expect(itemId.licenses, equals({'Apache-2.0'}));
    });

    test('parses licenses from directory with SPDX abbreviation', () async {
      final result = await parser.parse(directory);

      final itemId = result[ItemId('license', 'v1')];
      expect(itemId.licenses, equals({'MIT'}));
    });

    test('parses packages with license from ZIP file', () async {
      final result = await parser.parse(zipFile);

      final itemId = result[ItemId('license', 'v1')];
      expect(itemId, isNotNull);
      expect(itemId.licenses, equals({'MIT'}));
    });

    test('parses different types of matches', () async {
      final result = await parser.parse(directory);

      expect(result.items, contains(ItemId('default', 'v?')));
      expect(result.items, contains(ItemId('component', 'component_version')));
      expect(result.items, contains(ItemId('package/java', 'v2')));
      expect(result.items, contains(ItemId('github/repo', 'v3')));
      expect(result.items, contains(ItemId('package/js', 'v4')));
      expect(result.items, contains(ItemId('package/.Net', 'v9')));
      expect(result.items, contains(ItemId('alpine', 'v5')));
      expect(result.items, contains(ItemId('centos', 'v6')));
      expect(result.items, contains(ItemId('debian', 'v7')));
      expect(result.items, contains(ItemId('long_tail', 'v8')));
    });
  });
}
