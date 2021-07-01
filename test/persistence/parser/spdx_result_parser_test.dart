import 'dart:io';

import 'package:bompare/persistence/parser/spdx_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$SpdxResultParser', () {
    final resources = path.join('test', 'resources');
    final directory = path.join(resources, 'spdx');
    final file = File(path.join(directory, 'spdx_tag_value.spdx'));
    final lorumFile = File(path.join(resources, 'testfile.txt'));
    final missingRefFile =
        File(path.join(directory, 'missing_external_ref.spdx'));
    final parser = SpdxResultParser(SpdxMapper());

    test('throws for missing file', () {
      expect(
          () => parser.parse(File('not_a_file')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('not found'))));
    });

    test('throws for malformed file', () {
      expect(
          () => parser.parse(lorumFile),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('valid SPDX'))));
    });

    test('parses plain package', () async {
      final result = await parser.parse(file);

      expect(result[ItemId('group/artifact', '1.0')]!.licenses,
          containsAll(['MIT', '"Unknown"']));
    });

    group('license declaration', () {
      test('prefers concluded license', () async {
        final result = await parser.parse(file);

        expect(result[ItemId('group/artifact', '1.0')]!.licenses,
            containsAll(['MIT', '"Unknown"']));
      });

      test('parses package without asserted license', () async {
        final result = await parser.parse(file);

        expect(result[ItemId('unasserted_license', '2.0')]!.licenses, isEmpty);
      });

      test('assumes declared license', () async {
        final result = await parser.parse(file);

        expect(result[ItemId('declared_license', '3.0')]!.licenses,
            contains('Apache-2.0'));
      });

      test('recursively expands custom license', () async {
        final result = await parser.parse(file);

        expect(result[ItemId('custom_license', '4.0')]!.licenses,
            contains('"Custom WITH Exception"'));
      });
    });

    test('parses text blocks', () async {
      final result = await parser.parse(file);

      expect(result[ItemId('text', '3.0')], isNotNull);
    });

    test('skips when missing package url', () async {
      final result = await parser.parse(missingRefFile);

      expect(result.items.length, 0);
    });
  });
}
