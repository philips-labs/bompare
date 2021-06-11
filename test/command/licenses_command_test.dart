import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/command/abstract_command.dart';
import 'package:bompare/command/licenses_command.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:glob/glob.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class BomServiceMock extends Mock implements BomService {}

void main() {
  group('$LicensesCommand', () {
    const glob = 'glob pattern';

    late BomService service;
    late CommandRunner runner;
    late LicensesCommand command;

    setUp(() {
      service = BomServiceMock();
      command = LicensesCommand(service);
      runner = CommandRunner('dummy', 'description')..addCommand(command);

      registerFallbackValue(ScannerType.maven);
      registerFallbackValue(Glob(glob));
      registerFallbackValue(File(''));

      when(() => service.loadResult(any(), any())).thenAnswer((_) async {});
      when(() => service.loadSpdxMapping(any())).thenAnswer((_) async {});
    });

    test('provides description', () {
      expect(command.description,
          predicate<String>((s) => s.contains('license differences')));
    });

    test('analyses licenses from scan results', () async {
      when(() => service.compareLicenses())
          .thenAnswer((_) => Future.value(LicenseResult(2, 1)));

      await runner.run([
        LicensesCommand.command,
        '--${AbstractCommand.option_black_duck}',
        glob
      ]);

      verify(() => service.loadResult(ScannerType.black_duck,
          any(that: predicate<Glob>((g) => g.pattern == glob)))).called(1);

      verify(() => service.compareLicenses()).called(1);
    });

    test('loads SPDX mapping file', () async {
      const spdxFile = 'spdx.csv';

      when(() => service.compareLicenses())
          .thenAnswer((_) => Future.value(LicenseResult(0, 0)));

      await runner.run([
        LicensesCommand.command,
        '--${AbstractCommand.option_spdx_mapping}',
        spdxFile
      ]);

      verify(() => service.loadSpdxMapping(
          any(that: predicate<File>((f) => f.path == spdxFile)))).called(1);
    });

    test('outputs licenses CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(() =>
              service.compareLicenses(licensesFile: any(named: 'licensesFile')))
          .thenAnswer((_) => Future.value(LicenseResult(2, 1)));

      await runner.run([LicensesCommand.command, '-r', glob, '-o', csvFile]);

      verify(() => service.compareLicenses(
          licensesFile: any(
              that: predicate<File>((File f) => f.path == csvFile),
              named: 'licensesFile'),
          diffOnly: any(that: isFalse, named: 'diffOnly')));
    });

    test('outputs diff only CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(() => service.compareLicenses(
              licensesFile: any(named: 'licensesFile'),
              diffOnly: any(named: 'diffOnly')))
          .thenAnswer((_) => Future.value(LicenseResult(2, 1)));

      await runner.run(
          [LicensesCommand.command, '-r', glob, '-o', csvFile, '--diffOnly']);

      verify(() => service.compareLicenses(
          licensesFile: any(
              that: predicate<File>((File f) => f.path == csvFile),
              named: 'licensesFile'),
          diffOnly: any(that: isTrue, named: 'diffOnly')));
    });
  });
}
