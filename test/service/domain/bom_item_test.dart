import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/purl.dart';
import 'package:test/test.dart';

void main() {
  group('$BomItem', () {
    final purl = Purl('pkg:generic/name@version');
    const license = 'license';

    test('creates instance', () {
      final item = BomItem(purl);

      expect(item.purl, equals(purl));
      expect(item.licenses, isEmpty);
    });

    test('adds licenses', () {
      final item = BomItem(purl)..addLicenses([license]);

      expect(item.licenses, contains(license));
    });

    test('skips empty license', () {
      final item = BomItem(purl)..addLicenses(['']);

      expect(item.licenses, isEmpty);
    });

    test('implements equality', () {
      final item = BomItem(purl);
      final other = BomItem(Purl('pkg:generic/other@version'));
      final equal = BomItem(purl)..addLicenses(['ignored']);

      expect(item, equals(item));
      expect(item, equals(equal));
      expect(item, isNot(equals(other)));
    });

    test('implements comparable', () {
      final earlier = Purl('pkg:t/A@A');
      final later = Purl('pkg:t/Z@Z');

      expect(BomItem(purl).compareTo(BomItem(purl)), 0);
      expect(BomItem(earlier).compareTo(BomItem(later)), -1);
      expect(BomItem(later).compareTo(BomItem(earlier)), 1);
    });

    test('describes as package and version', () {
      final itemId = BomItem(purl);

      expect(itemId.toString(), equals(purl.toString()));
    });
  });
}
