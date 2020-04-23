import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/command/abstract_command.dart';
import 'package:bompare/command/bom_command.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class BomServiceMock extends Mock implements BomService {}

void main() {
  group('$BomCommand', () {
    const filename = 'filename';

    BomService service;
    CommandRunner runner;

    setUp(() {
      service = BomServiceMock();
      runner = CommandRunner('dummy', 'description')
        ..addCommand(BomCommand(service));
    });

    test('loads reference result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_reference}',
        filename
      ]);

      verify(service.loadResult(ScannerType.reference,
          argThat(predicate<File>((File f) => f.path == filename))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads WhiteSource result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_white_source}',
        filename
      ]);

      verify(service.loadResult(ScannerType.white_source,
          argThat(predicate<File>((File f) => f.path == filename))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads Black Duck result files', () async {
      when(service.compareBom()).thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_black_duck}',
        filename
      ]);

      verify(service.loadResult(ScannerType.black_duck,
          argThat(predicate<File>((File f) => f.path == filename))));
      verify(service.compareBom(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('outputs CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(service.compareBom(bomFile: anyNamed('bomFile')))
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_reference}',
        filename,
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
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([
        BomCommand.command,
        '--${AbstractCommand.option_reference}',
        filename,
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
