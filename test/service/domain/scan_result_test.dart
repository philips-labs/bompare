import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:test/test.dart';

void main() {
  group('$ScanResult', () {
    const name = 'name';
    const package = 'package';
    const version = 'version';
    ScanResult result;

    setUp(() {
      result = ScanResult(name);
    });

    test('creates named instance', () {
      expect(result.name, equals(name));
    });

    test('indicates non-contained items', () {
      expect(result[ItemId('non', 'existing')], isNull);
    });

    test('holds item identifiers', () {
      final id = ItemId(package, version);

      result.addItem(id);

      expect(result[id], equals(id));
    });

    group('merging results', () {
      test('merges independent items', () {
        final otherId = ItemId('other_package', 'v2.0');
        final itemId = ItemId(package, version);
        final other = ScanResult('other')..addItem(otherId);

        result.addItem(itemId);
        result.merge(other);

        expect(result[itemId], equals(itemId));
        expect(result[otherId], equals(otherId));
      });

      test('merges licenses of existing items', () {
        final sameId = ItemId(package, version)..addLicenses(['one']);
        final itemId = ItemId(package, version)..addLicenses(['two']);
        final other = ScanResult('other')..addItem(sameId);

        result.addItem(itemId);
        result.merge(other);

        expect(result[itemId].licenses, containsAll(['one', 'two']));
      });
    });
  });
}
