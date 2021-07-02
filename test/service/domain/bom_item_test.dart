import 'package:bompare/service/domain/bom_item.dart';
import 'package:test/test.dart';

void main() {
  group('$BomItem', () {
    const package = 'package';
    const version = 'version';
    const license = 'license';

    test('creates instance', () {
      final id = BomItem(package, version);

      expect(id.package, equals(package));
      expect(id.version, equals(version));
      expect(id.licenses, isEmpty);
    });

    test('creates instance with null version', () {
      final id = BomItem(package, null);

      expect(id.version, isEmpty);
    });

    test('adds licenses', () {
      final id = BomItem(package, version)..addLicenses([license]);

      expect(id.licenses, contains(license));
    });

    test('skips empty license', () {
      final id = BomItem(package, version)..addLicenses(['']);

      expect(id.licenses, isEmpty);
    });

    test('implements equality', () {
      final id = BomItem(package, version);
      final other1 = BomItem('other', version);
      final other2 = BomItem(package, 'other');
      final equal = BomItem(package, version)..addLicenses(['ignored']);

      expect(id, equals(id));
      expect(id, equals(equal));
      expect(id, isNot(equals(other1)));
      expect(id, isNot(equals(other2)));
    });

    group('implements comparable', () {
      test('0 if equal', () {
        final id = BomItem(package, version);

        expect(id.compareTo(id), equals(0));
      });

      test('-1 if before', () {
        expect(
            BomItem('aaa', 'zzz').compareTo(BomItem('bbb', 'xxx')), equals(-1));
        expect(BomItem(package, 'aaa').compareTo(BomItem(package, 'zzz')),
            equals(-1));
      });

      test('+1 if after', () {
        expect(
            BomItem('bbb', 'xxx').compareTo(BomItem('aaa', 'zzz')), equals(1));
        expect(BomItem(package, 'bbb').compareTo(BomItem(package, 'aaa')),
            equals(1));
      });
    });

    test('describes as package and version', () {
      final itemId = BomItem(package, version);

      expect(itemId.toString(), equals('$package-$version'));
    });
  });
}
