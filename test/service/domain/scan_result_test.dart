import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:test/test.dart';

void main() {
  group('$ScanResult', () {
    const name = 'name';
    const package = 'package';
    const version = 'version';
    late ScanResult result;

    setUp(() {
      result = ScanResult(name);
    });

    test('creates named instance', () {
      expect(result.name, equals(name));
    });

    test('indicates non-contained items', () {
      expect(result[BomItem('non', 'existing')], isNull);
    });

    test('holds item identifiers', () {
      final id = BomItem(package, version);

      result.addItem(id);

      expect(result[id], equals(id));
    });

    group('merging results', () {
      test('merges independent items', () {
        final otherId = BomItem('other_package', 'v2.0');
        final itemId = BomItem(package, version);
        final other = ScanResult('other')..addItem(otherId);

        result.addItem(itemId);
        result.merge(other);

        expect(result[itemId], equals(itemId));
        expect(result[otherId], equals(otherId));
      });

      test('merges licenses of existing items', () {
        final sameId = BomItem(package, version)..addLicenses(['one']);
        final itemId = BomItem(package, version)..addLicenses(['two']);
        final other = ScanResult('other')..addItem(sameId);

        result.addItem(itemId);
        result.merge(other);

        expect(result[itemId]!.licenses, containsAll(['one', 'two']));
      });
    });
  });
}
