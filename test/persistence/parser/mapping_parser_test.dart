import 'dart:io';

import 'package:bompare/persistence/parser/mapping_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$MappingParser', () {
    final directory = path.join('test', 'resources');
    final file = File(path.join(directory, 'mapping.csv'));
    final parser = MappingParser();

    test('throws for missing file', () {
      expect(
          parser.parse(File('not_a_file')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('not found'))));
    });

    test('throws for malformed file', () {
      final jsonFile = File(path.join(directory, 'reference.json'));

      expect(
          parser.parse(jsonFile),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('two columns'))));
    });

    test('reads mapping', () async {
      final mapping = await parser.parse(file);

      expect(mapping, containsPair('key', 'value'));
    });
  });
}
