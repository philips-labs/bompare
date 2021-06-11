import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/command/abstract_command.dart';
import 'package:bompare/command/bom_command.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:glob/glob.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class BomServiceMock extends Mock implements BomService {}

void main() {
  group('$BomCommand', () {
    const glob = 'glob pattern';

    late BomService service;
    late CommandRunner runner;
    late BomCommand command;

    setUp(() {
      service = BomServiceMock();
      command = BomCommand(service);
      runner = CommandRunner('dummy', 'description')..addCommand(command);

      registerFallbackValue(ScannerType.maven);
      registerFallbackValue(Glob(glob));

      when(() => service.compareBom())
          .thenAnswer((_) => Future.value(<BomResult>[]));

      when(() => service.loadResult(any(), any())).thenAnswer((_) async {});
    });

    test('provides description', () {
      expect(command.description,
          predicate<String>((s) => s.contains('BOM differences')));
    });

    test('loads reference result files', () async {
      await runner.run(
          [BomCommand.command, '--${AbstractCommand.option_reference}', glob]);

      verify(() => service.loadResult(ScannerType.reference,
          any(that: predicate<Glob>((g) => g.pattern == glob)))).called(1);

      verify(() =>
              service.compareBom(bomFile: any(that: isNull, named: 'bomFile')))
          .called(1);
    });

    test('loads JK1 result files', () async {
      await runner
          .run([BomCommand.command, '--${AbstractCommand.option_jk1}', glob]);

      verify(() => service.loadResult(ScannerType.jk1,
          any(that: predicate<Glob>((g) => g.pattern == glob)))).called(1);

      verify(() =>
              service.compareBom(bomFile: any(that: isNull, named: 'bomFile')))
          .called(1);
    });

    test('loads Maven license result files', () async {
      await runner
          .run([BomCommand.command, '--${AbstractCommand.option_maven}', glob]);

      verify(() => service.loadResult(ScannerType.maven,
          any(that: predicate<Glob>((g) => g.pattern == glob)))).called(1);

      verify(() =>
              service.compareBom(bomFile: any(that: isNull, named: 'bomFile')))
          .called(1);
    });

    test('loads Tern result files', () async {
      await runner
          .run([BomCommand.command, '--${AbstractCommand.option_tern}', glob]);

      verify(() => service.loadResult(ScannerType.tern,
          any(that: predicate<Glob>((g) => g.pattern == glob)))).called(1);

      verify(() =>
              service.compareBom(bomFile: any(that: isNull, named: 'bomFile')))
          .called(1);
    });

    test('loads SPDX tag-value result files', () async {
      await runner
          .run([BomCommand.command, '--${AbstractCommand.option_spdx}', glob]);

      verify(() => service.loadResult(ScannerType.spdx,
          any(that: predicate<Glob>((g) => g.pattern == glob)))).called(1);

      verify(() =>
              service.compareBom(bomFile: any(that: isNull, named: 'bomFile')))
          .called(1);
    });

    test('loads WhiteSource result files', () async {
      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_white_source}',
        glob
      ]);

      verify(() => service.loadResult(ScannerType.white_source,
          any(that: predicate<Glob>((g) => g.pattern == glob)))).called(1);

      verify(() =>
              service.compareBom(bomFile: any(that: isNull, named: 'bomFile')))
          .called(1);
    });

    test('loads Black Duck result files', () async {
      await runner.run(
          [BomCommand.command, '--${AbstractCommand.option_black_duck}', glob]);

      verify(() => service.loadResult(ScannerType.black_duck,
          any(that: predicate<Glob>((g) => g.pattern == glob)))).called(1);

      verify(() =>
              service.compareBom(bomFile: any(that: isNull, named: 'bomFile')))
          .called(1);
    });

    test('outputs CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(() => service.compareBom(bomFile: any(named: 'bomFile')))
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_reference}',
        glob,
        '--${AbstractCommand.option_output}',
        csvFile
      ]);

      verify(() => service.compareBom(
          bomFile: any(
              that: predicate<File>((File f) => f.path == csvFile),
              named: 'bomFile'),
          diffOnly: any(that: isFalse, named: 'diffOnly'))).called(1);
    });

    test('outputs diff only CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(() => service.compareBom(
              bomFile: any(named: 'bomFile'), diffOnly: any(named: 'diffOnly')))
          .thenAnswer((_) => Future.value(<BomResult>[BomResult('name', 42)]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_reference}',
        glob,
        '--${AbstractCommand.option_output}',
        csvFile,
        '--${AbstractCommand.option_diff_only}'
      ]);

      verify(() => service.compareBom(
          bomFile: any(
              that: predicate<File>((File f) => f.path == csvFile),
              named: 'bomFile'),
          diffOnly: any(that: isTrue, named: 'diffOnly'))).called(1);
    });
  });
}
