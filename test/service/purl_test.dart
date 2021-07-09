/*
 * Copyright (c) 2020-2021, Koninklijke Philips N.V., https://www.philips.com
 * SPDX-License-Identifier: MIT
 */

import 'package:bompare/service/purl.dart';
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

    test('creates from parts', () {
      final purl = Purl.of(
          type: 'type', namespace: 'ns', name: 'name', version: 'version');

      expect(purl, Purl('pkg:type/ns/name@version'));
    });

    test('creates without namespace', () {
      final purl = Purl.of(type: 'type', name: 'name', version: 'version');

      expect(purl, Purl('pkg:type/name@version'));
    });

    test('creates with namespace in name', () {
      final purl = Purl.of(type: 'type', name: 'ns/name', version: 'version');

      expect(purl, Purl('pkg:type/ns/name@version'));
    });

    test('creates with default type', () {
      final purl = Purl.of(name: 'name', version: 'version');

      expect(purl, Purl('pkg:generic/name@version'));
    });

    test('assumes explicit default type', () {
      final generic = Purl.defaultType;
      addTearDown(() {
        Purl.defaultType = generic;
      });
      Purl.defaultType = 'custom';

      final purl = Purl.of(name: 'name', version: 'version');

      expect(purl, Purl('pkg:custom/name@version'));
    });

    test('encodes purl parts', () {
      final purl =
          Purl.of(type: 'type', namespace: '@', name: '%', version: '/');

      expect(purl, Purl('pkg:type/%40/%25@%2F'));
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

    test('implements equality', () {
      expect(Purl('pkg:t/s/n@v'), Purl('pkg:t/s/n@v'));
      expect(Purl('pkg:t/s/n@v'), isNot(Purl('pkg:x/s/n@v')));
      expect(Purl('pkg:t/s/n@v'), isNot(Purl('pkg:t/x/n@v')));
      expect(Purl('pkg:t/s/n@v'), isNot(Purl('pkg:t/s/x@v')));
      expect(Purl('pkg:t/s/n@v'), isNot(Purl('pkg:t/s/n@x')));
    });

    test('implements comparable', () {
      expect(Purl('pkg:t/n@v').compareTo(Purl('pkg:t/n@v')), 0);

      expect(Purl('pkg:z/A@z').compareTo(Purl('pkg:a/Z@a')), -1);
      expect(Purl('pkg:z/n@A').compareTo(Purl('pkg:a/n@Z')), -1);
      expect(Purl('pkg:A/n@v').compareTo(Purl('pkg:Z/n@v')), -1);

      expect(Purl('pkg:a/Z@a').compareTo(Purl('pkg:z/A@z')), 1);
      expect(Purl('pkg:a/n@Z').compareTo(Purl('pkg:z/n@A')), 1);
      expect(Purl('pkg:Z/n@v').compareTo(Purl('pkg:A/n@v')), 1);
    });
  });
}
