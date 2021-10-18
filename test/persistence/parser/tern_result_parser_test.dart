import 'dart:io';

import 'package:bompare/persistence/parser/tern_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:bompare/service/purl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$TernResultParser', () {
    final resourcePath = path.join('test', 'resources');
    final ternFile = File(path.join(resourcePath, 'tern.json'));
    final lorumFile = File(path.join(resourcePath, 'testfile.txt'));
    final itemId1 =
        BomItem(Purl.of(name: 'image1_layer1_package1', version: 'v_1'));
    final itemId2 =
        BomItem(Purl.of(name: 'image1_layer1_package2', version: 'v_2'));
    final itemId3 =
        BomItem(Purl.of(name: 'image1_layer2_package', version: 'v_3'));
    final itemId4 = BomItem(Purl.of(name: 'image2_layer_package', version: ''));

    final parser = TernResultParser(SpdxMapper());

    test('parses packages from images and layers in file', () async {
      final result = await parser.parse(ternFile);

      expect(result.items, containsAll([itemId1, itemId2, itemId3, itemId4]));
    });

    test('converts licenses using mapper', () async {
      final result = await parser.parse(ternFile);

      expect(result[itemId1]!.licenses, equals({'"my_license"', 'MIT'}));
      expect(result[itemId2]!.licenses, equals({'GPL-2.0-only'}));
      expect(result[itemId3]!.licenses, equals({'GPL-2.0-or-later'}));
      expect(result[itemId4]!.licenses, isEmpty);
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
