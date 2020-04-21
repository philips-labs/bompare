import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/command/abstract_command.dart';
import 'package:bompare/command/licenses_command.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class BomServiceMock extends Mock implements BomService {}

void main() {
  group('$LicensesCommand', () {
    const filename = 'filename';

    BomService service;
    CommandRunner runner;

    setUp(() {
      service = BomServiceMock();
      runner = CommandRunner('dummy', 'description')
        ..addCommand(LicensesCommand(service));
    });

    test('analyses licenses from scan results', () async {
      when(service.compareLicenses())
          .thenAnswer((_) => Future.value(LicenseResult(2, 1)));

      await runner.run([
        LicensesCommand.command,
        '--${AbstractCommand.option_black_duck}',
        filename
      ]);

      verify(service.loadResult(ScannerType.black_duck,
          argThat(predicate<File>((File f) => f.path == filename))));
      verify(service.compareLicenses());
    });

//    test('outputs CSV to provided file name', () async {
//      const csvFile = 'file.csv';
//      when(service.compareBom(bomFile: anyNamed('bomFile')))
//          .thenAnswer((_) => Future.value(<BomResult>[]));
//
//      await runner.run([BomCommand.command, '-r', filename, '-o', csvFile]);
//
//      verify(service.compareBom(
//          bomFile: argThat(predicate<File>((File f) => f.path == csvFile),
//              named: 'bomFile'),
//          diffOnly: argThat(isFalse, named: 'diffOnly')));
//    });
//
//    test('outputs diff only CSV to provided file name', () async {
//      const csvFile = 'file.csv';
//      when(service.compareBom(
//              bomFile: anyNamed('bomFile'), diffOnly: anyNamed('diffOnly')))
//          .thenAnswer((_) => Future.value(<BomResult>[]));
//
//      await runner.run(
//          [BomCommand.command, '-r', filename, '-o', csvFile, '--diffOnly']);
//
//      verify(service.compareBom(
//          bomFile: argThat(predicate<File>((File f) => f.path == csvFile),
//              named: 'bomFile'),
//          diffOnly: argThat(isTrue, named: 'diffOnly')));
//    });
  });
}
