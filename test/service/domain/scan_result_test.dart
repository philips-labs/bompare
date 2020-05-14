import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:test/test.dart';

void main() {
  group('$ScanResult', () {
    const name = 'name';
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
      final id = ItemId('package', 'version');

      result.addItem(id);

      expect(result[id], equals(id));
    });
  });
}
