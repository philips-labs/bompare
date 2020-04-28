import 'dart:io';

import 'package:bompare/persistence/parser/mapping_parser.dart';
import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$MappingParser', () {
    final directory = path.join('test', 'resources');
    final file = File(path.join(directory, 'mapping.csv'));

    SpdxMapper mapper;
    MappingParser parser;

    setUp(() {
      mapper = SpdxMapper();
      parser = MappingParser(mapper);
    });

    test('throws for missing file', () {
      expect(
          parser.parse(File('not_a_file')),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('not found'))));
    });

    test('reads mapping', () async {
      const aladdin = 'Aladdin';

      await parser.parse(file);

      expect(mapper['key'], equals({'Beerware'}));
      expect(mapper['1001 NIGHTS'], equals({aladdin}));
    });
  });
}
