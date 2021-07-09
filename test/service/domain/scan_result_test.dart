import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/purl.dart';
import 'package:test/test.dart';

void main() {
  group('$ScanResult', () {
    const name = 'name';
    late ScanResult result;

    setUp(() {
      result = ScanResult(name);
    });

    test('creates named instance', () {
      expect(result.name, equals(name));
    });

    test('indicates non-contained items', () {
      expect(result[BomItem(Purl('pkg:type/non@existing'))], isNull);
    });

    test('holds item identifiers', () {
      final item = BomItem(Purl('pkg:type/name@version'));

      result.addItem(item);

      expect(result[item], equals(item));
    });

    group('merging results', () {
      test('merges independent items', () {
        final item = BomItem(Purl('pkg:type/name@version'));
        final otherItem = BomItem(Purl('pkg:type/other@version'));
        final otherResult = ScanResult('other')..addItem(otherItem);

        result.addItem(item);
        result.merge(otherResult);

        expect(result[item], equals(item));
        expect(result[otherItem], equals(otherItem));
      });

      test('merges licenses of existing items', () {
        final sameItem = BomItem(Purl('pkg:type/same@version'))
          ..addLicenses(['one']);
        final item = BomItem(Purl('pkg:type/same@version'))
          ..addLicenses(['two']);
        final otherResult = ScanResult('other')..addItem(sameItem);

        result.addItem(item);
        result.merge(otherResult);

        expect(result[item]!.licenses, containsAll(['one', 'two']));
      });
    });
  });
}
