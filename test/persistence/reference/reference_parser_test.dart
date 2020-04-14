import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/reference/reference_parser.dart';
import 'package:test/test.dart';

void main() {
  group('$ReferenceParser', () {
    const files = 'test/resources';

    final parser = ReferenceParser();

    test('parses from file', () {
      final inventory = parser.parse(File('$files/reference.json'));

      expect(inventory[0].name, equals('component_1'));
      expect(inventory[0].version, equals('v_1'));

      expect(inventory[1].name, equals('component_2'));
      expect(inventory[1].version, equals('v_2'));
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
