import 'package:bompare/persistence/parser/purl.dart';
import 'package:test/test.dart';

void main() {
  group('$Purl', () {
    test('throws when not starting with "pkg:', () {
      expect(
          () => Purl('other:abc/def@123'),
          throwsA(
              predicate<FormatException>((e) => e.toString().contains('pkg'))));
    });

    test('creates from full spec instance', () {
      final purl =
          Purl('pkg:type/namespace/name@version?qualifiers#relative/path');

      expect(purl.type, equals('type'));
      expect(purl.name, equals('namespace/name'));
      expect(purl.version, equals('version'));
    });

    test('creates from simple instance', () {
      final purl = Purl('pkg:type/name@version#relative/path');

      expect(purl.type, equals('type'));
      expect(purl.name, equals('name'));
      expect(purl.version, equals('version'));
    });

    test('throws for missing type part', () {
      expect(
          () => Purl('pkg:').type,
          throwsA(predicate<FormatException>(
              (e) => e.toString().contains('type part'))));
    });

    test('throws for missing name part', () {
      expect(
          () => Purl('pkg:type').name,
          throwsA(predicate<FormatException>(
              (e) => e.toString().contains('name part'))));
    });

    test('creates from minimal instance', () {
      final purl = Purl('pkg:type/name@version');

      expect(purl.type, equals('type'));
      expect(purl.name, equals('name'));
      expect(purl.version, equals('version'));
    });

    test('creates without version', () {
      final purl = Purl('pkg:type/name?qualifiers#relative/path');

      expect(purl.type, equals('type'));
      expect(purl.name, equals('name'));
      expect(purl.version, isEmpty);
    });

    test('decodes URL encoded values', () {
      final expected = ' %?@#/';
      final encoded = Uri.encodeComponent(expected);

      final purl = Purl('pkg:$encoded/$encoded/$encoded@$encoded');

      expect(purl.type, equals(expected));
      expect(purl.name, equals('$expected/$expected'));
      expect(purl.version, equals(expected));
    });
  });
}
