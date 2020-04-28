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

    test('maps SPDX titles and identifiers case-insensitively', () {
      expect(mapper['MIT License'], equals('MIT'));
      expect(mapper[valid_license], equals(valid_license));
      expect(mapper[valid_license.toUpperCase()], equals(valid_license));
      expect(mapper[valid_license.toLowerCase()], equals(valid_license));
    });

    test('quotes unregistered mappings', () {
      expect(mapper[unknown], '"$unknown"');
    });

    test('manually adds alternative titles', () {
      const custom = 'Not A standard Title';

      mapper[custom] = valid_license;

      expect(mapper[custom.toUpperCase()], equals(valid_license));
    });

    test('throws for manually adding an unknown identifier', () {
      expect(
          () => mapper[unknown] = unknown,
          throwsA(predicate<BusinessException>(
              (e) => e.toString().contains(unknown))));
    });
  });
}
