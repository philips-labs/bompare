import 'dart:io';

import 'package:bompare/persistence/parser/maven_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:bompare/service/purl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$MavenResultParser', () {
    final resourcePath = path.join('test', 'resources');
    final licenseFile = File(path.join(resourcePath, 'maven_license.txt'));
    final item = BomItem(Purl('pkg:maven/group/artifact@version'));

    final ResultParser parser = MavenResultParser(SpdxMapper());

    test('parses from file', () async {
      final result = await parser.parse(licenseFile);

      expect(result.items, contains(item));
    });

    test('converts licenses using mapper', () async {
      final result = await parser.parse(licenseFile);

      final licenses = result[item]!.licenses;
      expect(licenses, equals({'"my_license"', 'MIT'}));
    });

    test('throws when file does not exist', () {
      expect(
          () => parser.parse(File('unknown_file')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('not found'))));
    });
  });
}
