import 'dart:io';

import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/report_persistence.dart';
import 'package:bompare/service/result_persistence.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class ResultPersistenceMock extends Mock implements ResultPersistence {}

class ReportPersistenceMock extends Mock implements ReportPersistence {}

void main() {
  group('$BomService', () {
    const name = 'scan_result';
    final file = File('scan_result.json');

    ResultPersistence results;
    ReportPersistence reports;
    BomService service;

    setUp(() {
      results = ResultPersistenceMock();
      reports = ReportPersistenceMock();
      service = BomService(results, reports);
    });

    test('loads empty scan resuls', () {
      expect(service.compareResults(), isEmpty);
    });

    test('loads scan result from single scanner', () {
      final result = ScanResult(name)..addItem(ItemId('a', '1'));
      when(results.load(ScannerType.black_duck, file)).thenReturn(result);

      service.loadResult(ScannerType.black_duck, file);
      final summary = service.compareResults();

      expect(summary, hasLength(1));
      expect(summary[0].name, equals(name));
      expect(summary[0].common, equals(1));
      expect(summary[0].missing, isZero);
      expect(summary[0].additional, isZero);
    });

    test('loads scan results from multiple scanners', () {
      final commonItem = ItemId('common', '0');
      final result1 = ScanResult('A')
        ..addItem(commonItem)
        ..addItem(ItemId('a', '1'));
      when(results.load(ScannerType.reference, file))..thenReturn(result1);
      final result2 = ScanResult('B')
        ..addItem(commonItem)
        ..addItem(ItemId('b', '2'))
        ..addItem(ItemId('c', '3'));
      when(results.load(ScannerType.black_duck, file))..thenReturn(result2);

      service.loadResult(ScannerType.reference, file);
      service.loadResult(ScannerType.black_duck, file);
      final summary = service.compareResults();

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

    test('writes BOM report', () {
      final bomFile = File('bom.csv');
      final id = ItemId('a', '1');
      final result = ScanResult('A')..addItem(id);
      when(results.load(ScannerType.reference, file))..thenReturn(result);

      service.loadResult(ScannerType.reference, file);
      service.compareResults(bomFile: bomFile);

      verify(reports.writeBomComparison(bomFile, [id], [result]));
    });

    test('writes diff BOM report', () {
      final bomFile = File('bom.csv');
      final id1 = ItemId('a', '1');
      final id2 = ItemId('b', '2');
      final result1 = ScanResult('A')..addItem(id1);
      final result2 = ScanResult('B')..addItem(id1)..addItem(id2);
      when(results.load(ScannerType.reference, file))..thenReturn(result1);
      when(results.load(ScannerType.black_duck, file))..thenReturn(result2);

      service.loadResult(ScannerType.reference, file);
      service.loadResult(ScannerType.black_duck, file);
      service.compareResults(bomFile: bomFile, diffOnly: true);

      verify(reports.writeBomComparison(bomFile, [id2], [result1, result2]));
    });
  });
}
