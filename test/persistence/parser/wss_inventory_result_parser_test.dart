import 'dart:io';

import 'package:bompare/persistence/parser/wss_inventory_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$WhiteSourceInventoryResultParser', () {
    final resourcePath = path.join('test', 'resources');
    final inventoryFile = File(path.join(resourcePath, 'wss_inventory.json'));
    final lorumFile = File(path.join(resourcePath, 'testfile.txt'));

    final mapper = SpdxMapper();
    final ResultParser parser = WhiteSourceInventoryResultParser(mapper);

    setUpAll(() {
      mapper['Apache 2.0'] = 'Apache-2.0';
      mapper['key'] = 'MIT';
    });

    test('parses different types of items from file', () async {
      final result = await parser.parse(inventoryFile);

      expect(result.items, contains(ItemId('javascript/Node.js', '1.0')));
      expect(result.items, contains(ItemId('JavaScript', '2.0')));
      expect(result.items, contains(ItemId('Java1/jar', '12')));
      expect(result.items, contains(ItemId('Java2', '13')));
      expect(result.items, contains(ItemId('Alpine', '3.1.2-r0')));
      expect(result.items, contains(ItemId('Debian1', '1.5.71')));
      expect(result.items, contains(ItemId('Debian2', '2.2.3')));
      expect(result.items, contains(ItemId('ActionScript1', '1.2')));
      expect(result.items, contains(ItemId('ActionScript2', '3.1')));
      expect(result.items, contains(ItemId('Source Library1', '7.0')));
      expect(result.items, contains(ItemId('Source Library2', '8.0')));
      expect(
          result.items, contains(ItemId('Unknown Library1', 'Needs review')));
      expect(
          result.items, contains(ItemId('Unknown Library2', 'Needs review')));
      expect(result.items, contains(ItemId('RPM', '1.12.8')));
      expect(result.items, contains(ItemId('(not defined)', '1.2.3')));
    });

    test('handles missing version field', () async {
      final result = await parser.parse(inventoryFile);

      expect(result.items, contains(ItemId('no_version', '')));
    });

    test('handles empty version field', () async {
      final result = await parser.parse(inventoryFile);

      expect(result.items, contains(ItemId('empty_version', '')));
    });

    test('reads licenses using license mapping', () async {
      final result = await parser.parse(inventoryFile);

      final id = result[ItemId('licenses', 'v')];
      expect(id.licenses, equals({'MIT', '"my_license"'}));
    });

    test('throws when file does not exist', () {
      expect(
          () => parser.parse(File('Unknown_file')),
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
