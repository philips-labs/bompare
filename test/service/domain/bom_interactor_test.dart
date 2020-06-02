import 'dart:io';

import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/domain/bom_interactor.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/report_persistence.dart';
import 'package:bompare/service/result_persistence.dart';
import 'package:glob/glob.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class ResultPersistenceMock extends Mock implements ResultPersistence {}

class ReportPersistenceMock extends Mock implements ReportPersistence {}

void main() {
  group('$BomInteractor', () {
    const name = 'scan_result';
    final glob = Glob('scan_result.json');
    final spdxFile = File('spdx.csv');

    ResultPersistence results;
    ReportPersistence reports;
    BomService service;

    setUp(() {
      results = ResultPersistenceMock();
      reports = ReportPersistenceMock();
      service = BomInteractor(results, reports);
      service.verbose = true;
    });

    group('SPDX mapping', () {
      test('loads SPDX mapping file', () {
        service.loadSpdxMapping(spdxFile);

        verify(results.loadMapping(spdxFile));
      });
    });

    group('compare bill-of-materials', () {
      test('loads empty scan result', () async {
        expect(await service.compareBom(), isEmpty);
      });

      test('loads scan result from single scanner', () async {
        final result = ScanResult(name)..addItem(ItemId('a', '1'));
        when(results.load(ScannerType.black_duck, glob))
            .thenAnswer((_) => Future.value(result));

        await service.loadResult(ScannerType.black_duck, glob);
        final summary = await service.compareBom();

        expect(summary, hasLength(1));
        expect(summary[0].name, equals(name));
        expect(summary[0].common, equals(1));
        expect(summary[0].missing, isZero);
        expect(summary[0].additional, isZero);
      });

      test('loads scan results from multiple scanners', () async {
        final commonItem = ItemId('common', '0');
        final result1 = ScanResult('A')
          ..addItem(commonItem)
          ..addItem(ItemId('a', '1'));
        when(results.load(ScannerType.reference, glob))
            .thenAnswer((_) => Future.value(result1));
        final result2 = ScanResult('B')
          ..addItem(commonItem)
          ..addItem(ItemId('b', '2'))
          ..addItem(ItemId('c', '3'));
        when(results.load(ScannerType.black_duck, glob))
            .thenAnswer((_) => Future.value(result2));

        await service.loadResult(ScannerType.reference, glob);
        await service.loadResult(ScannerType.black_duck, glob);
        final summary = await service.compareBom();

        expect(summary, hasLength(2));
        expect(summary[0].detected, equals(2));
        expect(summary[0].common, equals(1));
        expect(summary[0].additional, equals(1));
        expect(summary[0].missing, equals(2));
        expect(summary[1].detected, equals(3));
        expect(summary[1].common, equals(1));
        expect(summary[1].additional, equals(2));
        expect(summary[1].missing, equals(1));
      });

      test('writes BOM report', () async {
        final bomFile = File('bom.csv');
        final id = ItemId('a', '1');
        final result = ScanResult('A')..addItem(id);
        when(results.load(ScannerType.reference, glob))
            .thenAnswer((_) => Future.value(result));

        await service.loadResult(ScannerType.reference, glob);
        await service.compareBom(bomFile: bomFile);

        verify(reports.writeBomComparison(bomFile, [id], [result]));
      });

      test('writes diff BOM report', () async {
        final bomFile = File('bom.csv');
        final id1 = ItemId('a', '1');
        final id2 = ItemId('b', '2');
        final result1 = ScanResult('A')..addItem(id1);
        final result2 = ScanResult('B')..addItem(id1)..addItem(id2);
        when(results.load(ScannerType.reference, glob))
            .thenAnswer((_) => Future.value(result1));
        when(results.load(ScannerType.black_duck, glob))
            .thenAnswer((_) => Future.value(result2));

        await service.loadResult(ScannerType.reference, glob);
        await service.loadResult(ScannerType.black_duck, glob);
        await service.compareBom(bomFile: bomFile, diffOnly: true);

        verify(reports.writeBomComparison(bomFile, [id2], [result1, result2]));
      });
    });

    group('compares licenses', () {
      const license = 'license';
      const otherLicense = 'other';

      test('loads empty scan result', () async {
        final summary = await service.compareLicenses();

        expect(summary.bom, isZero);
        expect(summary.common, isZero);
      });

      test('loads scan result from single scanner', () async {
        final result = ScanResult(name)
          ..addItem(ItemId('with', '1')..addLicenses([license]))
          ..addItem(ItemId('without', '1'));
        when(results.load(ScannerType.black_duck, glob))
            .thenAnswer((_) => Future.value(result));

        await service.loadResult(ScannerType.black_duck, glob);
        final summary = await service.compareLicenses();

        expect(summary.bom, equals(2));
        expect(summary.common, equals(2));
      });

      test('loads scan results from multiple scanners', () async {
        const common = 'common';
        final equalItem = ItemId('equal', '1')
          ..addLicenses([license])
          ..addLicenses([otherLicense]);
        final result1 = ScanResult('A')
          ..addItem(equalItem)
          ..addItem(ItemId(common, common)..addLicenses([license]))
          ..addItem(ItemId('other', '666'));
        when(results.load(ScannerType.reference, glob))
            .thenAnswer((_) => Future.value(result1));
        final result2 = ScanResult('B')
          ..addItem(equalItem)
          ..addItem(ItemId(common, common)..addLicenses([otherLicense]));
        when(results.load(ScannerType.black_duck, glob))
            .thenAnswer((_) => Future.value(result2));

        await service.loadResult(ScannerType.reference, glob);
        await service.loadResult(ScannerType.black_duck, glob);
        final summary = await service.compareLicenses();

        expect(summary.bom, equals(2));
        expect(summary.common, equals(1));
      });

      test('writes licenses report', () async {
        final licensesFile = File('licenses.csv');
        final id = ItemId('a', '1');
        final result = ScanResult('A')..addItem(id);
        when(results.load(ScannerType.reference, glob))
            .thenAnswer((_) => Future.value(result));

        await service.loadResult(ScannerType.reference, glob);
        await service.compareLicenses(licensesFile: licensesFile);

        verify(reports.writeLicenseComparison(licensesFile, [id], [result]));
      });

      test('writes licenses diff report', () async {
        final licensesFile = File('licenses.csv');
        final id1 = ItemId('a', '1')..addLicenses({'MIT'});
        final result1 = ScanResult('A')..addItem(id1);
        when(results.load(ScannerType.reference, glob))
            .thenAnswer((_) => Future.value(result1));
        final id2 = ItemId('a', '1')..addLicenses({'Apache-2.0'});
        final result2 = ScanResult('B')..addItem(id2);
        when(results.load(ScannerType.white_source, glob))
            .thenAnswer((_) => Future.value(result2));

        await service.loadResult(ScannerType.reference, glob);
        await service.loadResult(ScannerType.white_source, glob);
        await service.compareLicenses(
            licensesFile: licensesFile, diffOnly: true);

        verify(reports
            .writeLicenseComparison(licensesFile, [id1], [result1, result2]));
      });
    });
  });
}
