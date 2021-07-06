import 'dart:io';

import 'package:bompare/persistence/parser/blackduck_result_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/result_parser.dart';
import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:bompare/service/purl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$BlackDuckResultParser', () {
    final resources = path.join('test', 'resources');
    final directory = File(path.join(resources, 'blackduck'));
    final zipFile = File(path.join(resources, 'blackduck.zip'));
    final ResultParser parser = BlackDuckResultParser(SpdxMapper());

    test('throws for missing file', () {
      expect(
          () => parser.parse(File('not_a_file')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('not found'))));
    });

    test('skips separators inside quoted texts', () async {
      final result = await parser.parse(directory);

      final item = result[BomItem(Purl('pkg:npm/comma@v0'))]!;
      expect(item.licenses, equals({'Apache-2.0'}));
    });

    test('parses licenses from directory with SPDX abbreviation', () async {
      final result = await parser.parse(directory);

      final item = result[BomItem(Purl('pkg:npm/license@v1'))]!;
      expect(item.licenses, equals({'MIT'}));
    });

    test('parses packages with license from ZIP file', () async {
      final result = await parser.parse(zipFile);

      final item = result[BomItem(Purl('pkg:npm/license@v1'))]!;
      expect(item, isNotNull);
      expect(item.licenses, equals({'MIT'}));
    });

    test('parses different types of matches', () async {
      final result = await parser.parse(directory);

      expect(result.items,
          contains(BomItem(Purl('pkg:not a known type/default@v%3F'))));
      expect(result.items,
          contains(BomItem(Purl('pkg:nuget/component@component_version'))));
      expect(
          result.items, contains(BomItem(Purl('pkg:maven/package/java@v2'))));
      expect(
          result.items, contains(BomItem(Purl('pkg:github/github/repo@v3'))));
      expect(result.items, contains(BomItem(Purl('pkg:npm/package/js@v4'))));
      expect(
          result.items, contains(BomItem(Purl('pkg:nuget/package/.Net@v9'))));
      expect(result.items, contains(BomItem(Purl('pkg:alpine/alpine@v5'))));
      expect(result.items, contains(BomItem(Purl('pkg:rpm/centos@v6'))));
      expect(result.items, contains(BomItem(Purl('pkg:deb/debian@v7'))));
      expect(result.items, contains(BomItem(Purl('pkg:generic/long_tail@v8'))));
    });
  });
}
