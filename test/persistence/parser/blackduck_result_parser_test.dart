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

    test('parses JavaScript packages from directory', () async {
      final result = await parser.parse(directory);

      expect(result.items, contains(ItemId('package/js', 'v1')));
    });

    test('parses Java packages from directory', () async {
      final result = await parser.parse(directory);

      expect(result.items, contains(ItemId('package:java', 'v2')));
    });

    test('parses licenses from directory with SPDX abbreviation', () async {
      final result = await parser.parse(directory);

      final itemId = result.items.lookup(ItemId('license', 'v1'));
      expect(itemId.licenses, equals({'MIT'}));
    });

    test('parses packages from ZIP file', () async {
      final result = await parser.parse(zipFile);

      expect(result.items, contains(ItemId('package/js', 'v1')));
    });

    test('parses licenses from ZIP file', () async {
      final result = await parser.parse(zipFile);

      final itemId = result.items.lookup(ItemId('license', 'v1'));
      expect(itemId.licenses, equals({'MIT'}));
    });
  });
}
