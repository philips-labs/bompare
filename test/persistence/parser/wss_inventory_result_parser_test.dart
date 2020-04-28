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

    test('parses JavaScript items from file', () async {
      final result = await parser.parse(inventoryFile);

      expect(result.items, contains(ItemId('js_package', '1.0')));
    });

    test('parses Java items from file', () async {
      final result = await parser.parse(inventoryFile);

      expect(result.items, contains(ItemId('group:java_package', '2.0')));
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

      final id = result.items.lookup(ItemId('licenses', 'v'));
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
