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

    test('loads scanner result files', () {
      when(service.compareResults()).thenReturn(<BomResult>[]);

      runner.run([BomCommand.command, '-r', filename]);

      verify(service.loadResult(ScannerType.reference,
          argThat(predicate<File>((File f) => f.path == filename))));
      verify(service.compareResults());
    });
  });
}
