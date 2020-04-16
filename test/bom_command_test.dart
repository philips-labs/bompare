import 'dart:io';

import 'package:args/command_runner.dart';
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
      when(service.compareResults())
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([BomCommand.command, '-r', filename]);

      verify(service.loadResult(ScannerType.reference,
          argThat(predicate<File>((File f) => f.path == filename))));
      verify(
          service.compareResults(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads WhiteSource result files', () async {
      when(service.compareResults())
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([BomCommand.command, '-w', filename]);

      verify(service.loadResult(ScannerType.white_source,
          argThat(predicate<File>((File f) => f.path == filename))));
      verify(
          service.compareResults(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('loads Black Duck result files', () async {
      when(service.compareResults())
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([BomCommand.command, '-b', filename]);

      verify(service.loadResult(ScannerType.black_duck,
          argThat(predicate<File>((File f) => f.path == filename))));
      verify(
          service.compareResults(bomFile: argThat(isNull, named: 'bomFile')));
    });

    test('outputs CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(service.compareResults(bomFile: anyNamed('bomFile')))
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run([BomCommand.command, '-r', filename, '-o', csvFile]);

      verify(service.compareResults(
          bomFile: argThat(predicate<File>((File f) => f.path == csvFile),
              named: 'bomFile'),
          diffOnly: argThat(isFalse, named: 'diffOnly')));
    });

    test('outputs diff only CSV to provided file name', () async {
      const csvFile = 'file.csv';
      when(service.compareResults(
              bomFile: anyNamed('bomFile'), diffOnly: anyNamed('diffOnly')))
          .thenAnswer((_) => Future.value(<BomResult>[]));

      await runner.run(
          [BomCommand.command, '-r', filename, '-o', csvFile, '--diffOnly']);

      verify(service.compareResults(
          bomFile: argThat(predicate<File>((File f) => f.path == csvFile),
              named: 'bomFile'),
          diffOnly: argThat(isTrue, named: 'diffOnly')));
    });
  });
}
