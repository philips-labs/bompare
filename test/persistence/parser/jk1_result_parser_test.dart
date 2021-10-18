import 'dart:io';

import 'package:bompare/persistence/parser/jk1_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:bompare/service/purl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$Jk1ResultParser', () {
    final resourcePath = path.join('test', 'resources');
    final jk1File = File(path.join(resourcePath, 'jk1.json'));
    final lorumFile = File(path.join(resourcePath, 'testfile.txt'));
    final item1 = BomItem(Purl('pkg:maven/group/artifact_1@v_1'));
    final item2 = BomItem(Purl('pkg:maven/group/artifact_2@v_2'));

    final parser = Jk1ResultParser(SpdxMapper());

    test('parses from file', () async {
      final result = await parser.parse(jk1File);

      expect(result.items, containsAll([item1, item2]));
    });

    test('converts licenses using mapper', () async {
      final result = await parser.parse(jk1File);

      expect(result[item1]!.licenses, equals({'"my_license"'}));
      expect(result[item2]!.licenses, equals({'MIT'}));
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
