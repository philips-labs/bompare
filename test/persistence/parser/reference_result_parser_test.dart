import 'dart:io';

import 'package:bompare/persistence/parser/reference_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/purl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$ReferenceResultParser', () {
    final resourcePath = path.join('test', 'resources');
    final referenceFile = File(path.join(resourcePath, 'reference.json'));
    final lorumFile = File(path.join(resourcePath, 'testfile.txt'));

    final ResultParser parser = ReferenceResultParser();

    test('parses from file', () async {
      final result = await parser.parse(referenceFile);

      expect(
          result.items,
          containsAll([
            BomItem(Purl.of(name: 'component_1', version: 'v_1')),
            BomItem(Purl.of(name: 'component_2', version: 'v_2')),
          ]));
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
