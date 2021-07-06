import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/report/csv_result_writer.dart';
import 'package:bompare/service/domain/bom_item.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:bompare/service/purl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$CsvResultWriter', () {
    late File file;

    setUp(() {
      file = File(path.join(Directory.systemTemp.path, 'temp.csv'));
      if (file.existsSync()) file.deleteSync();
    });

    tearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    test('throws if file cannot be written', () {
      final writer =
          CsvResultWriter(File(path.join('does', 'not', 'exist.csv')), []);

      expect(
          () => writer.writeBomComparison(
              {BomItem(Purl.of(type: 'generic', name: 'a', version: 'b'))}),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('write'))));
    });

    test('writes bill-of-materials file', () async {
      final items = {BomItem(Purl('pkg:t/n@v'))};
      final scans = [ScanResult('A')..addItem(items.first), ScanResult('B')];
      final writer = CsvResultWriter(file, scans);

      await writer.writeBomComparison(items);

      final csv = file.readAsStringSync();
      expect(
          csv,
          equals('"package","A","B"\r\n'
              '"pkg:t/n@v","yes",""\r\n'));
    });

    test('writes licenses file', () async {
      final items = {
        BomItem(Purl('pkg:t/n@v'))..addLicenses(['lic1', '""'])
      };
      final scans = [ScanResult('A')..addItem(items.first), ScanResult('B')];
      final writer = CsvResultWriter(file, scans);

      await writer.writeLicensesComparison(items);

      final csv = file.readAsStringSync();
      expect(
          csv,
          equals('"package","A","B"\r\n'
              '"pkg:t/n@v","lic1 OR """"",""\r\n'));
    });
  });
}
