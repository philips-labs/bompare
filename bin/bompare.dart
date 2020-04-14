import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:bompare/command/bom_command.dart';
import 'package:bompare/persistence/reference/reference_result_parser.dart';
import 'package:bompare/persistence/scan_result_loader.dart';
import 'package:bompare/service/bom_service.dart';
import 'package:bompare/service/domain/business_exception.dart';

void main(List<String> arguments) async {
  final loader = ScanResultLoader(
    {ScannerType.reference: ReferenceResultParser()},
  );
  final service = BomService(loader);

  try {
    final command = CommandRunner('bompare', 'Bill-Of-Material scan comparator')
      ..addCommand(BomCommand(service));
    await command.run(arguments);
  } on UsageException catch (error) {
    print(error);
    exitCode = 64;
  } on BusinessException catch (error) {
    print(error);
    exitCode = 1;
  }
}
