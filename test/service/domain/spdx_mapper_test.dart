import 'package:bompare/service/business_exception.dart';
import 'package:bompare/service/domain/spdx_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('$SpdxMapper', () {
    const unknown = 'Not a known license';
    const valid_license = 'MIT';

    SpdxMapper mapper;

    setUp(() {
      mapper = SpdxMapper();
    });

    test('maps null to empty set', () {
      expect(mapper[null], isEmpty);
    });

    test('maps SPDX titles and identifiers case-insensitively', () {
      expect(mapper['MIT License'], equals({'MIT'}));
      expect(mapper[valid_license], equals({valid_license}));
      expect(mapper[valid_license.toUpperCase()], equals({valid_license}));
      expect(mapper[valid_license.toLowerCase()], equals({valid_license}));
    });

    test('maps obsolete SPDX identifiers to their replacement', () {
      expect(mapper['GPL-3.0+'], equals({'GPL-3.0-or-later'}));
    });

    test('quotes unregistered mappings', () {
      expect(mapper[unknown], equals({'"$unknown"'}));
    });

    test('ignores braces around key', () {
      expect(mapper['($valid_license)'], equals({valid_license}));
    });

    test('splits on AND and OR', () {
      expect(mapper['mit AND aladdin and Intel'],
          equals({'MIT', 'Aladdin', 'Intel'}));
      expect(mapper['mit OR aladdin or Intel'],
          equals({'MIT', 'Aladdin', 'Intel'}));
      expect(mapper['Mit or something and else'],
          equals({'MIT', '"something and else"'}));
      expect(mapper['something and else or mit'],
          equals({'"something and else"', 'MIT'}));
      expect(mapper['something or mit and else'],
          equals({'"something"', '"else"', 'MIT'}));
      expect(mapper['mit or something and Aladdin'],
          equals({'"something"', 'Aladdin', 'MIT'}));
    });

    test('handles postfix "or" properly', () {
      expect(
          mapper[
              '(GNU General Public License v3.0 only OR GNU Lesser General Public License v3.0 or later)'],
          equals({'GPL-3.0-only', 'LGPL-3.0-or-later'}));
    });

    test('ignores AND and OR that does not yield result', () {
      const andOr = 'This and that or more unknowns';
      const leftOrRight = 'Left or right';
      mapper[andOr] = valid_license;

      expect(mapper[andOr], equals({valid_license}));
      expect(mapper[leftOrRight], equals({'"$leftOrRight"'}));
    });

    test('manually adds alternative titles', () {
      const custom = 'Not A standard Title';

      mapper[custom] = valid_license;

      expect(mapper[custom.toUpperCase()], equals({valid_license}));
    });

    test('throws for manually adding a duplicate title', () {
      expect(
          () => mapper[valid_license] = valid_license,
          throwsA(predicate<BusinessException>(
              (e) => e.toString().contains(valid_license))));
    });

    test('throws for manually adding an unknown identifier', () {
      expect(
          () => mapper[unknown] = unknown,
          throwsA(predicate<BusinessException>(
              (e) => e.toString().contains(unknown))));
    });
  });
}
