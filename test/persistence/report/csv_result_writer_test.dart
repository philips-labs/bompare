import 'dart:io';

import 'package:bompare/persistence/persistence_exception.dart';
import 'package:bompare/persistence/report/csv_result_writer.dart';
import 'package:bompare/service/domain/item_id.dart';
import 'package:bompare/service/domain/scan_result.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$CsvResultWriter', () {
    File file;

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
          () => writer.writeBomComparison({ItemId('a', 'b')}),
          throwsA(predicate<PersistenceException>(
              (e) => e.toString().contains('write'))));
    });

    test('writes bill-of-materials file', () async {
      final ids = {ItemId('p', 'v')};
      final scans = [ScanResult('A')..addItem(ids.first), ScanResult('B')];
      final writer = CsvResultWriter(file, scans);

      await writer.writeBomComparison(ids);

      final csv = file.readAsStringSync();
      expect(
          csv,
          equals('"package","version","A","B"\r\n'
              '"p","v","yes",""\r\n'));
    });

    test('writes licenses file', () async {
      final ids = {
        ItemId('p', 'v')..addLicenses(['lic1', '""'])
      };
      final scans = [ScanResult('A')..addItem(ids.first), ScanResult('B')];
      final writer = CsvResultWriter(file, scans);

      await writer.writeLicensesComparison(ids);

      final csv = file.readAsStringSync();
      expect(
          csv,
          equals('"package","version","A","B"\r\n'
              '"p","v","lic1 OR """"",""\r\n'));
    });
  });
}
