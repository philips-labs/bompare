import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/command/abstract_command.dart';
import 'package:bompare/command/bom_command.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:glob/glob.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class BomServiceMock extends Mock implements BomService {}

void main() {
  group('$BomCommand', () {
    const glob = 'glob pattern';

    BomService service;
    CommandRunner runner;
    BomCommand command;

    setUp(() {
      service = BomServiceMock();
      command = BomCommand(service);
      runner = CommandRunner('dummy', 'description')..addCommand(command);
    });

    test('provides description', () {
      expect(command.description,
          predicate<String>((s) => s.contains('BOM differences')));
    });

    test('loads reference result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run(
          [BomCommand.command, '--${AbstractCommand.option_reference}', glob]);

      verify(service.loadResult(ScannerType.reference,
          argThat(predicate<Glob>((g) => g.pattern == glob))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads JK1 result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner
          .run([BomCommand.command, '--${AbstractCommand.option_jk1}', glob]);

      verify(service.loadResult(
          ScannerType.jk1, argThat(predicate<Glob>((g) => g.pattern == glob))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads Maven license result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner
          .run([BomCommand.command, '--${AbstractCommand.option_maven}', glob]);

      verify(service.loadResult(ScannerType.maven,
          argThat(predicate<Glob>((g) => g.pattern == glob))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads Tern result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner
          .run([BomCommand.command, '--${AbstractCommand.option_tern}', glob]);

      verify(service.loadResult(ScannerType.tern,
          argThat(predicate<Glob>((g) => g.pattern == glob))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads SPDX tag-value result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner
          .run([BomCommand.command, '--${AbstractCommand.option_spdx}', glob]);

      verify(service.loadResult(ScannerType.spdx,
          argThat(predicate<Glob>((g) => g.pattern == glob))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads WhiteSource result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_white_source}',
        glob
      ]);

      verify(service.loadResult(ScannerType.white_source,
          argThat(predicate<Glob>((g) => g.pattern == glob))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads Black Duck result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run(
          [BomCommand.command, '--${AbstractCommand.option_black_duck}', glob]);

      verify(service.loadResult(ScannerType.black_duck,
          argThat(predicate<Glob>((g) => g.pattern == glob))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('outputs CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(service.compareBom(bomFile: anyNamed('bomFile')))
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_reference}',
        glob,
        '--${AbstractCommand.option_output}',
        csvFile
      ]);

      verify(service.compareBom(
          bomFile: argThat(predicate<File>((File f) => f.path == csvFile),
              named: 'bomFile'),
          diffOnly: argThat(isFalse, named: 'diffOnly')));
    });

    test('outputs diff only CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(service.compareBom(
              bomFile: anyNamed('bomFile'), diffOnly: anyNamed('diffOnly')))
          .thenAnswer((_) => Future.value(<BomResult>[BomResult('name', 42)]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_reference}',
        glob,
        '--${AbstractCommand.option_output}',
        csvFile,
        '--${AbstractCommand.option_diff_only}'
      ]);

      verify(service.compareBom(
          bomFile: argThat(predicate<File>((File f) => f.path == csvFile),
              named: 'bomFile'),
          diffOnly: argThat(isTrue, named: 'diffOnly')));
    });
  });
}
