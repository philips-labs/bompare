import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/reference/reference_result_parser.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:test/test.dart';

void main() {
  group('$ReferenceResultParser', () {
    const files = 'test/resources';

    final parser = ReferenceResultParser();

    test('parses from file', () async {
      final result = await parser.parse(File('$files/reference.json'));

      expect(
          result.items,
          containsAll([
            ItemId('component_1', 'v_1'),
            ItemId('component_2', 'v_2'),
          ]));
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
