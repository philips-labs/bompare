import 'dart:io';

import 'package:bompare/persistence/parser/wss_inventory_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:test/test.dart';

void main() {
  group('$WhiteSourceInventoryResultParser', () {
    const files = 'test/resources';

    final ResultParser parser = WhiteSourceInventoryResultParser();

    test('parses JavaScript items from file', () async {
      final result = await parser.parse(File('$files/wss_inventory.json'));

      expect(result.items, contains(ItemId('js_package', '1.0')));
    });

    test('parses Java items from file', () async {
      final result = await parser.parse(File('$files/wss_inventory.json'));

      expect(result.items, contains(ItemId('java_package', '2.0')));
    });

    test('throws when file does not exist', () {
      expect(
          () => parser.parse(File('$files/Unknown_file')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('not found'))));
    });

    test('throws for malformed file', () {
      expect(
          () => parser.parse(File('$files/testfile.txt')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('Unexpected format'))));
    });
  });
}
